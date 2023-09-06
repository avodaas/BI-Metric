/***
 *      @description Extends BaseModel class, adds BIMetric tracking. Requires a custom metadata
 *                  BI_Metric_Fields record per field to be tracked.
 *    @testclass  BaseBIModel_Test.cls
 *      @examples   In Trigger:  new AccountBIModel().onTrigger();
 *      @author     Avodaas
 *      @date       Feb 2021
 * 
 * */
public with sharing abstract class BaseBIModel extends Avodaas_BaseModel{

    public String OBJECT_API_NAME;
    //list of fields to track for specific object, as per custom metadata BI_Metric_Fields records
    public List<BIMetricModel.BIFieldWrapper> BI_METRIC_FIELDS{
        get{
            if(BI_METRIC_FIELDS == null){
                if(OBJECT_API_NAME == null) setObjectAPIName();
                BI_METRIC_FIELDS = BIMetricModel.getFieldsToTrackForSObject(OBJECT_API_NAME);
            }
            return BI_METRIC_FIELDS;
        } private set;
    }

    public void setObjectAPIName(){
        if(this.triggerRecords == null || this.triggerRecords.isEmpty()) return;
        SObjectType triggerObjectType = this.triggerRecords[0].getSObjectType();
        OBJECT_API_NAME = triggerObjectType.getDescribe().getName();
    }

    public String getOwnerIdField(){
        if(!OBJECT_API_NAME.endsWith('__c')) return 'OwnerId';
        Map<String, Schema.SObjectField> fields = Avodaas_Apx.getSObjectFields(OBJECT_API_NAME);
        if(fields.containsKey('OwnerId')) return 'OwnerId';
        for(String fieldAPIName: fields.keySet()){
            if(fieldAPIName.contains('Owner')) return fieldAPIName;
        }
        return null;
    }

    //this method is declared in the parent class, as a virtual method. 
    public override void processAfterEventsExtension(){
        if(Trigger.isInsert || Trigger.isUpdate) populateBIMetrics();
    }

    public virtual void populateBIMetrics(){
        if(BI_METRIC_FIELDS == null || BI_METRIC_FIELDS.isEmpty()) return;
        List<BIMetricModel.BIUpdateWrapper> wrappers = new List<BIMetricModel.BIUpdateWrapper>();
        String ownerIdField = getOwnerIdField();
        String fieldName;
        for(SObject sobj: triggerRecords){
            for(BIMetricModel.BIFieldWrapper biField: BI_METRIC_FIELDS){
                fieldName = biField.fieldName;
                if(isFieldChanged(sobj, biField.objField)){
                    if(Trigger.isInsert && sobj.get(fieldName) == null) continue;
                    System.debug('sobj.get(fieldName)'+ sobj.get(fieldName) + 'fieldName'+fieldName+' biField.fieldType'+ biField.fieldType);
                    wrappers.add(new BIMetricModel.BIUpdateWrapper(Id.valueOf((String)sobj.get('Id')), fieldName, 
                            Id.valueOf((String)sobj.get(ownerIdField)), sobj.get(fieldName), biField.fieldType));
                } 
            }
        }
        if(!wrappers.isEmpty()) BIMetricModel.createBIMetrics(wrappers);
    }
}
