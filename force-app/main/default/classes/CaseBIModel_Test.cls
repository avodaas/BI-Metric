/**
 *  Case_Test
 *    Unit tests for Case class
 *    @author Avodaas
 *    @date  Feb 2021
 **/
@isTest
private class CaseBIModel_Test {
    @isTest static void testBIMetrics(){
        TestBIModel.initData();
        List<String> statusVals = Avodaas_Apx.getPicklistValues('Case', 'Status');
        TestBIModel.case1.Status = statusVals[0];
        Test.startTest();
        update TestBIModel.case1;
        Test.stopTest();
        //verify that a new bi metric was created
        BI_Metric__c biMetric = [SELECT New_Value__c
                FROM BI_Metric__c 
                WHERE Case__c = :TestBIModel.case1.Id and Lifecycle_Field__c  = 'Status' 
                        AND New_Value__c = :statusVals[0] LIMIT 1];
    }
}
