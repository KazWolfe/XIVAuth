import {WebauthnControllerBase} from "../webauthn_base";
import * as WebAuthnJSON from "@github/webauthn-json";

export default class WebauthnRegistrationController extends WebauthnControllerBase {
    async register(event) {
        event.preventDefault();

        let credential = await WebAuthnJSON.create({
            "publicKey": JSON.parse(this.challengeTarget.value)
        });

        this.responseTarget.value = JSON.stringify(credential);
        event.target.submit();
    }
}