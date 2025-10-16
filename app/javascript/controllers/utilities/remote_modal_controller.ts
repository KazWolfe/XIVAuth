import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class RemoteModalController extends Controller<HTMLDivElement> {
    static targets = [ "remoteCloseTrigger" ];

    private modal?: Modal;

    connect() {
        this.modal = new Modal(this.element);
        this.modal.show();

        this.element.addEventListener('hidden.bs.modal', this.cleanup.bind(this));
    }

    disconnect() {
        this.modal?.dispose();
    }

    remoteCloseTriggerTargetConnected() {
        console.debug("Server requested we close the modal.");
        this.modal!.hide();
    }

    isOpen(): boolean {
        return this.element.classList.contains("show");
    }

    cleanup() {
        const parentEl = this.element.parentElement;

        if (parentEl && parentEl.tagName.toLowerCase() == "turbo-frame") {
            parentEl.remove();
        }
    }
}