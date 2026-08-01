import { Controller } from "@hotwired/stimulus"

// Reloads the turbo-frame this controller is attached to on a fixed
// interval, only while the frame is on-screen. This is the "polling, not
// ActionCable" approach from the architecture plan: a persistent WebSocket
// would either die every time the free hosting dyno sleeps, or (if kept
// open) quietly burn through the free-tier hour budget. Polling this
// frequently only happens while someone's actually looking at the page —
// normal usage-driven traffic, not a background keep-alive.
export default class extends Controller {
  static values = { interval: { type: Number, default: 10000 } }

  connect() {
    this.timer = setInterval(() => this.reload(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  reload() {
    if (this.element.isConnected) this.element.reload()
  }
}
