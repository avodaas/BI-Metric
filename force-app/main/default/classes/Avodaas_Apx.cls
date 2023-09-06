/**
 *  Apx
 *  @description Utility class for common methods
 *  @testclass  Apx_Test.cls
 *  @author HGolov
 *  @date   Aug 2020
 */
global without sharing class Avodaas_Apx {
    //========== Static Variables =========//
    public static final String ADMIN_REPLYTO_EMAIL = 'saas-package-admin@avodaas.com';
    public static final String ADMIN_SENDER_DISPLAYNAME = 'The orgname';

    public static final String MANAGEMENT_EMAIL = 'admin@theorg.com';
    
    public static List<String> ADMIN_EMAILS{
        get{
            if(ADMIN_EMAILS == null){
                ADMIN_EMAILS = new List<String>{'saas-package-admin@avodaas.com'};
            }
            return ADMIN_EMAILS;
        }
        set;
    } 

    public final static Id MARKETING_QUEUE_ID{
        get{
            if(MARKETING_QUEUE_ID == null) MARKETING_QUEUE_ID = [SELECT Id FROM Group WHERE Name = 'Marketing Queue' LIMIT 1]?.Id;
            return MARKETING_QUEUE_ID;
        } private set;
    }
    
    public final static String ORG_URL{
        get{
            if(ORG_URL == null) ORG_URL = URL.getSalesforceBaseUrl().toExternalForm() + '/';
            return ORG_URL;
        } private set;
    }

    public static final String CURRENT_NAMESPACE {
        get {
            if (CURRENT_NAMESPACE == null) {
                List<String> classParts = MdtUtil.class.getName().split('\\.');
                CURRENT_NAMESPACE = (classParts.size() > 1) ? classParts[0] : '';
            }
            return CURRENT_NAMESPACE;
        }
        private set;
    }

    /**
     *  @description Returns the RecordTypeId based on SObject API Name and Record Type Label
     *  @param SObject sobjectType, String fieldName
     *  @example Apx.getRecordTypeId('Contact', 'Donor');
     */
    public static Id getRecordTypeId(String sobjectType, String recordTypeLabel) {
        try {
            return Schema.getGlobalDescribe().get(sobjectType).getDescribe().getRecordTypeInfosByName().get(recordTypeLabel).getRecordTypeId();
        } catch (Exception e) {
            Avodaas_Apx.debug(e);
            return null;
        }
    }

    public static Map<Id, String> getRecordTypesForObject(String sobjectType){
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(new List<String>{sobjectType});
        Schema.DescribeSObjectResult d = results[0];
        Map<Id,Schema.RecordTypeInfo> rtMapById = d.getRecordTypeInfosById();
        Map<Id, String> idsToLabels = new Map<Id, String>();
        for(Id rtId: rtMapById.keySet()) idsToLabels.put(rtId, rtMapById.get(rtId).getName());
        return idsToLabels;
    }

    /**
     * @description Given a list of records, return a Set of Id values for the given field
     */
    public static Set<Id> getIdSet(List<SObject> records, SObjectField fieldName) {
        Set<Id> ids = new Set<Id>();

        for(sObject record : records) {
            Id recordId = (Id) record.get(fieldName);
            if(recordId != null) ids.add(recordId);
        }

        return ids;
    }

    /**
     * @description A custom error string that compiles all the exception's error information into one string
     **/
    public static String longErrorString(System.Exception e) {
        return 'Message: ' + e.getMessage() + ', Cause: ' + e.getCause() + ', Type: ' + e.getTypeName() + ', Line Number: ' + e.getLineNumber() + ', Stack Trace: ' + e.getStackTraceString();
    }

  
    //========== General Debug Helpers ==========//

    /**
     * @description Logs a System.debug with all the general exception's information, according to the specified LoggingLevel
     **/
    public static void debug(LoggingLevel lvl, System.Exception e) {
        System.debug(lvl, longErrorString(e));
    }

    /**
     * @description Logs a System.debug with all the general exception's information, defaulting to a LoggingLevel of DEBUG
     **/
    public static void debug(System.Exception e) {
        System.debug(LoggingLevel.DEBUG, longErrorString(e));
    }

    public static void debugError(System.Exception e) { debug(LoggingLevel.ERROR, e); }


    /**
     *  @description Sends an email to the default admin email addresses
     */
    public static void sendAdminEmail (String subject, String msg) {
        sendEmail(ADMIN_EMAILS, subject, msg);
    }

    /**
     * Create a Messaging.SingleEmailMessage object 
     * @params List of to Email Addresses, Subject, Message, List of cc Addresses
     * @returns Messaging.SingleEmailMessage
     */
    public static Messaging.SingleEmailMessage setUpEmail(String[] toAddresses, String subject, String msg, String[] ccAddresses){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setReplyTo(ADMIN_REPLYTO_EMAIL);
        mail.setSenderDisplayName(ADMIN_SENDER_DISPLAYNAME);
        mail.setSubject(subject);
        mail.setPlainTextBody(msg);
        if(ccAddresses != null && !ccAddresses.isEmpty()) mail.setCcAddresses(ccAddresses);
        return mail;
    }

    /**
     * Create a Messaging.SingleEmailMessage object 
     * @params List of to Email Addresses, Subject, Message
     * @returns Messaging.SingleEmailMessage
     */
    public static Messaging.SingleEmailMessage setUpEmail(String[] toAddresses, String subject, String msg){
        return setUpEmail(toAddresses, subject, msg, null);
    }
   

    /**
     *  @description Sends an email to the specified email addresses
     */
    public static void sendEmail (String[] toAddresses, String subject, String msg) {
        Messaging.SingleEmailMessage mail = setUpEmail(toAddresses, subject, msg);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    /**
     *  @description Sends a debug email to the default admin email addresses
     */
    public static void debugEmail(Exception e) {
        debugError(e);
        sendAdminEmail(UserInfo.getOrganizationName() + ' SF Apex Error', longErrorString(e));
    }

	/**
	*  @description get a list of fields and returns a list of field types 
	*/
	public static List<String> getFieldTypes(List<Schema.SObjectField> fields){
		List<String> types = new List<String>();
		for(Schema.SObjectField sobField : fields) types.add(sobField.getDescribe().getType().name());
		return types;
	}

	/**
	*  @description Accepts a field object and returns the number of characters allowed
	*/
	public static Integer getFieldLength(SObjectField sobField){
		Schema.DescribeFieldResult fieldDescription = sobField.getDescribe();
		return fieldDescription.getLength();
	}

	/**
	*  @description Accepts an object and returns all the custom fields
	*/
	public static List<String> getCustomFieldsForSObject(String ObjName){
		List<String> customFields = new List<String>();
		Map <String, Schema.SObjectField> fieldMap = Avodaas_Apx.getSObjectFields(ObjName);
		for(Schema.SObjectField sfield : fieldMap.Values()){
			if(sfield.getDescribe().getName().endsWith('__c'))customFields.add(sfield.getDescribe().getName());
		}
		return customFields;
	}



	/**
	*  @description inserts error logs into the system 
	*/
	public static void createErrorLog (Exception e, String filename) {
		try{
			Avodaas_Logs__c log = new Avodaas_Logs__c(Field_Name__c = '', Object_Name__c = '', Record__c = '', Line_Number__c = '', Error_Message__c = '', Field_Type__c = '');
			String operator = '';
			SObjectField sobField;
			log.Error_Type__c = e.getTypeName();
			switch on log.Error_Type__c {
				when 'System.DmlException' {
					for(Integer i = 0; i < e.getNumDml(); i++){
						log.Field_Name__c += operator + String.join(e.getDmlFieldNames(i), '|');
						if(e.getDmlId(i) != null){
							Id dmlId = e.getDmlId(i);
							log.Record__c += operator + dmlId;
							log.Object_Name__c = dmlId.getSObjectType().getDescribe().getName();
						}
						log.Line_Number__c += operator + e.getDmlIndex(i); 
						log.Field_Type__c += operator + String.join(Avodaas_Apx.getFieldTypes(e.getDmlFields(i)), '|');
						log.Error_Message__c += operator + e.getDmlMessage(i);
						operator = '|';
					}
				}
				when else {
					log.Error_Message__c = e.getMessage();
					log.Line_Number__c = String.valueOf(e.getLineNumber()); 
				}
			}
			log.Stack_Trace__c = e.getStackTraceString();
			log.User__c = userinfo.getUserId();
			log.File_Name__c = filename;
			List<String> customFields = Avodaas_Apx.getCustomFieldsForSObject('Avodaas_Logs__c');
			Map<String, Schema.SObjectField> logFields = Avodaas_Apx.getSObjectFields('Avodaas_Logs__c');
			for(String field :customFields){
				sobField = logFields.get(field);
				Integer fieldLen = Avodaas_Apx.getFieldLength(sobField);
				if(string.valueOf(log.get(field)).length() > fieldLen){
					String fieldVal = string.valueOf(log.get(field));
					log.put(field, fieldVal.substring(0, fieldLen - 1));
				}
			}
			insert log;
		}catch(Exception ex){
			String message = 'Avodaas_Apx.errorLogs => the error:' + ex.getMessage() + '\r\nStack Trace: ' + ex.getStackTraceString();
			Avodaas_Apx.sendAdminEmail('Error inserting Log Tracking', message);
			System.debug(message);
		}
		
	}

    /***
     * @description Get FieldSet For given SObject
     * @param FieldSetName, SObjectName
     * @return Schema.FieldSetMember if the fieldset exists, null if not
     */
    public static List<Schema.FieldSetMember> getFieldSetMembers(String objectApiName, String fieldSetName){
        Map<String, Schema.FieldSet>  fieldsetMap = ((SObject)Type.forName(objectApiName).newInstance()).getSObjectType().getDescribe().FieldSets.getMap();
        return (fieldSetMap != null && fieldSetMap.containsKey(fieldSetName)) ? fieldSetMap.get(fieldSetName).getFields() : null;
    }

    /**
     * Source:https://gist.github.com/valentijnspruyt/028e0a6a7ced39e23de310e8efac7761
     * @name getfieldSetFieldsByFieldSetName
     * @description Helper method to retrieve fields in a fieldset
     */
    /*public static List<FieldSetField> getFieldSetFieldsByFieldSetName(String objectApiName, String fieldSetName){
        List<Schema.FieldSetMember> fieldSetMembers = getFieldSetMembers(objectApiName, fieldSetName);
        if(fieldSetMembers == null) return null;
        List<FieldSetField> fields = new List<FieldSetField>();
        for (Schema.FieldSetMember fieldSetMember : fieldSetMembers){
            FieldSetField fieldSetField = new FieldSetField(fieldSetMember);
            fields.add(fieldSetField);
        }
        return fields;
    }*/

    /**
     * Return the result of getFieldSetFieldsByFieldSetName as a list of api field names
     */
    /*public static List<String> getFieldSetAPINamesbyFieldSetName(String objectApiName, String fieldSetName){
        List<String> apiNames = new List<String>();
        List<FieldSetField> fields = getFieldSetFieldsByFieldSetName(objectApiName, fieldSetName);
        if(fields == null) return null;
        for(FieldSetField fs: fields) apiNames.add(fs.apiName);
        return apiNames;
    }*/

    /**
  * @description format date for soql
  * @param DateTime var
  * @returnVal String
  **/
  public static String dateTimeToSoql(DateTime inDateTime){
    return inDateTime.format('yyyy-MM-dd HH:mm:ss').replace(' ', 'T') + 'Z';
    }

    public static String getPaddedNum(Integer inDayMonth){
    String theDayMonth = String.valueOf(inDayMonth);
    if(inDayMonth < 10) theDayMonth = '0' + theDayMonth;
    return theDayMonth;
  }
    
    /**
  * @description format date for soql
  * @param DateTime var
  * @returnVal String
  **/
  public static String dateToSoql(Date inDate){
    return inDate.year() + '-' + getPaddedNum(inDate.month()) + '-' + getPaddedNum(inDate.day());
    }
    
    /**
     *  @description Returns non-duplicate values from two different picklist strings that are semi-colon separated.
     *  @example Avodaas_Apx.mergePicklistValues('Conference;Webinar', 'Webinar;Trade Show');
     */
    public static String mergePicklistValues(String plString1, String plString2) {
        List<String> valueList = new List<String>();
        if (plString1 != null && String.isNotBlank(plString1)) valueList.addAll(plString1.split(';'));
        if (plString2 != null && String.isNotBlank(plString2)) valueList.addAll(plString2.split(';'));
        valueList.sort();
        return (valueList.isEmpty()) ? '' : String.join(new List<String>(new Set<String>(valueList)), ';');
    }

    /****
     * @description Get Object name from a record id
     * @param RecordId
     * @return Object Name
     */
    public static String getObjectNameById(Id recordId){
        return recordId.getSObjectType().getDescribe().getName();
    }

    /***
     * @description Test if SObject exists
     * @param String object api name
     * @return True or False
     */
    public static Boolean doesSObjectExist(String objectAPIName){
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        return gd.containsKey(objectAPIName);
    }

    /**
     * @description Get Describe Sobject Result
     * @param String object api name
     * @return Describe SObject result or null if it doesn't exist
     */
    public static Schema.DescribeSObjectResult getSObjectDescribeResult(String objectAPIName){
        List<Schema.DescribeSObjectResult> dsors;
        try{
            dsors = Schema.describeSObjects(new List<String>{objectAPIName});
        } catch(System.InvalidParameterValueException e){
            //object doesn't exist
            return null;
        }
        if(dsors == null || dsors.isEmpty()) return null;
        return dsors[0];
    }

     /**
     * @description Get a map of field API Names and labels for an Object.
     * @param String object api name
     * @return Map of field api names & labels or null if the object doesn't exist
     */
    public static Map<String, String> getSObjectFieldNames(String objectAPIName){
        Schema.DescribeSObjectResult describeResult = getSObjectDescribeResult(objectAPIName);
        if(describeResult == null) return null;
        Map<String, String> fields = new Map<String, String>();
        Map<String, Schema.SObjectField> objFields = describeResult.fields.getMap();
        Schema.DescribeFieldResult dfr;
        for(Schema.SObjectField field: objFields.values()){
            dfr = field.getDescribe();
            fields.put(dfr.getName(), dfr.getLabel());
        }
        return fields;
    }

    /***
     * @description Get a map of sobject field API Names to the actual SObjectField object
     * @param String object api name
     * @return Map of field api names & SObjectField objects
     */
    public static Map<String, Schema.SObjectField> getSObjectFields(String objectAPIName){
        Schema.DescribeSObjectResult describeResult = getSObjectDescribeResult(objectAPIName);
        if(describeResult == null) return null;
        Map<String, Schema.SObjectField> fields = new Map<String, Schema.SObjectField>();
        Map<String, Schema.SObjectField> objFields = describeResult.fields.getMap();
        Schema.DescribeFieldResult dfr;
        for(Schema.SObjectField field: objFields.values()){
            dfr = field.getDescribe();
            fields.put(dfr.getName(), field);
        }
        return fields;
    }

    /****
     * @description Get field type for a SObject field
     * @param SObject field
     * @return String field type
     */
    public static String getFieldType(Schema.SObjectField theField){
        return theField.getDescribe().getType().name();
    }

    /**
     * @description Get a list of legal values for a picklist field
     * @param Object name and Field name
     * @return List of picklist values
     */
    public static List<String> getPicklistValues(String objectAPIName, String fieldAPIName) { 
        if(objectApiName == null || fieldApiName == null) return null; 
        //verify that the object & field exist
        Map<String, Schema.SObjectField> objectFields = getSObjectFields(objectAPIName);
        if(objectFields == null || !objectFields.containsKey(fieldAPIName)) return null;

        //get the SObjectField Describe Result
        Schema.DescribeFieldResult describe = objectFields.get(fieldAPIName).getDescribe();

        //verify that the field is a picklist field
        Schema.DisplayType theDisplayType = describe.getType();
        if(theDisplayType != Schema.DisplayType.Picklist && theDisplayType != Schema.DisplayType.MultiPicklist) return null;

        //get the values!
        List<String> picklistValues = new List<String>();
        for (Schema.PicklistEntry a: describe.getPickListValues()) picklistValues.add(a.getValue());

        return picklistValues;
    }

    public static String getQuarter(Date theDate){
        if(theDate == null) theDate = System.today();
        switch on theDate.month() {
            when 1, 2, 3{
                return '1';
            }
            when 4, 5, 6{
                return '2';
            }
            when 7, 8, 9{
                return '3';
            }
            when 10, 11, 12{
                return '4';
            }
        }
        return null;
    }

    public static String getQuarter(){
        return getQuarter(null);
    }
    
    public static String getQuarterWithYear(Date theDate){
        String quartPart = getQuarter(theDate);
        if(String.isEmpty(quartPart)) return null;
        return theDate.year() + '-Q' + quartPart;
    }

}