/**
 *	BIMetricModel
 *  	@description Base class for BIMetricModel object code, including static methods and variables
 *		@testclass	BIMetricModel_Test
 *		@author Avodaas
 *		@date   Jan 2021
 **/
public with sharing class BIMetricModel extends Avodaas_BaseModel{
    // ========== Static Object Variables ========== //
    // ============================================= //
    public static final String CLASS_NAME = BIMetricModel.class.getName();

    //Do we want to run the tracking code in as async? Defaulting to false
    //TODO: store in custom metadata
    public static Boolean USE_ASYNCHRONOUS = false;
    public static Map<Id, Map<String, Id>> allBIMetricsForRecords;
    public static Map<String, String> fieldMap;
    public static Map<String, Schema.SObjectField> objectFields;

    public class BIUpdateWrapper {
        public Id sourceRecordId{get;set;}
        public String lifecycleField{get;set;}
        public Id userOwnerId{get;set;}
        public Id queueOwnerId{get;set;}
        public Object newValue{get;set;}
        public String ownerName{get;set;}
        public String ownerAlias{get;set;}
        public String ownerRole{get;set;}
        public String newValueString{get;set;}
        public String dataType{get;set;}
        public Datetime newDatetime{get;set;}
        public Decimal newDecimal{get;set;}
    
        public BIUpdateWrapper(Id srId, String field, Id owner, Object newVal, String dataTypeIn) {
            sourceRecordId = srId;
            lifecycleField = field;
            newValue = newVal;
            dataType = dataTypeIn;
            setValueByType();
            setOwnerIdByType(owner);
        }

        private void setOwnerIdByType(Id ownerId){
            String ownerType = Avodaas_Apx.getObjectNameById(ownerId);
            if(ownerType == 'Group') queueOwnerId  = ownerId;
            else userOwnerId = ownerId;
        }

        public void setValueByType(){
            String stringVal;
            try{
                switch on dataType {
                    //using string for phone, not significant enough.
                    when 'REFERENCE', 'PICKLIST', 'STRING', 'PHONE', 'EMAIL', 'URL', 'MULTIPICKLIST', 'TEXTAREA'{
                        stringVal = String.valueOf(newValue);
                    }
                    when 'DATE'{
                        Date myDate = (Date)newValue;
                        stringVal = myDate.format();
                        Time myTime = Time.newInstance(0, 0, 0, 0);
                        newDatetime = Datetime.newInstance(myDate, myTime);
                    }
                    when 'DATETIME'{
                        Datetime myDateTime = (Datetime)newValue;
                        stringVal = myDateTime.format();
                        newDateTime = myDateTime;
                    }
                    when 'INTEGER', 'DECIMAL', 'CURRENCY','DOUBLE'{
                        newDecimal = (Decimal)newValue;
                        stringVal = String.valueOf(newDecimal);
                        
                    }
                    when else{
                        Avodaas_Apx.sendAdminEmail('Did not find field type', 'the field type was: ' + dataType + ' and the val: ' + newValue);
                    }
                }
                newValueString = stringVal;
            }
            catch(Exception e){
                Avodaas_Apx.sendAdminEmail('Error converting value to string.', ' Field: ' + lifecycleField + ' new value:' + newValue + '. Error:' + e.getStackTraceString());
                Avodaas_Apx.createErrorLog(e, CLASS_NAME);
            }
        }

        public String getIdAsString(){
            return String.valueOf(sourceRecordId);
        }

        public BI_Metric__c createMetric(){
            String objectName = Avodaas_Apx.getObjectNameById(sourceRecordId);
            //get the sobject field name on the object to set record id on
            String objectFieldAPIName = getFieldAPINameForTrackedObject(objectName);
            //if the sobject is not supported, don't create a metric!
            if(String.isBlank(objectFieldAPIName)) return null;

            Id metricId = getRecordLastMetricForFieldId(sourceRecordId, lifecycleField);
            BI_Metric__c newMetric = new BI_Metric__c(
                Lifecycle_Field__c = lifecycleField, 
                New_Value__c = newValueString,
                New_Datetime__c = newDatetime,
                New_Number__c = newDecimal,
                Previous_Record__c = metricId,
                Owner_Id__c = userOwnerId,
                Owner_Queue_Id__c = queueOwnerId,
                Owner_Name__c = OwnerName,
                Owner_Alias__c = OwnerAlias,
                Owner_Role__c = OwnerRole,
                Updating_User__c = UserInfo.getUserId(), 
                Record_Id__c = getIdAsString());
            //set the record id
            newMetric.put(objectFieldAPIName, sourceRecordId);
            return newMetric;
        }
    }

    public class BIFieldWrapper{
        public Schema.SObjectField objField{get;set;} 
        public String fieldName{get;set;}
        public String fieldType{get;set;}
       
        public BIFieldWrapper(BI_Metric_Fields__mdt biFieldRecord){
            fieldName = biFieldRecord.Field_Name__c;
            if(!objectFields.containsKey(fieldName)) return;
            objField = objectFields.get(fieldName);
            String dataType = biFieldRecord.Data_Type__c;
            //the data type is set here, once for the lifetime of the record
            if(String.isEmpty(dataType)){
                checkAndSetType();
                if(String.isEmpty(fieldType)) return;
                MdtUtil.updateMdtRecord((SObject)biFieldRecord, 'Data_Type__c', fieldType);
            }
            else fieldType = dataType;
        }

        public void checkAndSetType(){
            if(String.isBlank(fieldType)) fieldType = Avodaas_Apx.getFieldType(objField);
        }
        
        public Boolean isValid(){
            return (String.isNotEmpty(fieldName) && String.isNotEmpty(fieldType) && objField != null);
        }

    }

    // ========== Trigger Handler ========== //
    // ===================================== //

    /**
     * @description Populate records with the appropriate values on all Trigger.isBefore events
     **
    public override void processBeforeEvents() {
        if (Trigger.isInsert || Trigger.isUpdate) {}
    } */

    /**
    * @description Update related records on all Trigger.isAfter events
    **/
    public override void processAfterEvents() {
        if (Trigger.isInsert){
            closePreviousRecords();
        }
        if(Trigger.isUpdate){}
    }
    

     // ========== Trigger Helpers ========== //
    // ===================================== //

    /**
     * @description If a record was inserted with a Previous Metric Id, set the closed
     *              date for the previous record 
     */
    private void closePreviousRecords(){
        List<BI_Metric__c> previousRecords = new List<BI_Metric__c>();
        //get a list of all records that were 'closed'
        for(BI_Metric__c biMetric: (List<BI_Metric__c>)triggerRecords){
            if(biMetric.Previous_Record__c != null) previousRecords.add(new BI_Metric__c(Id = biMetric.Previous_Record__c, Completed_Date__c = System.today()));
        }

        if(previousRecords.isEmpty()) return;
        update previousRecords;
    }

     /**
     * @description Get a list of record ids for a list of wrappers
     * @param List of BIUpdateWrappers
     * @return List of source record ids
     */
    public static List<Id> getSourceRecordIds(List<BIUpdateWrapper> wrappers){
        if(wrappers.isEmpty()) return null;

        List<Id> sourceRecordIds = new List<Id>();
        for(BIUpdateWrapper wrapper: wrappers) sourceRecordIds.add(wrapper.sourceRecordId);
        return sourceRecordIds;
    }

    /**
     * @description Get a list of fields for a list of wrappers
     * @param List of BIUpdateWrappers
     * @return List of updated fields
     */
    public static List<String> getLifecycleFields(List<BIUpdateWrapper> wrappers){
        if(wrappers.isEmpty()) return null;
        List<String> lifecycleFields = new List<String>();
        for(BIUpdateWrapper wrapper: wrappers) lifecycleFields.add(wrapper.lifecycleField);
        return lifecycleFields;
    }

    
    // ========== Helpers ========== //
    // ===================================== //

    /***
     * @description Get list of fields to track for Object
     * @param Object name
     * @return List of field api names to track
     */
    public static List<BIFieldWrapper> getFieldsToTrackForSObject(String sObjectName){
        sObjectName = String.escapeSingleQuotes(sObjectName);
        //if the following returns null, the sobject doesn't exist
        objectFields = Avodaas_Apx.getSObjectFields(sObjectName);
        if(objectFields == null) return null;
        List<BI_Metric_Fields__mdt> fieldListData = [SELECT Field_Name__c, Data_Type__c, MasterLabel, QualifiedApiName, Active__c
                FROM BI_Metric_Fields__mdt 
                WHERE Object_Name__c = :sObjectName AND Active__c = true];
        //not tracking anything for this object
        if(fieldListData.isEmpty()) return null;
        List<BIFieldWrapper> theFields = new List<BIFieldWrapper>();
        String fieldAPIName;
        BIFieldWrapper tmpWrapper;
        for(BI_Metric_Fields__mdt fieldInfo: fieldListData){
            tmpWrapper = new BIFieldWrapper(fieldInfo);
            if(tmpWrapper.isValid()) theFields.add(tmpWrapper);
        }
        return theFields;
    }

    /***
     * @description Sort metric fields and returns the most recent one
     * @params BIMetricSortable list of wrapped BI Metric records
     * @return One BI Metric Object
     */
    public static Id getMostRecentBIMetric(List<BIMetricSortable> metrics){
        if(metrics.isEmpty()) return null;
        metrics.sort();
        return metrics.get(0).metric.Id;
    }

    /** 
     * @description Set owner name, alias and role for each wrapper
     * @param List of BIUpdateWrapper
     * @return List of BIUpdateWrapper
    */
    public static List<BIUpdateWrapper> setOwnerInformation(List<BIUpdateWrapper> wrappers){
        List<Id> ownerIds = new List<Id>();
        List<Id> queueIds = new List<Id>();
        for(BIUpdateWrapper wrapper: wrappers){
            if(wrapper.userOwnerId != null) ownerIds.add(wrapper.userOwnerId);
            else if(wrapper.queueOwnerId != null) queueIds.add(wrapper.queueOwnerId);
        }
        Map<Id, User> users = new Map<Id, User>();
        Map<Id, Group> queues = new Map<Id, Group>();

        if(!ownerIds.isEmpty()){
            users = new Map<Id, User>([SELECT Id, Alias, Name, UserRole.Name FROM User WHERE Id IN :ownerIds]);
        }
        if(!queueIds.isEmpty()){
            queues = new Map<Id, Group>([SELECT Id, DeveloperName, Name FROM Group WHERE Id IN :queueIds AND Type = 'Queue']);
        }
        User tmpUser;
        Group tmpQueue;
        for(BIUpdateWrapper wrapper: wrappers){
            if(users.containsKey(wrapper.userOwnerId)){
                tmpUser = users.get(wrapper.userOwnerId);
                wrapper.ownerName = tmpUser.Name;
                wrapper.ownerAlias = tmpUser.Alias;
                wrapper.ownerRole = tmpUser.UserRole?.Name;
            }
            else if(queues.containsKey(wrapper.queueOwnerId)){
                tmpQueue = queues.get(wrapper.queueOwnerId);
                wrapper.ownerName = tmpQueue.Name;
            }
        }
        return wrappers;
    }   

    /***
     * @description Build Map of records, fields and most recent bi metric
     * @params Id RecordId, String Field, List of Sortable BI Metrics
     * @return None, using static member
     */
    public static void setMetricIdForObjectField(Id sourceRecordId, String lifecycleField, List<BIMetricSortable> sortableMetrics){
        Map<String, Id> tmpMap;
        Id tmpMetricId;
        tmpMetricId = getMostRecentBIMetric(sortableMetrics);
        if(!allBIMetricsForRecords.containsKey(sourceRecordId)) tmpMap = new Map<String, Id>();
        else tmpMap = allBIMetricsForRecords.get(sourceRecordId);
        tmpMap.put(lifecycleField, tmpMetricId);
        allBIMetricsForRecords.put(sourceRecordId, tmpMap);
    }

    /**
     * @description Query all existing BI Metric Fields for Updated Records and relevant fields
     * @params List<Id> of current records
     * @return none - sets static member
     */
    public static void setBIRecords(List<Id> sourceRecordIds, List<String> fields){
        List<BI_Metric__c> biRecords = [SELECT Id, Record_Id__c, Lifecycle_Field__c, CreatedDate 
                FROM BI_Metric__c 
                WHERE Record_Id__c IN :sourceRecordIds and Lifecycle_Field__c IN :fields
                ORDER BY Record_Id__c, Lifecycle_Field__c, CreatedDate];
        List<BIMetricSortable> sortableMetrics = new List<BIMetricSortable>();
        allBIMetricsForRecords = new Map<Id, Map<String, Id>>();
        Id currentRecordId;
        String currentField;
        for(BI_Metric__c biObj: biRecords){
            if(String.isEmpty(currentField) && currentRecordId == null){
                currentField = biObj.Lifecycle_Field__c;
                currentRecordId = biObj.Record_Id__c;
            } else if(currentField != biObj.Lifecycle_Field__c){
                setMetricIdForObjectField(currentRecordId, currentField, sortableMetrics);
                currentField = biObj.Lifecycle_Field__c;
                sortableMetrics.clear();
            } else if(currentRecordId != biObj.Record_Id__c){
                setMetricIdForObjectField(currentRecordId, currentField, sortableMetrics);
                currentRecordId = biObj.Record_Id__c;
                sortableMetrics.clear();
            }
            sortableMetrics.add(new BIMetricSortable(biObj));
        }
        if(!sortableMetrics.isEmpty()) setMetricIdForObjectField(currentRecordId, currentField, sortableMetrics);
    }

    /***
     * @description Get Most Recent Metric Record for Record & Lifecyle Field. Used when inserting records via batch.
     * @param RecordId, LifecycleField
     * @return BI_Metric__c.Id
     */
    public static Id getRecordLastMetricForFieldId(Id recordId, String lifecycleField){
        if(allBIMetricsForRecords == null || !allBIMetricsForRecords.containsKey(recordId)) return null;
        Map<String, Id> thisMap = allBIMetricsForRecords.get(recordId);
        if(!thisMap.containsKey(lifecycleField)) return null;
        return thisMap.get(lifecycleField);
    }

    /****
     * @description Get Previous BI Record so we have a Linked List per record. Used when inserting single bi metric records.
     * @params objectName, sourceRecordId, fieldName
     * @return record Id for the previous BI Metric record for this record & field
     */
    public static Id getMostRecentBIRecord(Id sourceRecordId, String fieldName){
        fieldName = String.escapeSingleQuotes(fieldName);
        return [SELECT Id FROM BI_Metric__c WHERE Record_Id__c = :sourceRecordId AND Lifecycle_Field__c = :fieldName ORDER BY CreatedDate DESC LIMIT 1]?.Id;
    }


    /****
     * @description Get Field API Name for Object. Critical **MUST** keep field naming convention
     *      ie If we track a new object, we need to create a new field on the BIMetric object
     *          which uses the exact spelling of the object API name.
     *      eg Track Product -> add field called Product2__c
     * @param ObjectName
     * @return Field API Name
     */
    public static String getFieldAPINameForTrackedObject(String objectName){
        //this is an expensive method, only call once
        if(fieldMap == null) fieldMap = Avodaas_Apx.getSObjectFieldNames('BI_Metric__c');
        String fieldName = (objectName.endsWith('__c')) ? objectName : objectName + '__c'; 
        return fieldMap.containsKey(fieldName) ? fieldName : null;
    }
    
    /***
     * @description Create BI Metric record for single field update
     * @params FieldName, NewValue, RecordId, OwnerId
     * @return void
     */
    @future
    public static void createBIMetric(String fieldName, String newValue, Id sourceRecordId, Id ownerId){
        //decide which type of sobject this record is
        String objectName = Avodaas_Apx.getObjectNameById(sourceRecordId);
        //get the sobject field name on the object to set record id on
        String objectFieldAPIName = getFieldAPINameForTrackedObject(objectName);
        //if the sobject is not supported, don't create a metric!
        if(objectFieldAPIName == null) return;
        //get the previous bi metric record for this record & field
        //if there is none, this will be null and the lookup will be empty
        Id previousMetricId = getMostRecentBIRecord(sourceRecordId, fieldName);
        User recordOwner = [SELECT Id, Name, Alias, UserRole.Name FROM User WHERE Id = :ownerId];
        //create the new metric record
        BI_Metric__c biMetric = new BI_Metric__c(Lifecycle_Field__c = fieldName, New_Value__c = newValue, Previous_Record__c = previousMetricId,
                Owner_Id__c = ownerId, Updating_User__c = UserInfo.getUserId(), Record_Id__c = String.valueOf(sourceRecordId), Owner_Name__c = recordOwner.Name,
                Owner_Alias__c = recordOwner.Alias, Owner_Role__c = recordOwner.UserRole.Name);

        //set the record id
        biMetric.put(objectFieldAPIName, sourceRecordId);
        insert biMetric;
    }

    /***
     * @description Create BI Metric records for field updates (batch)
     * @params Map<Id, String> Source Record Ids => FieldName, Map<Id, String> Source Record Ids => NewValues, 
     *         Map<Id, String> Source Record Ids => OwnerIds
     * @return void
     */
    public static void createBIMetrics(List<BIUpdateWrapper> wrappers){
        //if this is running in normal context and the asynchronous flag is set, run it as a queueable
        if(USE_ASYNCHRONOUS && !System.isQueueable() && !System.isBatch() && !System.isFuture()) {
            System.enqueueJob(new QueueableBIMetric(wrappers));
            return;
        }
        //set owner info
        wrappers = setOwnerInformation(wrappers);
        //retrieve and set all existing metrics for current records
        setBIRecords(getSourceRecordIds(wrappers), getLifecycleFields(wrappers));
        //set up a list of metrics to insert
        List<BI_Metric__c> newMetrics = new List<BI_Metric__c>();
        for(BIUpdateWrapper wrapper: wrappers){
            BI_Metric__c tmpMetric = wrapper.createMetric();
            if(tmpMetric != null) newMetrics.add(tmpMetric);
        }
        
        try{
            insert newMetrics;
        } catch(Exception e){
            String message =  'The metrics to insert: \r\n' + newMetrics + '\r\n and the error:' + e.getMessage() + '\r\nStack Trace: ' + e.getStackTraceString();
            Avodaas_Apx.sendAdminEmail('Error inserting bi metrics', message);
            System.debug(message);
            Avodaas_Apx.createErrorLog(e, CLASS_NAME);
        }
    }

}
