import {Controller} from "@hotwired/stimulus";
import * as WebAuthnJSON from "@github/webauthn-json"

export default class WebauthnController extends Controller {
    static targets = [ "challenge", "response" ];

    declare readonly challengeTarget: HTMLInputElement;
    declare readonly responseTarget: HTMLInputElement;

    async authenticate(event) {
        event.preventDefault();

        let credential = await WebAuthnJSON.get({
            "publicKey": JSON.parse(this.challengeTarget.value)
        });

        this.responseTarget.value = JSON.stringify(credential);
        event.target.form.submit();
    }

    async register(event) {
        event.preventDefault();

        let credential = await WebAuthnJSON.create({
            "publicKey": JSON.parse(this.challengeTarget.value)
        });

        this.responseTarget.value = JSON.stringify(credential);
        event.target.submit();
    }
}