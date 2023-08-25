import {Controller} from "@hotwired/stimulus"
import zxcvbn from "zxcvbn";

export default class PasswordStrengthController extends Controller {
    static targets = ["password", "confirm", "strength", "tips", "warning", "crackTime", "meter"];
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

        this.crackTimeTarget.innerText = `${result.crack_times_display["offline_slow_hashing_1e4_per_second"]} (${result.guesses_log10})`;

        let scoreClass = this.scoreClass(result.score);
        this.meterTarget.className = this.meterTarget.className.replace(/\bbg-.+\b/, scoreClass);
        this.meterTarget.style['width'] = `${this.strengthPercentage(result.guesses_log10)}%`;

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
        return Math.min(guessCount * 10, 100);
    }
}