import { createConsumer } from "@rails/actioncable"

const consumer = createConsumer()
window.cableConsumer = consumer

document.addEventListener("turbo:load", () => {
  if (consumer.connection.disconnected) {
    consumer.connection.open()
  }
})

export default consumer
