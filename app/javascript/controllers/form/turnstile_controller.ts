import {Controller} from "@hotwired/stimulus";
import RenderParameters = Turnstile.RenderParameters;

export default class TurnstileFormController extends Controller<HTMLFormElement> {
    submitButton?: HTMLInputElement;
    submitButtonText?: string;

    initialize() {
        console.log("Turnstile-protected form intialized", this);

        // bind turnstile to turbo so we can update things
        const turnstileEl = this.element.querySelector('.cf-turnstile') as HTMLElement;
        turnstileEl.addEventListener("turbo:morph-element", this.initializeTurnstileChallenge.bind(this));

        this.initializeTurnstileChallenge();
    }

    onTurnstileSuccess() {
        if (this.submitButton) {
            this.submitButton.disabled = false;
            this.submitButton.value = this.submitButtonText || "Submit";
        }
    }

    private onTurnstileNeedsInteractive() {
        const turnstileEl = this.element.querySelector('.cf-turnstile') as HTMLElement;
        turnstileEl.classList.add('pt-2');
    }

    initializeTurnstileChallenge() {
        const turnstileEl = this.element.querySelector('.cf-turnstile') as HTMLElement;
        this.submitButton = this.element.querySelector('[type="submit"]') || undefined;

        let turnstileElData = Object.assign({}, turnstileEl.dataset) as unknown as RenderParameters;

        turnstileElData.callback = this.onTurnstileSuccess.bind(this);
        turnstileElData["before-interactive-callback"] = this.onTurnstileNeedsInteractive.bind(this);

        if (this.submitButton) {
            this.submitButtonText = this.submitButton.value;

            this.submitButton.value = "Waiting for captcha...";
            this.submitButton.disabled = true;
        }

        turnstile.render(turnstileEl, turnstileElData);
    }

    onTurboMorph(event: HTMLElement) {
        console.log("Turbo morph event detected.", event);
        this.initializeTurnstileChallenge();
    }
}