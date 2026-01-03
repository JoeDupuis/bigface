import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "callerName"]
  static values = { callId: Number }

  connect() {
    this.handleIncomingCall = this.handleIncomingCall.bind(this)
    window.addEventListener("incoming-call", this.handleIncomingCall)
  }

  disconnect() {
    window.removeEventListener("incoming-call", this.handleIncomingCall)
  }

  handleIncomingCall(event) {
    const { call_id, caller_name } = event.detail
    this.callIdValue = call_id
    this.callerNameTarget.textContent = `${caller_name} is calling...`
    this.containerTarget.classList.remove("hidden")
  }

  answer() {
    fetch(`/calls/${this.callIdValue}/answer`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      },
      redirect: "follow"
    }).then(response => {
      if (response.ok || response.redirected) {
        window.location.href = response.url
      }
    })
  }

  decline() {
    fetch(`/calls/${this.callIdValue}/decline`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      }
    }).then(() => {
      this.containerTarget.classList.add("hidden")
    })
  }
}
