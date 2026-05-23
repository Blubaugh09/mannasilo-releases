import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BereanPlugin } from './plugin/berean'
import { ControlPanel } from './ui/ControlPanel'
import './ui/styles.css'

async function boot() {
  const plugin = new BereanPlugin()

  // Start the plugin (probes the bridge with a timeout). We mount the React
  // companion either way — without a bridge the panel is still a usable HUD
  // preview for layout work.
  await plugin.start()
  const bridgeAvailable = plugin.hasBridge()

  const rootEl = document.getElementById('root')!
  createRoot(rootEl).render(
    <StrictMode>
      <ControlPanel plugin={plugin} bridgeAvailable={bridgeAvailable} />
    </StrictMode>
  )

  // Clean shutdown when the WebView unloads.
  window.addEventListener('beforeunload', () => { plugin.stop() })

  // TODO(voice): enable Web Speech API on supported devices.
  //   const SR = (window as any).webkitSpeechRecognition || (window as any).SpeechRecognition
  //   if (SR) {
  //     const recog = new SR()
  //     recog.continuous = true
  //     recog.interimResults = false
  //     recog.lang = 'en-US'
  //     recog.onresult = (e: any) => {
  //       const transcript = Array.from(e.results)
  //         .map((r: any) => r[0].transcript)
  //         .join(' ')
  //       plugin.onVoiceInput(transcript)
  //     }
  //     recog.start()
  //   }
  // On G2 hardware, prefer `bridge.audioControl(true)` + server-side STT
  // over Web Speech — see asr/ template in @evenrealities/evenhub-templates.
}

boot().catch(err => {
  console.error('[berean] boot failed:', err)
  const rootEl = document.getElementById('root')
  if (rootEl) {
    rootEl.textContent = 'Berean failed to start — check the console.'
  }
})
