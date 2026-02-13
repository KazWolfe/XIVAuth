import { Controller } from "@hotwired/stimulus"

// Enables a submit button only when the user has typed an exact confirmation string.
//
// Usage:
//   data-controller="form--confirm"
//   data-form--confirm-text-value="REVOKE"
//   data-form--confirm-input-target  (the text input)
//   data-form--confirm-submit-target (the submit button)
export default class ConfirmController extends Controller {
    static values = { text: String, caseSensitive: { type: Boolean, default: false } }
    static targets = ["input", "submit"]

    declare textValue: string
    declare caseSensitiveValue: boolean
    declare inputTarget: HTMLInputElement
    declare submitTarget: HTMLButtonElement

    connect() {
        this.validate()
    }

    validate() {
        const input    = this.inputTarget.value
        const expected = this.textValue
        const matches  = this.caseSensitiveValue
            ? input === expected
            : input.toLowerCase() === expected.toLowerCase()
        this.submitTarget.disabled = !matches
    }
}
