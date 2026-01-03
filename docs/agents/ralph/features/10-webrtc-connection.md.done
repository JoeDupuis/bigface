# WebRTC Connection

## Description

Establish the actual video connection between caller and recipient using WebRTC. This handles SDP offer/answer exchange and ICE candidate negotiation via Action Cable.

## Behavior

### Connection Flow

1. Caller creates RTCPeerConnection with TURN/STUN servers
2. Caller adds local media stream
3. Caller creates SDP offer
4. Caller sends offer via CallChannel
5. Recipient receives offer, creates answer
6. Recipient sends answer via CallChannel
7. Both exchange ICE candidates via CallChannel
8. Connection established, video flows

### Call Page Behavior

When call is active:
- Show local video (small, corner)
- Show remote video (large, center)
- Show "End Call" button

## Tests

### JavaScript Tests (if using Jest/Vitest)

**WebRTC manager creates peer connection**
- Given: TURN credentials
- When: initializing WebRTC
- Then: RTCPeerConnection is created with ice servers

**Offer is created and sent**
- Given: initialized peer connection with local stream
- When: starting call as caller
- Then: offer is created
- And: offer is sent via CallChannel

**Answer is created from offer**
- Given: received SDP offer
- When: processing as recipient
- Then: answer is created
- And: answer is sent via CallChannel

**ICE candidates are exchanged**
- Given: peer connection
- When: ICE candidate is generated
- Then: candidate is sent via CallChannel

**Remote stream is displayed**
- Given: established connection
- When: remote track is received
- Then: remote video element shows stream

### Integration Tests (System Tests)

**Video call connects** (may need to stub WebRTC)
- Given: Alice calls Bob
- And: Bob answers
- When: WebRTC negotiation completes
- Then: both see video (or connection established)

Note: Full WebRTC testing in browser is complex. Focus on:
- Signaling messages are sent/received correctly
- UI updates based on connection state

## Implementation Notes

### WebRTC Manager Class

```javascript
// app/javascript/lib/webrtc_manager.js
export class WebRTCManager {
  constructor(callChannel, localStream, iceServers) {
    this.callChannel = callChannel
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
        this.callChannel.send({
          type: "ice_candidate",
          candidate: event.candidate
        })
      }
    }
  }

  async createOffer() {
    const offer = await this.peerConnection.createOffer()
    await this.peerConnection.setLocalDescription(offer)
    this.callChannel.send({
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
    this.callChannel.send({
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
    await this.peerConnection.addIceCandidate(candidate)
  }

  close() {
    this.peerConnection?.close()
    this.localStream?.getTracks().forEach(t => t.stop())
  }
}
```

### Updated Call Controller

```javascript
// app/javascript/controllers/call_controller.js
import { Controller } from "@hotwired/stimulus"
import { WebRTCManager } from "../lib/webrtc_manager"
import consumer from "../channels/consumer"

export default class extends Controller {
  static values = { callId: Number, role: String }
  static targets = ["localVideo", "remoteVideo", "remoteContainer", "status"]

  async connect() {
    await this.startLocalVideo()
    await this.fetchTurnCredentials()
    this.subscribeToChannel()
  }

  async startLocalVideo() {
    this.localStream = await navigator.mediaDevices.getUserMedia({
      video: true,
      audio: true
    })
    this.localVideoTarget.srcObject = this.localStream
  }

  async fetchTurnCredentials() {
    const response = await fetch("/turn_credentials")
    const data = await response.json()
    this.iceServers = data.iceServers
  }

  subscribeToChannel() {
    this.channel = consumer.subscriptions.create(
      { channel: "CallChannel", call_id: this.callIdValue },
      {
        received: (data) => this.handleSignaling(data)
      }
    )

    this.webrtc = new WebRTCManager(
      this.channel,
      this.localStream,
      this.iceServers
    )
    this.webrtc.onRemoteStream = (stream) => {
      this.remoteVideoTarget.srcObject = stream
      this.remoteContainerTarget.classList.remove("hidden")
    }
    this.webrtc.initialize()

    if (this.roleValue === "caller") {
      // Wait for "answered" signal before creating offer
    }
  }

  handleSignaling(data) {
    switch (data.type) {
      case "answered":
        this.webrtc.createOffer()
        this.statusTarget.textContent = "Connecting..."
        break
      case "offer":
        this.webrtc.handleOffer(data.sdp)
        break
      case "answer":
        this.webrtc.handleAnswer(data.sdp)
        break
      case "ice_candidate":
        this.webrtc.handleIceCandidate(data.candidate)
        break
      case "hangup":
        this.handleHangup()
        break
    }
  }

  handleHangup() {
    this.webrtc.close()
    window.location.href = "/contacts"
  }

  disconnect() {
    this.webrtc?.close()
    this.channel?.unsubscribe()
  }
}
```

### Signaling Flow via CallChannel

1. Recipient answers → broadcasts `{ type: "answered" }`
2. Caller receives → creates offer → broadcasts `{ type: "offer", sdp: ... }`
3. Recipient receives → creates answer → broadcasts `{ type: "answer", sdp: ... }`
4. Both exchange `{ type: "ice_candidate", candidate: ... }`
5. Connection established

## Dependencies

- 05-action-cable-setup (need CallChannel)
- 06-turn-credentials (need TURN credentials endpoint)
- 09-incoming-call-ui (need answer flow to trigger WebRTC)
