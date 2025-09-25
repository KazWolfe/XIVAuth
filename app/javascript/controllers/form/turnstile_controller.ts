import {Controller} from "@hotwired/stimulus";

export default class TurnstileController extends Controller<HTMLDivElement> {
    connect() {
        console.log("Turnstile connected.");

        if (turnstile && this.element.innerHTML.trim() === "") {
            turnstile.render(this.element);
        }
    }
}