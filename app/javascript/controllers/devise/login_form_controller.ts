import {Controller} from "@hotwired/stimulus";
import * as WebAuthnJSON from "@github/webauthn-json";
import RenderParameters = Turnstile.RenderParameters;

export default class LoginFormController extends Controller {
    static targets = ["webauthnChallenge", "webauthnResponse", "actionButton"];

    declare readonly webauthnChallengeTarget: HTMLInputElement;
    declare readonly webauthnResponseTarget: HTMLInputElement;
    declare readonly actionButtonTargets: HTMLButtonElement[] | undefined;

    private discoveryAbortController: AbortController = new AbortController();

    async connect() {
        console.log("Login form connected.", this);

        const turnstileEl = this.element.querySelector('.cf-turnstile') as HTMLElement;
        let turnstileElData = Object.assign({}, turnstileEl.dataset) as unknown as RenderParameters;
        turnstileElData.callback = this.handleTurnstileSuccess.bind(this);

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

    async disconnect() {
        this.discoveryAbortController.abort();
        super.disconnect();
    }

    async webauthnRunConditional() {
        if (!await this.checkConditionalMediation()) {
            return;
        }

        // FIXME: Bug in certain password managers where they don't support toJSON on the response.
        let discoveredCredential = await WebAuthnJSON.get({
            "signal": this.discoveryAbortController.signal,
            "publicKey": JSON.parse(this.webauthnChallengeTarget.value),
            "mediation": "conditional",
        });

        // let discoveryOpts = PublicKeyCredential.parseRequestOptionsFromJSON({
        //    ...JSON.parse(this.challengeTarget.value),
        //
        //    "mediation": "conditional",
        //    "signal": this.discoveryAbortController.signal,
        // });
        //
        // let discoveredCredential = await navigator.credentials.get({publicKey: discoveryOpts}) as PublicKeyCredential;

        if (discoveredCredential) {
            this.webauthnResponseTarget.value = JSON.stringify(discoveredCredential);

            this.webauthnResponseTarget.form!.submit();
        }
    }

    webauthnAbort() {
        this.discoveryAbortController.abort();
    }

    async webauthnManualDiscovery() {
        // stop conditional first, we don't need it anymore.
        this.discoveryAbortController.abort();

        // FIXME: Bug in certain password managers where they don't support toJSON on the response.
        let discoveredCredential = await WebAuthnJSON.get({
            "publicKey": JSON.parse(this.webauthnChallengeTarget.value),
        });

        if (discoveredCredential) {
            this.webauthnResponseTarget.value = JSON.stringify(discoveredCredential);
            this.webauthnResponseTarget.form!.submit();
        }
    }

    private handleTurnstileSuccess() {
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

    private async checkConditionalMediation() {
        return window.PublicKeyCredential?.isConditionalMediationAvailable ||
            (await window.PublicKeyCredential?.isConditionalMediationAvailable());
    }
}
