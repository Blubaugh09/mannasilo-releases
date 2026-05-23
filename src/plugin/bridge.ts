/**
 * Thin wrapper around the Even Hub SDK bridge.
 *
 * The bridge resolves through `waitForEvenAppBridge()` when running inside
 * the simulator or the Even App WebView. In plain browser dev (no host
 * around) we time out and fall through to companion-only mode — the HUD
 * preview in the React panel still mirrors what the glasses would draw.
 */
import {
  waitForEvenAppBridge,
  type CreateStartUpPageContainer,
  type RebuildPageContainer,
  type TextContainerUpgrade,
  type EvenHubEvent,
  type EvenAppBridge
} from '@evenrealities/even_hub_sdk'

export type HubEvent = EvenHubEvent

export interface BridgeHandle {
  createStartUpPageContainer: EvenAppBridge['createStartUpPageContainer']
  rebuildPageContainer: EvenAppBridge['rebuildPageContainer']
  textContainerUpgrade: EvenAppBridge['textContainerUpgrade']
  audioControl: EvenAppBridge['audioControl']
  shutDownPageContainer: EvenAppBridge['shutDownPageContainer']
  onEvenHubEvent: EvenAppBridge['onEvenHubEvent']
}

export type { CreateStartUpPageContainer, RebuildPageContainer, TextContainerUpgrade }

let cached: BridgeHandle | null = null
let probed = false

/**
 * Resolve the bridge, with a timeout so plain browser sessions (no
 * simulator, no Even App) fall through to companion-only mode quickly.
 */
export async function getBridge(timeoutMs = 1500): Promise<BridgeHandle | null> {
  if (cached) return cached
  if (probed) return null
  try {
    const real = await Promise.race<BridgeHandle | null>([
      waitForEvenAppBridge() as Promise<BridgeHandle>,
      new Promise<null>(resolve => setTimeout(() => resolve(null), timeoutMs))
    ])
    probed = true
    if (real) {
      cached = real
      return real
    }
  } catch (err) {
    probed = true
    console.warn('[berean] bridge resolution failed:', err)
  }
  return null
}
