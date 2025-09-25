import {Controller} from "@hotwired/stimulus";

export default class TurnstileController extends Controller<HTMLDivElement> {
    connect() {
        console.log("Turnstile connected.");

        if (window.turnstile && this.element.innerHTML.trim() === "") {
            window.turnstile.render(this.element);
        }
    }
}