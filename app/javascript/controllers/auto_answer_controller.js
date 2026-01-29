import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["answerButton"]

  connect() {
    if (this.hasAnswerButtonTarget) {
      this.answerButtonTarget.click()
    }
  }
}
