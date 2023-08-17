/**
 *  Apx_Test
 *    Unit tests for Apx class
 *  
 **/
@isTest
public class Avodaas_Apx_Test {
    @isTest static void Apx_helperMethods_Test() {
        UnsupportedObjectTypeException uote = new UnsupportedObjectTypeException();
        Avodaas_Apx.longErrorString(uote);
        TestBIModel.initData();
        Set<Id> idSet = Avodaas_Apx.getIdSet(new List<SObject>{TestBIModel.vet1}, Contact.AccountId);
        Avodaas_Apx.debugError(uote);
        Avodaas_Apx.debug(uote);
        Avodaas_Apx.debugEmail(uote);
        try{
            TestBIModel.vet1.Email = 'bad Value';
            update TestBIModel.vet1;
        }catch(Exception ex) {
            Avodaas_Apx.createErrorLog(ex, 'Apx_Test');
        }
        System.assertNotEquals([SELECT Id FROM Avodaas_Logs__c WHERE Error_Type__c = 'System.DmlException'].size(), 0);
        //== Apx.sendEmail() Unit tests for ==//
        Avodaas_Apx.sendAdminEmail('Email Subject', 'Body of the test email');
        //consider changing this test if we use record types for a standard object??
        Id rtId = Avodaas_Apx.getRecordTypeId('Account', 'Nice rt name');
        //bad rt - doesn't exist
        rtId = Avodaas_Apx.getRecordTypeId('Account', 'bad one');
        Map<Id, String> recordTypesToLabels = Avodaas_Apx.getRecordTypesForObject('Account');
        //for this org
        //List<String> fieldLists = Avodaas_Apx.getFieldSetAPINamesbyFieldSetName('Account', 'AvodaasTest');
        //non existent
        //fieldLists = Avodaas_Apx.getFieldSetAPINamesbyFieldSetName('Contact', 'Details_Left');

        Id marketingQueueId = Avodaas_Apx.MARKETING_QUEUE_ID;
        String orgUrl = Avodaas_Apx.ORG_URL;
        String magementEmail = Avodaas_Apx.MANAGEMENT_EMAIL;

        String dateTimeString = Avodaas_Apx.dateTimeToSoql(Datetime.now());
        String dateString = Avodaas_Apx.dateToSoql(Date.today());

        String mergedValues = Avodaas_Apx.mergePicklistValues('a;b;job;', 'c;b;');
        System.assertEquals('a;b;c;job', mergedValues, 'Merge Picklist Values didnt work!');

        Account a = new Account(Name='Acme');
        insert a;
        System.assertEquals('Account', Avodaas_Apx.getObjectNameById(a.Id));

        Map<String, String> fieldMap = Avodaas_Apx.getSObjectFieldNames('Account');
        System.assert(fieldMap.containsKey('CreatedDate'));
        fieldMap = Avodaas_Apx.getSObjectFieldNames('a bad object name');
        System.assertEquals(null, fieldMap);

        Map<String, Schema.SObjectField> fields = Avodaas_Apx.getSObjectFields('Account');
        System.assertNotEquals(null, fields);

        //can't count on any vals!! Just code coverage
        //this should always work.
        List<String> pickVals = Avodaas_Apx.getPicklistValues('Lead', 'Status');
        System.assert(!pickVals.isEmpty());
        //non existant obj
        pickVals = Avodaas_Apx.getPicklistValues('Bad obj', 'Does not matter');
        System.assertEquals(null, pickVals);
        //non existant field
        pickVals = Avodaas_Apx.getPicklistValues('Lead', 'Bad field name');
        System.assertEquals(null, pickVals);
        //non picklist field
        pickVals = Avodaas_Apx.getPicklistValues('Lead', 'Name');
        System.assertEquals(null, pickVals);

        //bad object
        System.assertEquals(false, Avodaas_Apx.doesSObjectExist('A bad object name'));
        //good one
        System.assert(Avodaas_Apx.doesSObjectExist('Account'));
        Date today = System.today();
        Integer year = today.year();
        Date janDate = Date.newInstance(year, 1, 1);
        Date mayDate = Date.newInstance(year, 5, 1);
        Date augDate = Date.newInstance(year, 8, 1);
        Date novDate = Date.newInstance(year, 11, 1);
        System.assertEquals('1', Avodaas_Apx.getQuarter(janDate));
        System.assertEquals('2', Avodaas_Apx.getQuarter(mayDate));
        System.assertEquals('3', Avodaas_Apx.getQuarter(augDate));
        System.assertEquals('4', Avodaas_Apx.getQuarter(novDate));
        System.assertEquals(Avodaas_Apx.getQuarter(today), Avodaas_Apx.getQuarter());
        System.assertEquals(year + '-Q3', Avodaas_Apx.getQuarterWithYear(augDate));
    }
}