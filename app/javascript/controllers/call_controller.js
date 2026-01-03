import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"
import { WebRTCManager } from "../lib/webrtc_manager"

export default class extends Controller {
  static targets = ["localVideo", "remoteVideo", "remoteContainer", "status"]
  static values = { callId: Number, role: String }

  async connect() {
    await this.startLocalVideo()
    await this.fetchTurnCredentials()
    this.subscribeToChannel()
  }

  async startLocalVideo() {
    try {
      this.localStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true })
      this.localVideoTarget.srcObject = this.localStream
    } catch (error) {
      console.error("Failed to access camera/microphone:", error)
    }
  }

  async fetchTurnCredentials() {
    try {
      const response = await fetch("/turn_credentials")
      const data = await response.json()
      this.iceServers = data.iceServers
    } catch (error) {
      console.error("Failed to fetch TURN credentials:", error)
      this.iceServers = []
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

  initializeWebRTC() {
    this.webrtc = new WebRTCManager(
      this.subscription,
      this.localStream,
      this.iceServers
    )
    this.webrtc.onRemoteStream = (stream) => {
      this.remoteVideoTarget.srcObject = stream
      this.remoteContainerTarget.classList.remove("hidden")
    }
    this.webrtc.onConnectionStateChange = (state) => {
      if (state === "connected") {
        if (this.hasStatusTarget) {
          this.statusTarget.textContent = "Connected"
        }
      } else if (state === "disconnected" || state === "failed") {
        this.handleHangup()
      }
    }
    this.webrtc.initialize()
  }

  handleSignaling(data) {
    switch (data.type) {
      case "answered":
        this.initializeWebRTC()
        this.webrtc.createOffer()
        if (this.hasStatusTarget) {
          this.statusTarget.textContent = "Connecting..."
        }
        break
      case "offer":
        if (!this.webrtc) {
          this.initializeWebRTC()
        }
        this.webrtc.handleOffer(data.sdp)
        break
      case "answer":
        this.webrtc.handleAnswer(data.sdp)
        break
      case "ice_candidate":
        if (this.webrtc) {
          this.webrtc.handleIceCandidate(data.candidate)
        }
        break
      case "hangup":
        this.handleHangup()
        break
      case "timeout":
        if (this.hasStatusTarget) {
          this.statusTarget.textContent = "No answer"
        }
        setTimeout(() => {
          window.location.href = "/contacts"
        }, 2000)
        break
      case "declined":
        if (this.hasStatusTarget) {
          this.statusTarget.textContent = "Call declined"
        }
        setTimeout(() => {
          window.location.href = "/contacts"
        }, 2000)
        break
    }
  }

  handleHangup() {
    this.webrtc?.close()
    window.location.href = "/contacts"
  }

  endCall() {
    const csrfToken = document.querySelector("[name='csrf-token']")?.content || ""
    fetch(`/calls/${this.callIdValue}/hangup`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken
      }
    }).then(() => {
      this.handleHangup()
    })
  }

  disconnect() {
    this.webrtc?.close()
    this.subscription?.unsubscribe()
  }
}
