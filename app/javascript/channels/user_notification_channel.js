import consumer from "channels/consumer"

consumer.subscriptions.create("UserNotificationChannel", {
  received(data) {
    switch (data.type) {
      case "incoming_call":
        window.dispatchEvent(new CustomEvent("incoming-call", { detail: data }))
        break
      case "call_answered":
        window.dispatchEvent(new CustomEvent("call-answered", { detail: data }))
        break
      case "call_timeout":
        window.dispatchEvent(new CustomEvent("call-timeout", { detail: data }))
        break
    }
  }
})
