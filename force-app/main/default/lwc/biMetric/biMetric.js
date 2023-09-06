import { LightningElement, track, wire } from 'lwc';
import getFilteredBiMdtRecords from '@salesforce/apex/BiMetricController.getFilteredBiMdtRecords';
import getObjectNames from '@salesforce/apex/BiMetricController.getObjectNames';
import getFieldsByObjectName from '@salesforce/apex/BiMetricController.getFieldsByObjectName';
import createBiMetric from '@salesforce/apex/BiMetricController.createBiMetric';
import editBiMetric from '@salesforce/apex/BiMetricController.editBiMetric';
import mdtActivation from '@salesforce/apex/BiMetricController.mdtActivation';

const actions = [
	{ label: 'Clone a BI Metric', name: 'create' },
	{ label: 'Edit', name: 'edit' },
	{ label: 'Activate', name: 'activate' },
	{ label: 'Deactivate', name: 'deactivate' }
];

const columns = [
	{ label: 'Master Label', fieldName: 'MasterLabel', type: 'text', sortable: true },
	{ label: 'Object', fieldName: 'Object_Name__c', type: 'text', sortable: true },
	{ label: 'Field', fieldName: 'Field_Name__c', type: 'text', sortable: true },
	{ label: 'Active', fieldName: 'Active__c', type: 'boolean', sortable: true },
	{ type: 'action', typeAttributes: { rowActions: actions } }
];

const noticeMsgSuccess = 'It may take upwards of a few minutes to finalize the updates';
const noticeMsgError = 'NOTE: An error has occured, with the following error message: ';

export default class BiMetric extends LightningElement {

	records = [];
	columns = columns;
	showMdtUpdatingNotice = false;
	noticeMsg = '';
	error;

	sortDirection = 'Asc';
	sortBy = 'MasterLabel';
	sortChanged = false;

	searchKey = '';
	placeholder = 'Search';

	//bi metric mdt fields
	biId = '';
	objectName = '';
	masterLabel = '';
	fieldName = '';
	isActive = '';
	
	spinner = false;
	openCreateMetricModal = false;
	loadingStatus = '';
	
	queryOffset;
	queryLimit;
	totalRecordCount;

	objectsOptions = [];
	fieldOptions = [];
	fieldNameChosen = false;
	disableSave = true;

	connectedCallback() {
		this.queryOffset = 0;
		this.queryLimit = 20;
		this.loadRecords();
	}
	
	//get list of object options from custom mdt
	@wire(getObjectNames) 
	wiredPicklistValues({data, error}) {
		if(data) { 
			data.forEach(o => {this.objectsOptions.push({ label: o.DeveloperName, value: o.QualifiedApiName })});
		}
		else if(error) console.log('error getting Object Names' + error);
	}
	
	loadMoreData(event) {
		const { target } = event;
		//Display a spinner to signal that data is being loaded
		target.isLoading = true;
		if(!this.searchKey && this.totalRecordCount >= this.queryOffset + this.queryLimit) {
			this.queryOffset = this.queryOffset + this.queryLimit;
			this.loadRecords()
				.then(()=> {
					target.isLoading = false;
				});
		} else {
			target.isLoading = false;
			target.enableInfiniteLoading = false;
			this.loadingStatus = 'No more records to load';
		}
	}

	/*
	** Infinite Scrolling taken from: https://salesforcespace.blogspot.com/2020/02/lwc-audit-log-viewer-using-infinite.html
	*/

	loadRecords() {
		this.spinner = true;
		let queryOffset = this.queryOffset, queryLimit = this.queryLimit;
		if(this.sortChanged) {
			queryLimit = this.queryOffset + this.queryLimit;
			queryOffset = 0;
		}
		if(this.searchKey) {
			queryLimit = this.totalRecordCount;
		}
		return getFilteredBiMdtRecords({ queryLimit: queryLimit, queryOffset: queryOffset, sortBy: this.sortBy, sortDirection: this.sortDirection, searchKey: this.searchKey })
		.then(result => { 
			this.spinner = false;
			this.totalRecordCount = result.totalRecordCount;
			const flatData = JSON.parse(JSON.stringify(result.biRecords));
			if(!this.sortChanged) this.records = [...this.records, ...flatData];
			else this.records = flatData;
			this.records = this.removeDuplicates(this.records);
			this.error = undefined;
			let target = this.template.querySelector('[data-id="datatable"]');
			target.enableInfiniteLoading = true;
		})
		.catch(error => { 
			this.error = error;
			console.log('err ' + error + ' ' + JSON.stringify(error));
		})
		.finally(f => {
			this.sortChanged = false;
		})
	}

	//get records() {
	//	return this.records.length ? this.records : null;
	//}

	removeDuplicates(data){
		return data.filter((v,i,a)=>a.findIndex(t=>(t.MasterLabel === v.MasterLabel))===i);
	}

	handleSortdata(event) {
		this.sortBy = event.detail.fieldName;
		this.sortDirection = event.detail.sortDirection;
		this.records = [];
		this.loadingStatus = '';
		this.sortChanged = true;
		this.loadRecords();
	}

	handleSearchChange(event) {
		this.searchKey = event.target.value;
		this.queryOffset = 0;
		this.records = [];
		if(this.searchKey == '') this.resetFields();
		this.loadRecords();
	}

	refreshTable() {
		this.resetFields();
		this.loadRecords();
	}
		
	handleRowAction(event) {
		this.executeMdtAction(event.detail.action.name, event.detail.row);
	}

	handleCancel(event) {
		this.openCreateMetricModal = false;
		this.setSaveVisibility();
		event.preventDefault();
	}

	handleMasterNameChange(event) {
		this.masterLabel = event.detail.value;
		this.disableSave = (this.fieldNameChosen && this.masterLabel) ? false : true;
	}

	handleObjectNameChange(event) {
		this.objectName = event.detail.value;
		this.fieldName = '';
		this.setSaveVisibility();
		this.getPicklistFields();
	}

	getPicklistFields() {
		if(!this.objectName) return;
		getFieldsByObjectName({objectName: this.objectName})
		.then(result => { 
			this.fieldOptions = [];
			result.forEach(f => { this.fieldOptions.push({ label: f, value: f })});
		})
		.catch(error => { 
			this.error = error;
			console.log('err ' + error + JSON.stringify(error));
		})
	}

	handleFieldNameChange(event) {
		this.fieldName = event.detail.value;
		this.fieldNameChosen = true;
		this.disableSave = this.masterLabel ? false : true;
	}

	setSaveVisibility() {
		this.fieldNameChosen = false;
		this.disableSave = true;
	}

	handleIsActiveChange(event) {
		this.isActive = event.detail.checked;
	}

	openMetricModel(row, isInsert) {
		this.masterLabel = row.MasterLabel;
		this.objectName = row.Object_Name__c;
		this.fieldName = row.Field_Name__c;
		this.isActive = row.Active__c;
		this.isInsert = isInsert;
		if(!isInsert) this.biId = row.Id;
		this.openCreateMetricModal = true;
		this.getPicklistFields();
	}

	executeMdtAction(actionName, row) {
		this.spinner = (actionName !== 'new' && actionName !== 'create' && actionName !== 'edit');
		switch (actionName) {
			case 'new':
				this.openMetricModel(row, true);
				break;
			case 'create':
				this.fieldNameChosen = true;
				this.disableSave = false;
				this.openMetricModel(row, true);
				break;
			case 'edit':
				this.fieldNameChosen = true;
				this.disableSave = false;
				this.openMetricModel(row, false);
				break;
			case 'activate':
				mdtActivation({ mdtId: row.Id, isActive: true })
					.then(result => {
						this.showSuccessNoticeMsg();
					}) .catch(error => {
						this.error = error;
						this.showErrorNoticeMsg(error);
					});
					this.turnOffSpinner();
				break;
			case 'deactivate':
				mdtActivation({ mdtId: row.Id, isActive: false })
					.then(result => {
						this.showSuccessNoticeMsg();
					}) .catch(error => {
						this.error = error;
						this.showErrorNoticeMsg(error);
					});
					this.turnOffSpinner();
				break;
			default:
		}
	}

	addMetricField() {
		var row = {};
		this.executeMdtAction('new', row);
	}

	validate() {
		if(this.masterLabel && this.objectName && this.fieldName) return true;
		return false;
	}

	handleAddMetric(event) {
		event.preventDefault();
		this.spinner = true;
		createBiMetric({ masterLabel: this.masterLabel, objectName: this.objectName, fieldName: this.fieldName, isActive: this.isActive })
		.then(result => {
			this.showSuccessNoticeMsg();
		}).catch(error => {
			this.error = error;
			this.showErrorNoticeMsg(error);
		}).finally(() => {
			this.openCreateMetricModal = false;
			this.turnOffSpinner();
		});
	}

	handleEditMetric(event) {
		event.preventDefault();
		this.spinner = true;
		editBiMetric({ biId: this.biId, masterLabel: this.masterLabel, objectName: this.objectName, fieldName: this.fieldName, isActive: this.isActive })
		.then(result => {
			this.showSuccessNoticeMsg();
		}).catch(error => {
			this.error = error;
			this.showErrorNoticeMsg(error);
		}).finally(() => {
			this.openCreateMetricModal = false;
			this.turnOffSpinner();
		});
	}

	turnOffSpinner() {
		setTimeout(() => {
			this.spinner = false;
			this.resetFields();
			this.loadRecords();
		}, 2500);
	}

	showSuccessNoticeMsg() {
		this.noticeMsg = noticeMsgSuccess;
		this.showMdtUpdatingNotice = true;
	}

	showErrorNoticeMsg(errorMsg) {
		this.noticeMsg = noticeMsgError + JSON.stringify(errorMsg);
		this.showMdtUpdatingNotice = true;
	}

	resetFields() {
		this.biId = '';
		this.objectName = '';
		this.masterLabel = '';
		this.fieldName = '';
		this.isActive = '';
		this.isInsert = '';
		this.queryOffset = 0;
		this.queryLimit = 20;
		this.totalRecordCount = null;
		this.records = [];
		this.loadingStatus = '';
		this.sortDirection = 'Asc';
		this.sortBy = 'MasterLabel';
		this.sortChanged = false;
		this.searchKey = '';
		this.setSaveVisibility();
	}
}