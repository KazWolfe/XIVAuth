import {RecursivePartial, TomOption, TomSettings} from "tom-select/dist/types/types";
import TomSelectController from "../form/tomselect_controller";
import {escape_html} from "tom-select/src/utils";

export default class IdentitySelectController extends TomSelectController {
    get user_settings(): RecursivePartial<TomSettings> {
        return {
            render: {
                item: this.renderItem,
                option: this.renderOption,
            },
            plugins: {
                'remove_button': {
                    title: 'Remove this item'
                },
                'checkbox_options': {
                    'checkedClassNames':   ['ts-checked'],
                    'uncheckedClassNames': ['ts-unchecked'],
                }
            },
            searchField: ["identityName", "identityProvider"]
        };
    }

    renderItem(data: TomOption, escape: typeof escape_html): string {
        return "<div>" +
            `<i class='fab fa-${data.identityProvider} me-1 fa-fw'></i> ${escape(data.identityName)}` +
            "</div>";
    }

    renderOption(data: TomOption, escape: typeof escape_html): string {
            return "<div>" +
                `<span><i class='fab fa-${data.identityProvider} me-1 fa-fw'></i> ${data.identityName}</span><br/>` +
                `<span class='very-small'>External ID: <span class='font-monospace'>${data.identityExtid}</span></span>` +
                "</div>";
    }
}