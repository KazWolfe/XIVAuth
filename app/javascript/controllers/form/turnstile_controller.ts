import {Controller} from "@hotwired/stimulus";
import RenderParameters = Turnstile.RenderParameters;

export default class TurnstileFormController extends Controller<HTMLFormElement> {
    submitButton?: HTMLInputElement;
    submitButtonText?: string;

    connect() {
        console.log("Turnstile form connected.");

        const turnstileEl = this.element.querySelector('.cf-turnstile') as HTMLElement;
        this.submitButton = this.element.querySelector('[type="submit"]') || undefined;

        let turnstileElData = Object.assign({}, turnstileEl.dataset) as unknown as RenderParameters;

        if (this.submitButton) {
            turnstileElData.callback = this.onTurnstileSuccess.bind(this);
            this.submitButtonText = this.submitButton.value;

            this.submitButton.value = "Waiting for captcha...";
            this.submitButton.disabled = true;
        }

        turnstile.render(turnstileEl, turnstileElData);
    }

    onTurnstileSuccess() {
        if (this.submitButton) {
            this.submitButton.disabled = false;
            this.submitButton.value = this.submitButtonText || "Submit";
        }
    }
}