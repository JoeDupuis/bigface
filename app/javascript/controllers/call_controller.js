import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"
import { WebRTCManager } from "lib/webrtc_manager"

export default class extends Controller {
  static targets = ["localVideo", "remoteVideo", "remoteContainer", "localContainer", "status", "switchCameraButton", "controls", "cancelButton", "endCallButton"]
  static values = { callId: Number, role: String, userId: Number, status: String }

  currentFacingMode = "user"
  hideControlsTimer = null
  isConnected = false
  feedsSwapped = false
  lastLocalTap = 0
  isDragging = false
  dragStartX = 0
  dragStartY = 0
  initialLeft = 0
  initialTop = 0

  async connect() {
    if (this.statusValue === "ended" || this.statusValue === "missed" || this.statusValue === "declined") {
      window.location.href = "/contacts"
      return
    }
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
        rejected: () => this.handleRejected(),
        received: (data) => this.handleSignaling(data)
      }
    )
  }

  handleRejected() {
    window.location.href = "/contacts"
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
        if (this.hasCancelButtonTarget) {
          this.cancelButtonTarget.classList.add("hidden")
        }
        if (this.hasEndCallButtonTarget) {
          this.endCallButtonTarget.classList.remove("hidden")
        }
        this.isConnected = true
        this.startHideTimer()
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
    this.localStream?.getTracks().forEach(t => t.stop())
    if (this.hasLocalVideoTarget) {
      this.localVideoTarget.srcObject = null
    }
    if (this.hasRemoteVideoTarget) {
      this.remoteVideoTarget.srcObject = null
    }
    this.clearHideTimer()
  }

  handleMouseMove(event) {
    if (event.pointerType !== "mouse" || !this.isConnected) return
    this.showControls()
    this.startHideTimer()
  }

  handleTap(event) {
    if (event.pointerType !== "touch" || !this.isConnected) return
    if (event.target.closest("button")) return
    event.preventDefault()
    event.stopImmediatePropagation()
    this.toggleControls()
  }

  handleLocalTap(event) {
    if (event.pointerType !== "touch") return
    event.preventDefault()
    event.stopPropagation()

    if (this.isDragging) {
      this.isDragging = false
      return
    }

    const now = Date.now()
    if (now - this.lastLocalTap < 300) {
      this.swapFeeds()
      this.lastLocalTap = 0
    } else {
      this.lastLocalTap = now
    }
  }

  swapFeeds() {
    const localStream = this.localVideoTarget.srcObject
    const remoteStream = this.remoteVideoTarget.srcObject
    if (!remoteStream) return

    this.localVideoTarget.srcObject = remoteStream
    this.remoteVideoTarget.srcObject = localStream
    this.feedsSwapped = !this.feedsSwapped
  }

  startDrag(event) {
    if (event.pointerType === "mouse" && event.button !== 0) return

    const container = this.localContainerTarget
    const rect = container.getBoundingClientRect()

    container.style.right = "auto"
    container.style.bottom = "auto"
    container.style.left = `${rect.left}px`
    container.style.top = `${rect.top}px`

    this.isDragging = false
    this.dragStartX = event.clientX
    this.dragStartY = event.clientY
    this.initialLeft = rect.left
    this.initialTop = rect.top

    container.classList.add("-dragging")
    container.setPointerCapture(event.pointerId)

    this.boundDrag = this.drag.bind(this)
    this.boundStopDrag = this.stopDrag.bind(this)
    container.addEventListener("pointermove", this.boundDrag)
    container.addEventListener("pointerup", this.boundStopDrag)
    container.addEventListener("pointercancel", this.boundStopDrag)
  }

  drag(event) {
    const dx = event.clientX - this.dragStartX
    const dy = event.clientY - this.dragStartY

    if (!this.isDragging && (Math.abs(dx) > 5 || Math.abs(dy) > 5)) {
      this.isDragging = true
    }

    if (!this.isDragging) return

    const container = this.localContainerTarget
    const containerWidth = container.offsetWidth
    const containerHeight = container.offsetHeight

    let newLeft = this.initialLeft + dx
    let newTop = this.initialTop + dy

    newLeft = Math.max(0, Math.min(newLeft, window.innerWidth - containerWidth))
    newTop = Math.max(0, Math.min(newTop, window.innerHeight - containerHeight))

    container.style.left = `${newLeft}px`
    container.style.top = `${newTop}px`
  }

  stopDrag(event) {
    const container = this.localContainerTarget
    container.classList.remove("-dragging")
    container.releasePointerCapture(event.pointerId)

    container.removeEventListener("pointermove", this.boundDrag)
    container.removeEventListener("pointerup", this.boundStopDrag)
    container.removeEventListener("pointercancel", this.boundStopDrag)
  }

  showControls() {
    if (this.hasControlsTarget) {
      this.controlsTarget.classList.remove("-hidden")
      setTimeout(() => {
        this.controlsTarget.querySelectorAll("button").forEach(btn => btn.disabled = false)
      }, 300)
    }
  }

  hideControls() {
    if (this.hasControlsTarget) {
      this.controlsTarget.querySelectorAll("button").forEach(btn => btn.disabled = true)
      this.controlsTarget.classList.add("-hidden")
    }
  }

  toggleControls() {
    if (this.hasControlsTarget) {
      const isHidden = this.controlsTarget.classList.contains("-hidden")
      if (isHidden) {
        this.showControls()
        this.startHideTimer()
      } else {
        this.hideControls()
        this.clearHideTimer()
      }
    }
  }

  startHideTimer() {
    this.clearHideTimer()
    this.hideControlsTimer = setTimeout(() => this.hideControls(), 3000)
  }

  resetHideTimer(event) {
    if (!this.isConnected) return
    if (this.controlsTarget.classList.contains("-hidden")) {
      event.preventDefault()
      event.stopPropagation()
      return
    }
    this.startHideTimer()
  }

  clearHideTimer() {
    if (this.hideControlsTimer) {
      clearTimeout(this.hideControlsTimer)
      this.hideControlsTimer = null
    }
  }
}
