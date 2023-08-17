/**
 *	BIMetric_Test
 *	  Unit tests for BIMetric class
 *		@author Avodaas
 *		@date	Feb 2021
 **/
@isTest
private class BIMetricModel_Test {
    
    @isTest static void testBIMetrics(){
        //actual tests for bulk insertion are in LeadModel.
        //this is only to test the single insertion method
        //TestBIModel.initData gives code coverage
        Test.startTest();
        TestBIModel.initData();
        List<String> statusVals = Avodaas_Apx.getPicklistValues('Lead', 'Status');
        String statusVal2 = statusVals.size() > 1 ? statusVals[1] : '';
        BIMetricModel.createBIMetric('Status', statusVals[0], TestBIModel.myLead.Id, TestBIModel.myLead.OwnerId);
        BIMetricModel.createBIMetric('Status', statusVal2, TestBIModel.myLead.Id, TestBIModel.myLead.OwnerId);
        TestBIModel.case1.OwnerId = TestBIModel.supportQueueGroup.Id;
        update TestBIModel.case1;
        Test.stopTest();
        //try to select the metric that should have been created by the above call
        //if it wasn't created, the test fails with no rows to assign error
        BI_Metric__c biMetric = [SELECT Id, Previous_Record__r.Completed_Date__c, Owner_Name__c, Owner_Role__c
                FROM BI_Metric__c 
                WHERE Lead__c = :TestBIModel.myLead.Id and Lifecycle_Field__c  = 'Status' AND New_Value__c = :statusVal2
                LIMIT 1];
        User leadOwner = [SELECT Name, UserRole.Name FROM User WHERE Id = :TestBIModel.user1.Id];
        //validate that the previous one was completed, owner info set.
        System.assertEquals(System.today(), biMetric.Previous_Record__r?.Completed_Date__c);
        System.assertEquals(leadOwner.Name, biMetric.Owner_Name__c);
        System.assertEquals(leadOwner.UserRole.Name, biMetric.Owner_Role__c);

        //code coverage for bad object names 
        List<BIMetricModel.BIFieldWrapper> fields = BIMetricModel.getFieldsToTrackForSObject('A bad object');
        System.assertEquals(null, fields);
        ///create via wrappers
        List<BIMetricModel.BIUpdateWrapper> wrappers = new List<BIMetricModel.BIUpdateWrapper>();
        wrappers.add(new BIMetricModel.BIUpdateWrapper(TestBIModel.opp1.Id, 'Sales_Qualified_Lead_Date__c', TestBIModel.user1.Id, System.today(), null));
        wrappers.add(new BIMetricModel.BIUpdateWrapper(TestBIModel.vet1.Id, 'Email', TestBIModel.user1.Id, 'test@test.com', null));
        wrappers.add(new BIMetricModel.BIUpdateWrapper(TestBIModel.opp1.Id, 'CreatedDate', TestBIModel.user1.Id, System.now(), null));
        wrappers.add(new BIMetricModel.BIUpdateWrapper(TestBIModel.opp1.Id, 'Amount', TestBIModel.user1.Id, 250.00, null));
        BIMetricModel.createBIMetrics(wrappers);
        wrappers.clear();
        //code coverage for more than one metric per object & field, and with data types
        wrappers.add(new BIMetricModel.BIUpdateWrapper(TestBIModel.opp1.Id, 'Sales_Qualified_Lead_Date__c', TestBIModel.user1.Id, System.today().addDays(3), 'DATE'));
        wrappers.add(new BIMetricModel.BIUpdateWrapper(TestBIModel.opp1.Id, 'CreatedDate', TestBIModel.user1.Id, System.now().addHours(3), 'DATETIME'));
        wrappers.add(new BIMetricModel.BIUpdateWrapper(TestBIModel.opp1.Id, 'Amount', TestBIModel.user1.Id, 350.00, 'CURRENCY'));
        BIMetricModel.createBIMetrics(wrappers);
        wrappers.clear();
        wrappers.add(new BIMetricModel.BIUpdateWrapper(TestBIModel.opp1.Id, 'Sales_Qualified_Lead_Date__c', TestBIModel.user1.Id, System.today().addDays(4), 'DATE'));
        wrappers.add(new BIMetricModel.BIUpdateWrapper(TestBIModel.opp1.Id, 'CreatedDate', TestBIModel.user1.Id, System.now().addHours(4), 'DATETIME'));
        wrappers.add(new BIMetricModel.BIUpdateWrapper(TestBIModel.opp1.Id, 'Amount', TestBIModel.user1.Id, 360.00, 'CURRENCY'));
        System.enqueueJob(new QueueableBIMetric(wrappers));
    }
}
