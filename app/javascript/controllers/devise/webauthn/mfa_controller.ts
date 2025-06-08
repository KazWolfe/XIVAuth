import {WebauthnControllerBase} from "../webauthn_base";
import * as WebAuthnJSON from "@github/webauthn-json";

export default class WebauthnMFAController extends WebauthnControllerBase {
    async authenticate(event) {
        console.warn("AUTHENTICATION REQUEST RECEIVED!!!")
        event.preventDefault();

        let credential = await WebAuthnJSON.get({
            "publicKey": JSON.parse(this.challengeTarget.value)
        });

        this.responseTarget.value = JSON.stringify(credential);
        event.target.form.submit();
    }
}