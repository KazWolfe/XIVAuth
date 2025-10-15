import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class RemoteModalController extends Controller {
    private modal?: Modal;

    connect() {
        this.modal = new Modal(this.element);
        this.modal.show();

        this.element.addEventListener('hide.bs.modal', this.cleanup.bind(this));
    }

    disconnect() {
        this.modal?.dispose();
    }

    hideBeforeRender(event: Modal.Event) {
        if (this.isOpen()) {
            event.preventDefault();
            this.element.addEventListener('hidden.bs.modal', event.detail.resume);
            this.modal!.hide();
        }
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