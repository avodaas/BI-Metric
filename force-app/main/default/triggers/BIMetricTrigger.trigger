/**
 *	BIMetricTrigger
 *		@description Our single trigger for handling all BIMetric trigger logic.
 *		@author Avodaas
 **/
trigger BIMetricTrigger on BI_Metric__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new BIMetricModel().onTrigger();
}