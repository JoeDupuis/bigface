import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["status"]
  static values = { callId: Number, role: String }

  connect() {
    this.startLocalVideo()
    this.subscribeToChannel()
  }

  async startLocalVideo() {
    try {
      this.localStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true })
      this.element.querySelector("#local-video").srcObject = this.localStream
    } catch (error) {
      console.error("Failed to access camera/microphone:", error)
    }
  }

  subscribeToChannel() {
    this.subscription = consumer.subscriptions.create(
      { channel: "CallChannel", call_id: this.callIdValue },
      {
        received: (data) => this.handleSignaling(data)
      }
    )
  }

  handleSignaling(data) {
    switch (data.type) {
      case "timeout":
        if (this.hasStatusTarget) {
          this.statusTarget.textContent = "No answer"
        }
        setTimeout(() => {
          window.location.href = "/contacts"
        }, 2000)
        break
    }
  }

  disconnect() {
    if (this.localStream) {
      this.localStream.getTracks().forEach(track => track.stop())
    }
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }
}
