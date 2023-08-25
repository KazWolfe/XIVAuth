import {Controller} from "@hotwired/stimulus"
import zxcvbn from "zxcvbn";

export default class PasswordStrengthController extends Controller {
    static targets = ["password", "confirm", "strength", "tips", "warning", "crackTime"];

    connect() {
        console.debug('Password strength controller connected!');
        this.calc();
    }

    calc() {
        this.onConfirm();

        let result = zxcvbn(this.passwordTarget.value);

        this.strengthTarget.value = result.score.toString();
        this.crackTimeTarget.innerText = result.crack_times_display["offline_slow_hashing_1e4_per_second"];

        this.tipsTarget.innerHTML = "";
        if (result.feedback.warning) {
            let el = document.createElement("li");
            el.classList.add("text-warning-emphasis", "fw-bold");
            el.innerText = result.feedback.warning;

            this.tipsTarget.appendChild(el);
        }

        result.feedback.suggestions.forEach(tip => {
            let el = document.createElement("li");
            el.innerText = tip;

            this.tipsTarget.appendChild(el);
        })
    }

    onConfirm() {
        if (this.confirmTarget.value === "") return;

        if (this.passwordTarget.value !== this.confirmTarget.value) {
            this.confirmTarget.classList.add('is-invalid');
        } else {
            this.confirmTarget.classList.remove('is-invalid');
        }
    }
}