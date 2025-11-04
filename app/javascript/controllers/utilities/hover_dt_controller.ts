import {Controller} from "@hotwired/stimulus";

export default class HoverDateTimeController extends Controller<HTMLSpanElement> {
    static values = {ts: Number}

    declare readonly hasTsValue: boolean;
    declare tsValue: number;

    // A generic timestamp format that I like. Because browsers don't let me figure out exactly what the user wants,
    // this will have to do. Learn 24-hour time, Americans!
    static DATETIME_FORMAT: Intl.DateTimeFormatOptions = {
        hour12: false,
        month: "long",
        day: "numeric",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
        timeZoneName: "short"
    }

    connect() {
        this.element.title = new Date(this.tsValue * 1000).toLocaleString(undefined, HoverDateTimeController.DATETIME_FORMAT);
    }
}