import {Controller} from "@hotwired/stimulus";
import * as WebAuthnJSON from "@github/webauthn-json";
import RenderParameters = Turnstile.RenderParameters;
import {PublicKeyCredentialWithAssertionJSON} from "@github/webauthn-json";

export default class LoginFormController extends Controller {
    static targets = ["webauthnChallenge", "webauthnResponse", "actionButton"];

    declare readonly webauthnChallengeTarget: HTMLInputElement;
    declare readonly webauthnResponseTarget: HTMLInputElement;
    declare readonly actionButtonTargets: HTMLButtonElement[] | undefined;

    private discoveryAbortController: AbortController = new AbortController();

    async initialize() {
        console.debug("Login form initialized", this);

        // bind turnstile to turbo so we can update things
        const turnstileEl = this.element.querySelector('.cf-turnstile') as HTMLElement;
        turnstileEl.addEventListener("turbo:morph-element", this.initializeTurnstileChallenge.bind(this));

        this.initializeTurnstileChallenge();
    }

    async connect() {
        console.debug("Login form connected.");

        this.discoveryAbortController = new AbortController();
    }

    async disconnect() {
        this.discoveryAbortController.abort("disconnect");
        super.disconnect();

        console.debug("Login form disconnected.");
    }

    async webauthnRunConditional() {
        if (!await this.checkConditionalMediation()) {
            return;
        }

        let discoveredCredential: PublicKeyCredentialWithAssertionJSON;
        try {
            // FIXME: Bug in certain password managers where they don't support toJSON on the response.
            discoveredCredential = await WebAuthnJSON.get({
                "signal": this.discoveryAbortController.signal,
                "publicKey": JSON.parse(this.webauthnChallengeTarget.value),
                "mediation": "conditional",
            });
        } catch (e: unknown) {
            return;
        }

        if (discoveredCredential) {
            this.webauthnResponseTarget.value = JSON.stringify(discoveredCredential);

            this.webauthnResponseTarget.form!.submit();
        }
    }

    webauthnAbort() {
        this.discoveryAbortController.abort("passwordLogin");
    }

    async webauthnManualDiscovery() {
        // stop conditional first, we don't need it anymore.
        this.discoveryAbortController.abort("manualWebauthn");

        // FIXME: Bug in certain password managers where they don't support toJSON on the response.
        let discoveredCredential = await WebAuthnJSON.get({
            "publicKey": JSON.parse(this.webauthnChallengeTarget.value),
        });

        if (discoveredCredential) {
            this.webauthnResponseTarget.value = JSON.stringify(discoveredCredential);
            this.webauthnResponseTarget.form!.submit();
        }
    }

    private initializeTurnstileChallenge() {
        const turnstileEl = this.element.querySelector('.cf-turnstile') as HTMLElement;
        let turnstileElData = Object.assign({}, turnstileEl.dataset) as unknown as RenderParameters;
        turnstileElData["before-interactive-callback"] = this.onTurnstileNeedsInteractive.bind(this);
        turnstileElData.callback = this.onTurnstileSuccess.bind(this);

        this.actionButtonTargets?.forEach(button => {
            if (button.innerText.trim().length > 0) {
                button.setAttribute("data-original-text", button.innerText);
                button.innerText = "Waiting for captcha...";
            }

            if (button.value.trim().length > 0) {
                button.setAttribute("data-original-value", button.value);
                button.value = "Waiting for captcha...";
            }

            button.disabled = true;
            button.classList.add('disabled');
        });

        turnstile.render(turnstileEl, turnstileElData);
    }

    private onTurnstileNeedsInteractive() {
        const turnstileEl = this.element.querySelector('.cf-turnstile') as HTMLElement;
        turnstileEl.classList.add('pt-2');
    }

    private onTurnstileSuccess() {
        this.webauthnRunConditional().then(); // faf

        this.actionButtonTargets?.forEach(button => {
            button.disabled = false;
            button.classList.remove('disabled');

            const originalText = button.getAttribute("data-original-text");
            if (originalText) {
                button.innerText = originalText;
                button.removeAttribute("data-original-text");
            }

            const originalValue = button.getAttribute("data-original-value");
            if (originalValue) {
                button.value = originalValue;
                button.removeAttribute("data-original-value");
            }
        })
    }

    private onTurboMorph(event: HTMLElement) {
        console.log("Turbo morph event detected.", event);

        this.initializeTurnstileChallenge();
    }

    private async checkConditionalMediation() {
        return window.PublicKeyCredential?.isConditionalMediationAvailable ||
            (await window.PublicKeyCredential?.isConditionalMediationAvailable());
    }
}
