import {Controller} from "@hotwired/stimulus";

export abstract class WebauthnControllerBase extends Controller<HTMLFormElement> {
    static targets = ["challenge", "response"];

    declare readonly challengeTarget: HTMLInputElement;
    declare readonly responseTarget: HTMLInputElement;
}