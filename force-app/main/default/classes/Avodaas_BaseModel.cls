/**
 *  BaseModel
 *    @description Base class for object-specific code, including trigger handling, static methods and variables, etc.
 *    @testclass  BaseModel_Test.cls
 *      @examples   In Trigger:  new ContactModel().onTrigger();
 *      @author     Avodaas
 *      @date       Sept 2017
 **/
global abstract with sharing class Avodaas_BaseModel {

    // ========== Trigger Variables ========== //
    // ======================================= //

    private static Map<SObjectType, Avodaas_BaseModel> runningTriggers = new Map<SObjectType, Avodaas_BaseModel>();
    private static Map<SObjectType, Avodaas_BaseModel> ranTriggers = new Map<SObjectType, Avodaas_BaseModel>();
    protected Boolean isRecursive = false;
    protected Boolean isOnBeforeEvent = false;
    protected Boolean isValidating = false;
    protected Boolean isOnAfterEvent = false;
    protected Boolean isValidatingDelete = false;


    // ========== Trigger Methods ========== //
    // ===================================== //

    /**
     * @description Master trigger method.
     */
    global virtual void onTrigger() {
        SObjectType triggerObjectType = triggerRecords[0].getSObjectType();

        try {
            //Register trigger
            if (runningTriggers.containsKey(triggerObjectType) || ranTriggers.containsKey(triggerObjectType))
                this.isRecursive = true;
            runningTriggers.put(triggerObjectType, this);

            // Dispatch to correct method
            if (Trigger.isInsert || Trigger.isUndelete || Trigger.isUpdate) {
                if (Trigger.isBefore)
                    this.onBeforeInsertUpdate();
                else if (Trigger.isAfter)
                    this.onAfterInsertUpdate();
            } else if (Trigger.isDelete) {
                if (Trigger.isBefore)
                    this.onBeforeDelete();
                else if (Trigger.isAfter)
                    onAfterDelete();
            }
        } finally {
            // Un-register trigger
            runningTriggers.remove(triggerObjectType);
            ranTriggers.put(triggerObjectType, this);

        }
    }

    /**
    *   @description onBeforeInsertUpdate: Only override if necessary. Otherwise override called methods.
    */
    global virtual void onBeforeInsertUpdate() {
        try {
            this.isOnBeforeEvent = true;
            this.processBeforeEventsExtension();
            this.processBeforeEvents();
            this.isOnBeforeEvent = false;

            this.isValidating = true;
            this.validate();
            this.isValidating = false;
        } finally {
            this.isOnBeforeEvent = false;
            this.isValidating = false;
        }
    }

    /**
    *   @description onBeforeDelete: Only override if necessary. Otherwise override called methods.
    */
    global virtual void onBeforeDelete() {
        try {
            this.isValidatingDelete = true;
            this.validateDelete();
            this.isValidatingDelete = false;
        } finally {
            this.isValidatingDelete = true;
        }
    }

    /**
    *   @description onAfterInsertUpdate: Only override if necessary. Otherwise override called methods.
    */
    global virtual void onAfterInsertUpdate() {
        try {
            this.isOnAfterEvent = true;
            this.processAfterEvents();
            this.processAfterEventsExtension();
            this.isOnAfterEvent = false;
        } finally {
            this.isOnAfterEvent = false;
        }
    }

    /**
    *   @description onAfterDelete: Only override if necessary. Otherwise override called methods.
    */
    global virtual void onAfterDelete() {
        try {
            this.isOnAfterEvent = true;
            this.processAfterEvents();
            this.processAfterEventsExtension();
            this.isOnAfterEvent = false;
        } finally {
            this.isOnAfterEvent = false;
        }
    }

    /**
     * @description Override in object model class to validate trigger records.
     */
    global virtual void validate() {}

    /**
     * @description Override in class extension to add additional functionality.
     */
    global virtual void processBeforeEventsExtension() {}

    /**
     * @description Override in object model class to calculate values on before events on trigger records.
     */
    global virtual void processBeforeEvents() {}

    /**
     * @description Override in object model class to update related records on after events to trigger records.
     */
    global virtual void processAfterEvents() {}

    /**
     * @description Override in class extension to add additional functionality.
     */
    global virtual void processAfterEventsExtension() {}

    /**
     * @description Override in object model class to validate that record is deletable.
     */
    global virtual void validateDelete() {}


    // ========== Trigger Helpers ========== //
    // ===================================== //

    /**
     * Returns the set of trigger records
     */
    protected List<SObject> triggerRecords {
        get { return Trigger.isDelete ? Trigger.old : Trigger.new; }
    }

    /**
     * Returns the set of trigger record Ids
     */
    protected Set<Id> triggerRecordIds {
        get { return Trigger.isDelete ? Trigger.oldMap.keySet() : Trigger.newMap != null ? Trigger.newMap.keySet() : new Set<Id>(); }
    }

    /**
    *   @description Checks to see whether the field for this trigger record has changed.
    */
    protected Boolean isFieldChanged(SObject triggerRecord, SObjectField testField) {
        Boolean result = false;

        if (Trigger.isInsert || Trigger.isDelete || Trigger.isUndelete)
            result = true;
        else if (Trigger.isUpdate)
            result = triggerRecord.get(testField) != Trigger.oldMap.get(triggerRecord.Id).get(testField);

        return result;
    }

    /**
     * @description Checks whether the specified field has just transitioned to a specified value.
     */
    protected Boolean isFieldChangedTo(SObject triggerRecord, SObjectField testField, Object toValue) {
        Boolean result = false;

        if (Trigger.isInsert || Trigger.isUndelete)
            result = triggerRecord.get(testField) == toValue;
        else if (Trigger.isDelete)
            result = toValue == null;
        else if (Trigger.isUpdate)
            result = triggerRecord.get(testField) == toValue && Trigger.oldMap.get(triggerRecord.Id).get(testField) != toValue;

        return result;
    }

	/**
	* @description Checks whether the specified field has just transitioned to a specified value from a list.
	*/
	protected Boolean isFieldChangedToOneOf(SObject triggerRecord, SObjectField testField, List<Object> toValues) {
		if(toValues == null) return isFieldChangedTo(triggerRecord, testField, null);
		for(Object toValue : toValues){
			if (isFieldChangedTo(triggerRecord, testField, toValue)) return true;
		} return false;
	}

    /**
     * @description Checks whether the specified field has just transitioned from a specified value.
     */
    protected Boolean isFieldChangedFrom(SObject triggerRecord, SObjectField testField, Object fromValue) {
        if (Trigger.isInsert || Trigger.isUndelete)
            return fromValue == null && triggerRecord.get(testField) != null;
        else if (Trigger.isDelete)
            return triggerRecord.get(testField) == fromValue;
        else
            return Trigger.oldMap.get(triggerRecord.Id).get(testField) == fromValue && triggerRecord.get(testField) != fromValue;
    }

    /**
     * @description Returns the list of trigger records whose given field has changed.
     */
    protected List<SObject> getChangedRecords(SObjectField testField) {
        List<SObject> result = new List<SObject>();
        for (SObject triggerRecord : this.triggerRecords)
            if (isFieldChanged(triggerRecord, testField))
                result.add(triggerRecord);

        return result;
    }

    /**
     * @description Returns the list of trigger records whose given field has changed to the given value
     */
    /*protected List<SObject> getChangedRecordsTo(SObjectField testField, Object toValue) {
        List<SObject> result = new List<SObject>();
        for (SObject triggerRecord : this.triggerRecords)
            if (isFieldChangedTo(triggerRecord, testField, toValue))
                result.add(triggerRecord);

        return result;
    }*/

    /**
     * @description Returns the list of trigger records whose given field have the specified value.
     */
    protected List<SObject> getRecordsWithFieldValue(SObjectField field, Object value) {
        List<SObject> result = new List<SObject>();
        for (SObject triggerRecord : this.triggerRecords)
            if (triggerRecord.get(field) == value)
                result.add(triggerRecord);

        return result;
    }

    /**
     * @description Returns the list of trigger records whose given fields have the same value.
     */
    protected List<SObject> getRecordsWithSameValue(SObjectField field1, SObjectField field2) {
        List<SObject> result = new List<SObject>();
        for (SObject triggerRecord : this.triggerRecords)
            if (triggerRecord.get(field1) == triggerRecord.get(field2))
                result.add(triggerRecord);

        return result;
    }

    /**
     * @description Returns the old version of the new record.
     */
    protected SObject getOldRecord(SObject newRecord) {
        return Trigger.isInsert ? null : trigger.oldMap.get(newRecord.Id);
    }

    /**
     * @description Gets the old value of a field from the record.
     */
    protected Object getOldValue(SObject triggerRecord, SObjectField field) {
        if (Trigger.isInsert)
            return null;

        return Trigger.oldMap.get(triggerRecord.Id).get(field);
    }

}
