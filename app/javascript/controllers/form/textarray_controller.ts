import {Controller} from "@hotwired/stimulus";

export default class TextArrayController extends Controller {
    static targets = ["input"];

    declare readonly inputTargets: HTMLInputElement[];

    templateElement?: HTMLDivElement;

    connect() {
        console.log("CONNECTED!");
        super.connect();
        this.calculateDisables();

        this.templateElement = this.inputTargets[0].cloneNode(true) as HTMLDivElement;
        this.templateElement.querySelector("input")!.value = "";
        for (let child of this.templateElement.children) {
            if (child.getAttribute("data-nocopy") != null) {
                child.remove();
            }
        }
    }

    addNewField() {
        let lastNode = this.inputTargets[this.inputTargets.length - 1];
        let clone = this.templateElement!.cloneNode(true) as HTMLDivElement;

        if (lastNode) {
            let parent = lastNode.parentElement as HTMLDivElement;
            parent.insertBefore(clone, lastNode.nextElementSibling);
        } else {
            // edge case if we don't have any elements somehow
            this.element.prepend(clone);
        }

        this.calculateDisables();
    }

    removeField(event: MouseEvent) {
        let target = event.currentTarget as HTMLButtonElement;
        target.parentElement!.remove();
        this.calculateDisables();
    }

    calculateDisables() {
        let inputCount = this.inputTargets.length;
        if (inputCount == 1) {
            this.inputTargets[0].querySelector('button[name="deleteRow"]')!.setAttribute("disabled", "disabled");
        } else {
            this.inputTargets.forEach((input) => {
                input.querySelector("button[name=\"deleteRow\"]")!.removeAttribute("disabled");
            })
        }
    }
}