import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "callerName"]
  static values = { callId: Number }

  connect() {
    this.handleIncomingCall = this.handleIncomingCall.bind(this)
    this.handleCallAnswered = this.handleCallAnswered.bind(this)
    window.addEventListener("incoming-call", this.handleIncomingCall)
    window.addEventListener("call-answered", this.handleCallAnswered)
  }

  disconnect() {
    window.removeEventListener("incoming-call", this.handleIncomingCall)
    window.removeEventListener("call-answered", this.handleCallAnswered)
  }

  handleIncomingCall(event) {
    const { call_id, caller_name } = event.detail
    this.callIdValue = call_id
    this.callerNameTarget.textContent = `${caller_name} is calling...`
    this.containerTarget.classList.remove("hidden")
  }

  handleCallAnswered(event) {
    if (event.detail.call_id === this.callIdValue) {
      this.dismiss()
    }
  }

  dismiss() {
    this.containerTarget.classList.add("hidden")
    this.callIdValue = 0
  }

  answer() {
    const csrfToken = document.querySelector("[name='csrf-token']")?.content || ""
    fetch(`/calls/${this.callIdValue}/answer`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken
      },
      redirect: "follow"
    }).then(response => {
      if (response.ok || response.redirected) {
        window.location.href = response.url
      }
    })
  }

  decline() {
    const csrfToken = document.querySelector("[name='csrf-token']")?.content || ""
    fetch(`/calls/${this.callIdValue}/decline`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken
      }
    }).then(() => {
      this.dismiss()
    })
  }
}
