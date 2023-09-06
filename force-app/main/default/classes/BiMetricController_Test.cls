@isTest
public with sharing class BiMetricController_Test {
	
	@isTest static void codeCoverage_Test() {
		Test.startTest();
		BiMetricController.getBiMdtRecords();
		BiMetricController.getFilteredBiMdtRecords(20, 0, 'MasterLabel', 'ASC', 'Accou');
		BiMetricController.getFieldsByObjectName('Account');
		BiMetricController.getObjectNames();
		BiMetricController.createBiMetric('TestMasterLabel', 'TestobjectName', 'TestfieldName', true);
		List<BI_Metric_Fields__mdt> biMetrics = [SELECT Id FROM BI_Metric_Fields__mdt LIMIT 1];
		System.assertEquals(1, biMetrics.size());
		BiMetricController.editBiMetric(biMetrics[0].Id, 'TestMasterLabel', 'TestobjectName', 'TestfieldName', false);
		BiMetricController.mdtActivation(biMetrics[0].Id, true);
		Test.stopTest();
	}
}