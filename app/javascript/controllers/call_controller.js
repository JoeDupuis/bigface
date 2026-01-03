import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
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
  }

  disconnect() {
    if (this.localStream) {
      this.localStream.getTracks().forEach(track => track.stop())
    }
  }
}
