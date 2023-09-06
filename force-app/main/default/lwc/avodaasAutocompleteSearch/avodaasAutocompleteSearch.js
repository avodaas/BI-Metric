import { LightningElement, api, track} from 'lwc';

export default class AvodaasAutoCompleteSearch extends LightningElement {

	records;
	noRecordsFlag = false;
	showoptions = false;
	searchString = '';

	// API properties
	@api selectedsobject;
	@api recordlimit;
	@api searchLabel;
	@api searchField;
	@api objectjson = {};
	@api searchdisabled = false;
	@api options;
	@api filteredOptions;
	@api isRequired;
	@api selectedName;

	// handle event coming from lookup
	handlelookupselect(event) {
		this.selectedName = event.detail.value;
		this.showoptions = false;
	}

	// filter the options based on search string
	handleKeyChange(event) {
		this.searchString = event.target.value;
		this.records = [];
		this.records = this.options.filter(o => o['label'].toLowerCase().includes(this.searchString.toLowerCase()));
		this.showoptions = this.records.length === 0 ? false : true;
	}

	// every time input changes including clicking x
	inputChanged(event) {
		this.selectedName = event.detail.value;
		const changedEvent = new CustomEvent('inputchanged');
		this.dispatchEvent(changedEvent);  
	}
}