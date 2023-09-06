public with sharing class BiMetricController {

	@AuraEnabled(cacheable=true)
	public static List<BI_Metric_Fields__mdt> getBiMdtRecords() {
		return [SELECT Id, masterLabel, Field_Name__c, Object_Name__c, Active__c FROM BI_Metric_Fields__mdt];
	}

	@AuraEnabled(cacheable=true)
	public static List<Bi_Metric_Objects__mdt> getObjectNames() {
		return [SELECT Id, QualifiedApiName, DeveloperName FROM Bi_Metric_Objects__mdt];
	}
	
	@AuraEnabled(cacheable=true)
	public static List<String> getFieldsByObjectName(String objectName) {
		return new List<String>(Avodaas_Apx.getSObjectFields(objectName).keySet());
	}

	@AuraEnabled(cacheable=true)
	public static void createBiMetric(String masterLabel, String objectName, String fieldName, Boolean isActive) {
		try {
			BI_Metric_Fields__mdt newMet = new BI_Metric_Fields__mdt(
				MasterLabel = masterLabel,
				QualifiedApiName = masterLabel.replaceAll('\\W+', '_')
			);
			// Prepping mdt for insertion
			Map<String, Object> setMdtFields = new Map<String, Object>{
				'Field_Name__c' => fieldName,
				'Object_Name__c' => objectName,
				'Active__c' => isActive
			};
			MdtUtil.updateMdtRecords(new List<BI_Metric_Fields__mdt>{newMet}, setMdtFields, null);
		} 
		catch (Exception e) {
			throw new AuraHandledException(e.getMessage() + ' | ' + e.getStackTraceString());
		}
	}

	@AuraEnabled(cacheable=true)
	public static void editBiMetric(String biId, String masterLabel, String objectName, String fieldName, Boolean isActive) {
		try {
			List<BI_Metric_Fields__mdt> biMetricMdts = [
				SELECT Id, MasterLabel, QualifiedApiName, Field_Name__c, Object_Name__c, Active__c 
				FROM BI_Metric_Fields__mdt
				WHERE Id = :biId
			]; 
			if (biMetricMdts.isEmpty()) return;
			BI_Metric_Fields__mdt mdt = biMetricMdts[0];
			mdt.MasterLabel = masterLabel;
			// updated fields
			Map<String, Object> mdtDetails = new Map<String, Object>{
				'Field_Name__c' => fieldName,
				'Object_Name__c' => objectName,
				'Active__c' => isActive
			};
			MdtUtil.updateMdtRecord(mdt, mdtDetails);
		} 
		catch (Exception e) {
			throw new AuraHandledException(e.getMessage() + ' | ' + e.getStackTraceString());
		}
	}

	@AuraEnabled(cacheable=true)
	public static void mdtActivation(String mdtId, Boolean isActive) {
		try {
			// Get the current mdt record if it exists
			List<BI_Metric_Fields__mdt> biMetricMdts = [
				SELECT Id, MasterLabel, QualifiedApiName, Field_Name__c, Object_Name__c, Active__c 
				FROM BI_Metric_Fields__mdt
				WHERE Id = :mdtId
			]; 
			if (biMetricMdts.isEmpty()) return;
			BI_Metric_Fields__mdt mdt = biMetricMdts[0];
			// Call the metadata job to update the mdt
			MdtUtil.updateMdtRecord(mdt, 'Active__c', isActive);
		} 
		catch (Exception e) {
			throw new AuraHandledException(e.getMessage() + ' | ' + e.getStackTraceString());
		}
	}

	@AuraEnabled
	public static SetupBiMetricsInfo getFilteredBiMdtRecords(Integer queryLimit, Integer queryOffset, String sortBy, String sortDirection, String searchKey) {
		String query = 'SELECT Id, MasterLabel, Field_Name__c, Object_Name__c, Active__c ' +
						'FROM BI_Metric_Fields__mdt ' +
						'WHERE MasterLabel LIKE \'%' + String.escapeSingleQuotes(searchKey) + '%\' ' +
						'ORDER BY ' + String.escapeSingleQuotes(sortBy) + ' ' + sortDirection +
						' LIMIT ' + queryLimit +
						' OFFSET ' + queryOffset;
		return new SetupBiMetricsInfo(
			[SELECT count() FROM BI_Metric_Fields__mdt],
			database.query(query)
		);
	}
	
	public class SetupBiMetricsInfo {

		@AuraEnabled
		public Integer totalRecordCount { get;set; }

		@AuraEnabled
		public List<BI_Metric_Fields__mdt> biRecords{ get;set; }

		public SetupBiMetricsInfo(Integer totalRecordCount, List<BI_Metric_Fields__mdt> biRecords) {
			this.totalRecordCount = totalRecordCount;
			this.biRecords = biRecords;
		}
	}

}