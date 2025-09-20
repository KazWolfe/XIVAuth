import {Controller} from "@hotwired/stimulus";

import TomSelect from "tom-select";
import {TomOption} from "tom-select/dist/types/types";
import {escape_html} from "tom-select/src/utils";

export default class CharacterSelectDropdown extends Controller<HTMLSelectElement> {
    tomSelect?: TomSelect = undefined;

    connect() {
        this.tomSelect = new TomSelect(this.element, {
            render: {
                option: CharacterSelectDropdown.render_option,
                item: CharacterSelectDropdown.render_item
            },
            searchField: ["characterName"]
        });

        console.log("It's Tom Select! Get the camera!", this.tomSelect);
    }

    static render_option(data: TomOption, escape: typeof escape_html): string {
        return "<div class='d-flex flex-row align-items-center'>" +
            `<img src="${data.characterAvatar}" class="me-2 rounded" style="width: 48px; height: 48px;">` +
            `<div class='ps-2'>` +
            `<span>${escape(data.characterName)}</span><br/>` +
            `<span class='small'>${escape(data.characterWorld)} [${escape(data.characterDatacenter)}]</span>` +
            "</div>" +
            "</div>";
    }

    static render_item(data: TomOption, escape: typeof escape_html): string {
        return "<div class='d-flex flex-row align-items-center'>" +
            `<img src="${data.characterAvatar}" class="me-2 rounded" style="width: 48px; height: 48px;">` +
            `<div class='ps-2'>` +
            `<span>${escape(data.characterName)}</span><br/>` +
            `<span class='small'>${escape(data.characterWorld)} [${escape(data.characterDatacenter)}]</span>` +
            "</div>" +
            "</div>";
    }
}