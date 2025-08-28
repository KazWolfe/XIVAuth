import {WebauthnControllerBase} from "../webauthn_base";

export default class WebauthnRegistrationController extends WebauthnControllerBase {
    async register(event) {
        event.preventDefault();

        let discovery = PublicKeyCredential.parseCreationOptionsFromJSON(JSON.parse(this.challengeTarget.value));
        let credential = await navigator.credentials.create({publicKey: discovery}) as PublicKeyCredential | null;

        this.responseTarget.value = JSON.stringify(credential);
        event.target.submit();
    }
}