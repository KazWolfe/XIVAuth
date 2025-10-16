import {WebauthnControllerBase} from "../webauthn_base";
import * as WebAuthnJSON from "@github/webauthn-json";
import {PublicKeyCredentialWithAssertionJSON, PublicKeyCredentialWithAttestationJSON} from "@github/webauthn-json";


export default class WebauthnRegistrationController extends WebauthnControllerBase {
    static targets = ["challenge", "response", "feedback"];

    declare readonly feedbackTarget: HTMLDivElement;

    async register(event: SubmitEvent) {
        event.preventDefault();

        let credential: PublicKeyCredentialWithAttestationJSON;

        try {
            // FIXME: Bug in certain password managers where they don't support toJSON on the response.
            credential = await WebAuthnJSON.create({
                "publicKey": JSON.parse(this.challengeTarget.value)
            });
        } catch (err: unknown) {
            if (err instanceof DOMException && err.name === "NotAllowedError") {
                this.feedbackTarget.innerText = "Your browser blocked an attempt to register a security key. Please " +
                    "make sure you have one available and try again.";
                this.feedbackTarget.classList.remove("d-none");
                return;
            }

            if (err instanceof DOMException && err.name === "NotSupportedError") {
                this.feedbackTarget.innerText = "Your browser does not support WebAuthn. Please try again with a " +
                    "different browser.";
                this.feedbackTarget.classList.remove("d-none");
                return;
            }

            throw err;
        }

        this.responseTarget.value = JSON.stringify(credential);
        (event.target as HTMLFormElement).submit();
    }
}