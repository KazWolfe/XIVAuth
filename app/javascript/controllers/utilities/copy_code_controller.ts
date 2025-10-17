import {Controller} from "@hotwired/stimulus";

export default class CopyCodeController extends Controller {
    static targets = [ "source", "button" ]
    static values = { timeout: Number }

    // These target helpers are declared for type-safety; prefix unused ones to appease linters.
    declare readonly _hasSourceTarget: boolean;
    declare readonly sourceTarget: HTMLInputElement | HTMLTextAreaElement;
    declare readonly _sourceTargets: (HTMLInputElement | HTMLTextAreaElement)[];

    declare readonly _hasButtonTarget: boolean;
    declare readonly buttonTarget: HTMLButtonElement;
    declare readonly _buttonTargets: HTMLButtonElement[];

    declare readonly hasTimeoutValue: boolean;
    declare timeoutValue: number;

    private resetTimer?: number;

    connect() {
        // Default to 2000ms if not provided via data-utilities--copy-code-timeout-value
        if (!this.hasTimeoutValue) {
            this.timeoutValue = 2000;
        }
    }

    disconnect() {
        if (this.resetTimer) {
            window.clearTimeout(this.resetTimer);
            this.resetTimer = undefined;
        }
    }

    copy(event: PointerEvent) {
        event.preventDefault();

        // Copy the source value to clipboard
        navigator.clipboard.writeText(this.sourceTarget.value);

        // Capture original content to allow revert
        const originalHTML = this.buttonTarget.innerHTML;
        const originalClassName = this.buttonTarget.className;

        // Set temporary "Copied!" state
        const icon = document.createElement("i");
        icon.classList.add("bi", "bi-clipboard-check");

        this.buttonTarget.classList.remove("btn-outline-secondary");
        this.buttonTarget.classList.add("btn-outline-success");
        this.buttonTarget.innerHTML = " Copied!";
        this.buttonTarget.prepend(icon);

        // Clear existing timer if present, then schedule a revert
        if (this.resetTimer) {
            window.clearTimeout(this.resetTimer);
        }
        this.resetTimer = window.setTimeout(() => {
            this.buttonTarget.className = originalClassName;
            this.buttonTarget.innerHTML = originalHTML;
            this.resetTimer = undefined;
        }, this.timeoutValue);
    }
}