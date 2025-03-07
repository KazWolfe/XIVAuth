import {Controller} from "@hotwired/stimulus";

export default class CopyCodeController extends Controller {
    static targets = [ "source", "button" ]

    declare readonly hasSourceTarget: boolean;
    declare readonly sourceTarget: HTMLInputElement;
    declare readonly sourceTargets: HTMLInputElement[];

    declare readonly hasButtonTarget: boolean;
    declare readonly buttonTarget: HTMLInputElement;
    declare readonly buttonTargets: HTMLInputElement[];

    connect() { }

    copy(event: PointerEvent) {
        event.preventDefault();
        navigator.clipboard.writeText(this.sourceTarget.value);

        let el = document.createElement("i");
        el.classList.add("bi", "bi-clipboard-check");

        this.buttonTarget.classList.replace("btn-outline-secondary", "btn-outline-success");
        this.buttonTarget.innerText = " Copied!";
        this.buttonTarget.prepend(el);
    }
}