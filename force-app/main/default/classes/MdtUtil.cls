public with sharing class MdtUtil {

	public class MdtUtilException extends Exception {}

	// Based on: https://sfcure.com/2018/05/28/how-to-create-update-custom-metadata-record-using-apex-lightning-component/
	public static void updateMdtRecord(SObject mdtRecord, String field, Object value) {
		if (mdtRecord == null || String.isBlank(field)) throw new MdtUtilException('Please specify a valid mdtRecord and field to update');
		updateMdtRecord(mdtRecord, new Map<String, Object>{ field => value });
	}

	public static void updateMdtRecord(SObject mdtRecord, Map<String, Object> fieldToValues) {
		if (mdtRecord == null || fieldToValues == null || fieldToValues.isEmpty()) throw new MdtUtilException('Please specify a valid mdtRecord and field to update');
		updateMdtRecords(new List<SObject>{mdtRecord}, fieldToValues, null);
	}

	public static void updateMdtRecords(List<SObject> mdtRecords, Map<String, Object> fieldToValues, Metadata.DeployCallback callback) {
		if (mdtRecords == null || mdtRecords.isEmpty() || fieldToValues == null || fieldToValues.isEmpty()) throw new MdtUtilException('Please specify a valid mdtRecord and field to value map to update');

		Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();

		for (SObject mdtRecord : mdtRecords) {
			Metadata.CustomMetadata customMdt = prepMdt(mdtRecord, fieldToValues);
			System.debug( 'MdtUtil::updateMdtRecord(): Updating custom metadata object: ' + customMdt );
			mdContainer.addMetadata(customMdt);
		}

		// Async update to MDT (to avoid DML Mixed operations)
		Id queueJobId = System.enqueueJob(new MdtAsync(mdContainer, callback));
        System.debug('the queue job id: ' + queueJobId);
	}

	public static Metadata.CustomMetadata prepMdt(SObject mdtRecord, Map<String, Object> fieldToValues) {
		if (mdtRecord == null || fieldToValues == null || fieldToValues.isEmpty()) throw new MdtUtilException('Please specify a valid mdtRecord and field to value map to update');
		String mdtType = mdtRecord.getSObjectType().getDescribe().getName();
		String recordDevName = ((String)mdtRecord.get('QualifiedApiName'));			//.get('MasterLabel')).replaceAll(' ', '_');
		//String nsPrefix = Avodaas_apx.CURRENT_NAMESPACE + (String.isBlank(apx.CURRENT_NAMESPACE) ? '' : '__');

		Metadata.CustomMetadata customMdt =  new Metadata.CustomMetadata();
		customMdt.fullName = mdtType + '.' + recordDevName;		//nsPrefix + mdtType + '.' + recordDevName;
		customMdt.label = (String)mdtRecord.get('MasterLabel');

		// Add all the field value pairs
		String nsFieldPrefix = (String.isBlank(Avodaas_apx.CURRENT_NAMESPACE) ? '' : Avodaas_apx.CURRENT_NAMESPACE + '__');
		for (String field : fieldToValues.keySet()) {
			Object value = fieldToValues.get(field);
			Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
			customField.field = nsFieldPrefix + field;
			customField.value = value;
			customMdt.values.add(customField);
		}

		return customMdt;
	}

	// Helper class to run Metadata commands asyncronously
	public class MdtAsync implements Queueable {
		public Metadata.DeployContainer container;
		public Metadata.DeployCallback callback;
		public Id mdtJobId;

		public MdtAsync(Metadata.DeployContainer mdc, Metadata.DeployCallback mdCallback) {
			container = mdc;
			callback = mdCallback;
		}

		public void execute(QueueableContext context) {
			if (container == null) return;
			if (!Test.isRunningTest()) mdtJobId = Metadata.Operations.enqueueDeployment(container, callback);
		}
	}
}