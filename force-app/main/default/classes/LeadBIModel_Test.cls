/**
 *  Lead_Test
 *    Unit tests for Lead class
 *    @author Avodaas
 *    @date  Feb 2021
 **/
@isTest
private class LeadBIModel_Test {
    @isTest static void testBIMetrics(){
        TestBIModel.initData();
        List<String> statusVals = Avodaas_Apx.getPicklistValues('Lead', 'Status');
        String status2 = (statusVals.size() > 1) ? statusVals[1] : statusVals[0];
        TestBIModel.myLead.Status = statusVals[0];
        TestBIModel.leadWithParams.Status = status2;
        Test.startTest();
        update new List<Lead>{TestBIModel.myLead, TestBIModel.leadWithParams};
        Test.stopTest();
        //verify that a new bi metric was created
        BI_Metric__c biMetric = [SELECT New_Value__c
                FROM BI_Metric__c 
                WHERE Lead__c = :TestBIModel.leadWithParams.Id and Lifecycle_Field__c  = 'Status' 
                        AND New_Value__c = :status2 LIMIT 1];
    }
    
}