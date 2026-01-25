export class WebRTCManager {
  constructor(channel, localStream, iceServers) {
    this.channel = channel
    this.localStream = localStream
    this.iceServers = iceServers
    this.peerConnection = null
    this.remoteStream = new MediaStream()
  }

  async initialize() {
    this.peerConnection = new RTCPeerConnection({
      iceServers: this.iceServers
    })

    this.localStream.getTracks().forEach(track => {
      this.peerConnection.addTrack(track, this.localStream)
    })

    this.peerConnection.ontrack = (event) => {
      event.streams[0].getTracks().forEach(track => {
        this.remoteStream.addTrack(track)
      })
      this.onRemoteStream?.(this.remoteStream)
    }

    this.peerConnection.onicecandidate = (event) => {
      if (event.candidate) {
        this.channel.send({
          type: "ice_candidate",
          candidate: event.candidate
        })
      }
    }

    this.peerConnection.onconnectionstatechange = () => {
      this.onConnectionStateChange?.(this.peerConnection.connectionState)
    }
  }

  async createOffer() {
    const offer = await this.peerConnection.createOffer()
    await this.peerConnection.setLocalDescription(offer)
    this.channel.send({
      type: "offer",
      sdp: offer.sdp
    })
  }

  async handleOffer(sdp) {
    await this.peerConnection.setRemoteDescription({
      type: "offer",
      sdp: sdp
    })
    const answer = await this.peerConnection.createAnswer()
    await this.peerConnection.setLocalDescription(answer)
    this.channel.send({
      type: "answer",
      sdp: answer.sdp
    })
  }

  async handleAnswer(sdp) {
    await this.peerConnection.setRemoteDescription({
      type: "answer",
      sdp: sdp
    })
  }

  async handleIceCandidate(candidate) {
    if (this.peerConnection.remoteDescription) {
      await this.peerConnection.addIceCandidate(candidate)
    }
  }

  async replaceVideoTrack(newTrack) {
    const sender = this.peerConnection?.getSenders().find(s => s.track?.kind === "video")
    if (sender) {
      await sender.replaceTrack(newTrack)
    }
  }

  close() {
    this.peerConnection?.close()
    this.localStream?.getTracks().forEach(t => t.stop())
  }
}
