/**
 *  Account_Test
 *    Unit tests for Account class
 *    @author Avodaas
 *    @date  Feb 2021
 **/
@isTest
private class Avodaas_AccountModel_Test {
    @isTest static void testBIMetrics(){
        TestBIModel.initData();
        List<String> statusVals = Avodaas_Apx.getPicklistValues('Account', 'Account_Status__c');
        TestBIModel.clinic1.Account_Status__c = statusVals[0];
        Test.startTest();
        update TestBIModel.clinic1;
        Test.stopTest();
        //verify that a new bi metric was created
        BI_Metric__c biMetric = [SELECT New_Value__c
                FROM BI_Metric__c 
                WHERE Account__c = :TestBIModel.clinic1.Id and Lifecycle_Field__c  = 'Account_Status__c' 
                        AND New_Value__c = :statusVals[0] LIMIT 1];
    }
    
}