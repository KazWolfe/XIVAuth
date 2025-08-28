import {WebauthnControllerBase} from "../webauthn_base";
import * as WebAuthnJSON from "@github/webauthn-json";


export default class WebauthnRegistrationController extends WebauthnControllerBase {
    async register(event) {
        event.preventDefault();

        // FIXME: Bug in certain password managers where they don't support toJSON on the response.
        let credential = await WebAuthnJSON.create({
            "publicKey": JSON.parse(this.challengeTarget.value)
        });

        // let discovery = PublicKeyCredential.parseCreationOptionsFromJSON(JSON.parse(this.challengeTarget.value));
        // let credential = await navigator.credentials.create({publicKey: discovery}) as PublicKeyCredential | null;

        this.responseTarget.value = JSON.stringify(credential);
        event.target.submit();
    }
}