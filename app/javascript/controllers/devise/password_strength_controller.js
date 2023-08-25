import {Controller} from "@hotwired/stimulus"
import zxcvbn from "zxcvbn";

export default class PasswordStrengthController extends Controller {
    static targets = ["password", "confirm", "tips", "warning", "crackTime", "meterInner", "meter"];
    static values = {
        minScore: Number,
    }

    connect() {
        console.debug('Password strength controller connected!', this);

        this.calc();
    }

    calc() {
        this.onConfirm();

        let result = zxcvbn(this.passwordTarget.value);

        this.crackTimeTarget.innerText = `${result.crack_times_display["offline_slow_hashing_1e4_per_second"]}`;

        let scoreClass = this.scoreClass(result.score);
        let strengthValue = this.strengthPercentage(result.guesses_log10);

        this.meterTarget.setAttribute('aria-valuenow', Math.floor(strengthValue).toString());

        this.meterInnerTarget.className = this.meterInnerTarget.className.replace(/\bbg-.+\b/, scoreClass);
        this.meterInnerTarget.style['width'] = `${strengthValue}%`;

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
        if (this.confirmTarget.value === "") {
            if (this.passwordTarget.value === "") {
                this.confirmTarget.classList.remove('is-invalid');
            }

            return;
        }

        if (this.passwordTarget.value !== this.confirmTarget.value) {
            this.confirmTarget.classList.add('is-invalid');
        } else {
            this.confirmTarget.classList.remove('is-invalid');
        }
    }

    scoreClass(score) {
        if (score === 4 || (score > this.minScoreValue)) return "bg-success";
        return (score < this.minScoreValue) ? "bg-danger" : "bg-warning";
    }

    strengthPercentage(guessCount) {
        // calculated such that a password of score 3 (10^8) will be in the middle.
        return Math.min(guessCount * (1 / 16) * 100, 100);
    }
}