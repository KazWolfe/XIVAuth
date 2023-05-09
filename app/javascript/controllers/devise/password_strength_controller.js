import {Controller} from "@hotwired/stimulus"
import zxcvbn from "zxcvbn";

export default class PasswordStrengthController extends Controller {
    static targets = ["password", "confirm", "strength", "tips", "warning"];

    _confirmWasFocused = false;

    connect() {
        console.debug('Password strength controller connected!');
    }

    calc() {
        this.onConfirm();

        let result = zxcvbn(this.passwordTarget.value);

        if (this.passwordTarget.value !== this.confirmTarget.value) {
            this.confirmTarget.classList.add('is-invalid');
        } else {
            this.confirmTarget.classList.remove('is-invalid');
        }

        this.strengthTarget.value = result.score.toString();

        this.tipsTarget.innerHTML = "";
        if (result.feedback.warning) {
            let el = document.createElement("li");
            el.classList.add("text-warning");
            el.innerText = result.feedback.warning;

            this.tipsTarget.appendChild(el);
        }

        result.feedback.suggestions.forEach(tip => {
            let el = document.createElement("li");
            el.innerText = tip;

            this.tipsTarget.appendChild(el);
        })

        console.log("zxcvbn", result);
    }

    onConfirm() {
        if (this.confirmTarget.value === "") return;

        if (this.passwordTarget.value !== this.confirmTarget.value) {
            this.confirmTarget.classList.add('is-invalid');
        } else {
            this.confirmTarget.classList.remove('is-invalid');
        }
    }

    onConfirmFocus() {
        this._confirmWasFocused = true;
    }
}