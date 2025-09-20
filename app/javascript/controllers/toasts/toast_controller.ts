import {Controller} from "@hotwired/stimulus";
import { Toast } from 'bootstrap';

export default class ToastController extends Controller {
    timeToClose = 15_000; // millis
    updateInterval = 100;

    // state
    bootstrapToast?: Toast;

    timer?: number;
    timerActive = false;
    timeElapsed = 0;

    connect() {
        this.bootstrapToast = Toast.getOrCreateInstance(this.element, {
            autohide: false,
            delay: this.timeToClose
        });
        this.bootstrapToast.show();

        this.element.addEventListener("mouseover", this.onHover.bind(this));
        this.element.addEventListener("mouseout", this.onUnHover.bind(this));

        this.element.addEventListener("shown.bs.toast", () => {
            this.timerActive = true;
            this.timer = setInterval(this.tick.bind(this), this.updateInterval);
        })

        this.element.addEventListener("hidden.bs.toast", () => {
            clearInterval(this.timer);
            this.element.remove();
        })
    }

    tick() {
        if (!this.timerActive) return;

        this.timeElapsed += this.updateInterval;

        let progressElement = this.element.querySelector("#pb") as HTMLDivElement | null;
        if (!progressElement) return;

        let percentRemaining = Math.round(((this.timeToClose - this.timeElapsed) / this.timeToClose) * 100);
        progressElement.style.width = `${percentRemaining}%`;

        if (this.timeElapsed >= this.timeToClose) {
            this.bootstrapToast?.hide();
            clearInterval(this.timer);
        }
    }

    onHover() {
        this.timerActive = false;
    }

    onUnHover() {
        this.timerActive = true;
    }
}
