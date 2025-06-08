import {Controller} from "@hotwired/stimulus";

export abstract class WebauthnControllerBase extends Controller {
    static targets = ["challenge", "response"];

    declare readonly challengeTarget: HTMLInputElement;
    declare readonly responseTarget: HTMLInputElement;
}