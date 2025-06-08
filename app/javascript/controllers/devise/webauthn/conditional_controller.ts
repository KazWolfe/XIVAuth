import {WebauthnControllerBase} from "../webauthn_base";
import * as WebAuthnJSON from "@github/webauthn-json";

export default class WebauthnConditionalController extends WebauthnControllerBase {
    private discoveryAbortController: AbortController = new AbortController();

    async connect() {
        await this.authenticate_conditional();
    }

    async disconnect() {
        this.discoveryAbortController.abort();
        super.disconnect();
    }

    async authenticate_conditional() {
        if (!await this.check_conditional_mediation()) {
            return;
        }

        let discoveredCredential = await WebAuthnJSON.get({
            "signal": this.discoveryAbortController.signal,
            "publicKey": JSON.parse(this.challengeTarget.value),
            "mediation": "conditional",
        });

        if (discoveredCredential) {
            this.responseTarget.value = JSON.stringify(discoveredCredential);

            // trigger recaptcha if we have it
            if (this.responseTarget.form.querySelector("#g-recaptcha-response") != null) {
                window.grecaptcha.execute();
            } else {
                this.responseTarget.form.submit();
            }
        }
    }

    immediate_abort() {
        this.discoveryAbortController.abort();
    }

    private async check_conditional_mediation() {
        return window.PublicKeyCredential?.isConditionalMediationAvailable ||
            (await window.PublicKeyCredential?.isConditionalMediationAvailable()) ||
            navigator.credentials.conditionalMediationSupported;
    }
}