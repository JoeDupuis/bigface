import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  filter(event) {
    const query = event.target.value.toLowerCase().trim()
    const cards = this.element.closest(".main-content").querySelectorAll(".contact-card")

    cards.forEach(card => {
      const name = card.dataset.name || ""
      card.style.display = name.includes(query) ? "" : "none"
    })
  }
}
