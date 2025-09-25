import {Controller} from "@hotwired/stimulus";

export default class TurnstileController extends Controller<HTMLDivElement> {
    connect() {
        if (window.turnstile && this.element.innerHTML.trim() === "") {
            window.turnstile.render(this.element);
        }
    }
}