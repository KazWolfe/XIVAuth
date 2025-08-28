import {WebauthnControllerBase} from "../webauthn_base";
import * as WebAuthnJSON from "@github/webauthn-json";

export default class WebauthnMFAController extends WebauthnControllerBase {
    async authenticate(event) {
        console.warn("AUTHENTICATION REQUEST RECEIVED!!!")
        event.preventDefault();

        // let discovery = PublicKeyCredential.parseRequestOptionsFromJSON(JSON.parse(this.challengeTarget.value));
        // let credential = await navigator.credentials.get({publicKey: discovery}) as PublicKeyCredential | null;

        // FIXME: Bug in certain password managers where they don't support toJSON on the response.
        let credential = await WebAuthnJSON.get({
            "publicKey": JSON.parse(this.challengeTarget.value)
        });
        
        if (credential) {
            this.responseTarget.value = JSON.stringify(credential);
            event.target.form.submit();
        }
    }
}