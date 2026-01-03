import consumer from "./consumer"

consumer.subscriptions.create("UserNotificationChannel", {
  received(data) {
    if (data.type === "incoming_call") {
      window.dispatchEvent(new CustomEvent("incoming-call", { detail: data }))
    }
  }
})
