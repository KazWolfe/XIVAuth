import {Controller} from "@hotwired/stimulus"

export default class AutosavingFormController extends Controller<HTMLFormElement> {
    declare delayValue: number

    static values = {
        delay: {
            type: Number,
            default: 150,
        },
    }

    initialize(): void {
        this.submit = this.submit.bind(this)
    }

    connect(): void {
        if (this.delayValue > 0) {
            this.submit = this.debounce(this.submit, this.delayValue)
        }
    }

    submit(): void {
        this.element.requestSubmit()
    }

    private debounce(callback: Function, delay: number) {
        let timeout: number

        return (...args: unknown[]) => {
            clearTimeout(timeout)

            timeout = window.setTimeout(() => {
                callback.apply(this, args)
            }, delay)
        }
    }
}
