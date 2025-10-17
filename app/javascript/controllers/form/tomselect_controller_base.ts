import TomSelect from "tom-select";
import {Controller} from "@hotwired/stimulus";
import {RecursivePartial, TomSettings} from "tom-select/dist/types/types";

export default abstract class TomSelectController extends Controller<HTMLSelectElement> {
    protected tomSelect?: TomSelect = undefined;

    connect() {
        this.tomSelect = new TomSelect(this.element, this.user_settings);
        console.debug("Tom Select initialized", this.tomSelect);
    }

    get user_settings(): RecursivePartial<TomSettings> {
        return { };
    };
}