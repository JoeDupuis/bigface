import consumer from "channels/consumer"

consumer.subscriptions.create("UserNotificationChannel", {
  received(data) {
  }
})
