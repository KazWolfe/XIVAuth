import { Controller} from '@hotwired/stimulus'

export default class CopyCodeController extends Controller {
    static targets = [ "source", "button" ]

    connect() {

    }

    copy(event) {
        event.preventDefault();
        navigator.clipboard.writeText(this.sourceTarget.value);

        let el = document.createElement("i");
        el.classList.add("bi", "bi-clipboard-check");

        this.buttonTarget.classList.replace("btn-outline-secondary", "btn-outline-success");
        this.buttonTarget.innerText = " Copied!";
        this.buttonTarget.prepend(el);
    }
}