/**
 *	    BIMetricSortable_Test
 *	    Unit Tests for BIMetricSortable class
 *		@author Avodaas
 *		@date	Feb 2021
 **/
@isTest
private class BIMetricSortable_Test {
    
    @isTest static void testSortable(){
        TestBIModel.initData();
        List<String> statusVals = Avodaas_Apx.getPicklistValues('Lead', 'Status');
        BIMetricModel.createBIMetric('Status', statusVals[0], TestBIModel.myLead.Id, TestBIModel.myLead.OwnerId);
        Id metricId = BIMetricModel.getMostRecentBIRecord(TestBIModel.myLead.Id, 'Status');
        BI_Metric__c theMetric = [SELECT CreatedDate, Id FROM BI_Metric__c WHERE Lead__c = :TestBIModel.myLead.Id LIMIT 1];
        String statusVals2 = statusVals.size() > 1 ? statusVals[1] : statusVals[0];
        BI_Metric__c nextMetric = new BI_Metric__c(
            Lifecycle_Field__c = 'Status', 
            New_Value__c = statusVals2, 
            Previous_Record__c = metricId, 
            Owner_Id__c = TestBIModel.myLead.ownerId, 
            Updating_User__c = UserInfo.getUserId(), 
            Record_Id__c = String.valueOf(TestBIModel.myLead.Id)
        );
        insert nextMetric;
        BI_Metric__c clonedMetric = nextMetric.clone();
        insert clonedMetric;

        //now set the different created dates
        Test.setCreatedDate(metricId, System.today().addDays(-30));
        Test.setCreatedDate(clonedMetric.Id, System.today().addDays(-60));
        
        //create a list of wrapers 
        List<BIMetricSortable> sortMe = new List<BIMetricSortable>();
        sortMe.add(new BIMetricSortable(theMetric));
        sortMe.add(new BIMetricSortable(nextMetric));
        sortMe.add(new BIMetricSortable(clonedMetric));
        //sort them!
        sortMe.sort();       

    }
}
