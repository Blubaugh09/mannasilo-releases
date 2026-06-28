import Foundation
import CoreBluetooth
import Combine

/// Drives the Bluetooth connection to the Even Realities glasses and pumps their
/// microphone audio straight into our own speech pipeline — no Even Realities
/// companion app in the loop.
///
/// Flow: scan → connect → discover the Nordic UART Service → subscribe to RX →
/// send the mic-enable command → receive 0xF1 audio frames → LC3-decode →
/// feed the SpeechProcessor → live transcript.
@MainActor
final class GlassesManager: NSObject, ObservableObject {

    enum ConnectionState: Equatable {
        case poweredOff
        case unauthorized
        case idle
        case scanning
        case connecting
        case connected
        case listening
    }

    struct DiscoveredDevice: Identifiable, Equatable {
        let id: UUID            // peripheral identifier
        let name: String
        let side: GlassesProtocol.Side
        let rssi: Int
    }

    // MARK: Published state for the UI
    @Published private(set) var state: ConnectionState = .idle
    @Published private(set) var discovered: [DiscoveredDevice] = []
    @Published private(set) var connectedNames: [String] = []
    @Published private(set) var isListening = false
    @Published private(set) var framesReceived: Int = 0
    @Published private(set) var lastError: String?

    /// The live speech pipeline (its `transcript` drives the UI).
    let speech = SpeechProcessor()

    /// Whether real LC3 decoding is compiled in (see LC3Decoder.swift).
    var decoderFunctional: Bool { decoder.isFunctional }

    // MARK: Internals
    private var central: CBCentralManager!
    private let decoder: LC3Decoding = DefaultLC3Decoder()
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var txCharacteristics: [UUID: CBCharacteristic] = [:]
    private var heartbeatTimer: Timer?
    private var heartbeatSeq: UInt8 = 0

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: Public controls

    func startScanning() {
        guard central.state == .poweredOn else {
            lastError = "Bluetooth is not powered on."
            return
        }
        discovered.removeAll()
        state = .scanning
        // Scan broadly (the glasses don't always advertise the NUS UUID in the
        // advertisement packet), then filter by name in the callback.
        central.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
    }

    func stopScanning() {
        central.stopScan()
        if state == .scanning { state = peripherals.isEmpty ? .idle : .connected }
    }

    func connect(_ device: DiscoveredDevice) {
        guard let peripheral = peripherals[device.id] else { return }
        central.stopScan()
        state = .connecting
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }

    func disconnect() {
        stopListening()
        for peripheral in peripherals.values where peripheral.state != .disconnected {
            central.cancelPeripheralConnection(peripheral)
        }
        peripherals.removeAll()
        txCharacteristics.removeAll()
        connectedNames.removeAll()
        state = .idle
    }

    /// Enable the glasses' microphone and begin transcribing.
    func startListening() async {
        guard !txCharacteristics.isEmpty else {
            lastError = "Not connected to the glasses yet."
            return
        }
        await speech.requestAuthorization()
        if speech.authorizationDenied {
            lastError = "Speech recognition permission was denied. Enable it in Settings."
            return
        }
        framesReceived = 0
        speech.clear()
        speech.start()
        sendToAll(GlassesProtocol.micEnableCommand())
        startHeartbeat()
        isListening = true
        state = .listening
    }

    func stopListening() {
        guard isListening else { return }
        sendToAll(GlassesProtocol.micDisableCommand())
        stopHeartbeat()
        speech.stop()
        isListening = false
        state = peripherals.isEmpty ? .idle : .connected
    }

    // MARK: Command plumbing

    private func sendToAll(_ data: Data) {
        for (id, characteristic) in txCharacteristics {
            peripherals[id]?.writeValue(data, for: characteristic, type: .withoutResponse)
        }
    }

    private func startHeartbeat() {
        stopHeartbeat()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.heartbeatSeq &+= 1
                self.sendToAll(GlassesProtocol.heartbeatCommand(sequence: self.heartbeatSeq))
            }
        }
    }

    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
}

// MARK: - CBCentralManagerDelegate
extension GlassesManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:  if state == .poweredOff || state == .unauthorized { state = .idle }
        case .poweredOff: state = .poweredOff
        case .unauthorized: state = .unauthorized
        default: break
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let advName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advName ?? peripheral.name ?? ""
        guard name.hasPrefix(GlassesProtocol.namePrefix) else { return }

        peripherals[peripheral.identifier] = peripheral
        let device = DiscoveredDevice(
            id: peripheral.identifier,
            name: name,
            side: GlassesProtocol.side(for: name),
            rssi: RSSI.intValue
        )
        if let index = discovered.firstIndex(where: { $0.id == device.id }) {
            discovered[index] = device
        } else {
            discovered.append(device)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([GlassesProtocol.nusService])
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        lastError = "Failed to connect: \(error?.localizedDescription ?? "unknown error")."
        state = peripherals.isEmpty ? .idle : .connected
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        txCharacteristics[peripheral.identifier] = nil
        connectedNames.removeAll { $0 == (peripheral.name ?? "") }
        if txCharacteristics.isEmpty {
            isListening = false
            stopHeartbeat()
            speech.stop()
            state = .idle
        }
    }
}

// MARK: - CBPeripheralDelegate
extension GlassesManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == GlassesProtocol.nusService {
            peripheral.discoverCharacteristics(
                [GlassesProtocol.nusTXWrite, GlassesProtocol.nusRXNotify],
                for: service
            )
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            switch characteristic.uuid {
            case GlassesProtocol.nusTXWrite:
                txCharacteristics[peripheral.identifier] = characteristic
            case GlassesProtocol.nusRXNotify:
                peripheral.setNotifyValue(true, for: characteristic)
            default:
                break
            }
        }
        if txCharacteristics[peripheral.identifier] != nil {
            let name = peripheral.name ?? "Glasses"
            if !connectedNames.contains(name) { connectedNames.append(name) }
            if state == .connecting { state = .connected }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard characteristic.uuid == GlassesProtocol.nusRXNotify,
              let data = characteristic.value else { return }

        // Only audio frames are routed into the speech pipeline; other
        // notifications (status, battery, touch events) are ignored for now.
        guard let payload = GlassesProtocol.audioPayload(from: data) else { return }
        framesReceived += 1

        let pcm = decoder.decode(payload)
        if !pcm.isEmpty {
            speech.appendPCM(pcm)
        }
    }
}
