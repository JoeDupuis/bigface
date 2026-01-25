import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"
import { WebRTCManager } from "lib/webrtc_manager"

export default class extends Controller {
  static targets = ["localVideo", "remoteVideo", "remoteContainer", "status", "switchCameraButton"]
  static values = { callId: Number, role: String, userId: Number }

  currentFacingMode = "user"

  async connect() {
    await this.startLocalVideo()
    await this.fetchTurnCredentials()
    await this.checkMultipleCameras()
    this.subscribeToChannel()
  }

  async checkMultipleCameras() {
    try {
      const devices = await navigator.mediaDevices.enumerateDevices()
      const videoInputs = devices.filter(d => d.kind === "videoinput")
      if (videoInputs.length > 1 && this.hasSwitchCameraButtonTarget) {
        this.switchCameraButtonTarget.classList.remove("hidden")
      }
    } catch (error) {
      console.error("Failed to enumerate devices:", error)
    }
  }

  async startLocalVideo(facingMode = "user") {
    try {
      this.localStream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: facingMode },
        audio: true
      })
      this.localVideoTarget.srcObject = this.localStream
      this.currentFacingMode = facingMode
    } catch (error) {
      console.error("Failed to access camera/microphone:", error)
    }
  }

  async switchCamera() {
    const newFacingMode = this.currentFacingMode === "user" ? "environment" : "user"

    try {
      const newStream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: newFacingMode },
        audio: false
      })

      const newVideoTrack = newStream.getVideoTracks()[0]
      const oldVideoTrack = this.localStream.getVideoTracks()[0]

      if (oldVideoTrack) {
        oldVideoTrack.stop()
        this.localStream.removeTrack(oldVideoTrack)
      }

      this.localStream.addTrack(newVideoTrack)
      this.localVideoTarget.srcObject = this.localStream

      if (this.webrtc) {
        this.webrtc.replaceVideoTrack(newVideoTrack)
      }

      this.currentFacingMode = newFacingMode
    } catch (error) {
      console.error("Failed to switch camera:", error)
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
        connected: () => this.handleConnected(),
        received: (data) => this.handleSignaling(data)
      }
    )
  }

  handleConnected() {
    if (this.roleValue === "recipient") {
      this.subscription.send({ type: "ready" })
    }
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
    if (data.from === this.userIdValue) {
      return
    }

    switch (data.type) {
      case "answered":
        if (this.roleValue === "caller" && this.hasStatusTarget) {
          this.statusTarget.textContent = "Connecting..."
        }
        break
      case "ready":
        if (this.roleValue === "caller") {
          this.initializeWebRTC()
          this.webrtc.createOffer()
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
