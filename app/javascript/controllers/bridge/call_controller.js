import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends BridgeComponent {
  static component = "call"

  connect() {
    super.connect()
    if (window.nativeBridge && !this.enabled) {
      this.bridge.setAdapter(window.nativeBridge)
    }

    if (!this.#openedFromNotification()) {
      this.#sendRing()
    }
  }

  disconnect() {
    this.#sendStopRing()
  }

  close(event) {
    this.#sendStopRing()
    if (this.enabled) {
      event?.preventDefault()
      this.send("close")
    } else if (window.nativeBridge) {
      this.bridge.setAdapter(window.nativeBridge)
      event?.preventDefault()
      this.send("close")
    }
  }

  missed(event) {
    this.#sendStopRing()
    if (this.enabled) {
      event?.preventDefault()
      this.send("missed")
    } else if (window.nativeBridge) {
      this.bridge.setAdapter(window.nativeBridge)
      event?.preventDefault()
      this.send("missed")
    }
  }

  decline(event) {
    const params = new URLSearchParams(window.location.search)
    if (!params.has('incoming_call_id')) {
      return
    }

    event.preventDefault()

    const form = event.target.closest('form')
    const url = form.action

    fetch(url, {
      method: 'POST',
      headers: { 'Accept': 'text/html' },
      credentials: 'same-origin'
    })

    this.close()
  }

  #openedFromNotification() {
    const params = new URLSearchParams(window.location.search)
    return params.has('caller_name') || params.has('auto_answer')
  }

  #sendRing() {
    if (this.enabled) {
      this.send("ring")
    } else if (window.nativeBridge) {
      this.bridge.setAdapter(window.nativeBridge)
      this.send("ring")
    }
  }

  #sendStopRing() {
    if (this.enabled) {
      this.send("stopRing")
    } else if (window.nativeBridge) {
      this.bridge.setAdapter(window.nativeBridge)
      this.send("stopRing")
    }
  }
}
