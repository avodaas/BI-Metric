@isTest
private with sharing class MdtUtil_Test {

    @isTest static void CodeCoverage() {
        MdtUtil.updateMdtRecord([SELECT Id, MasterLabel, QualifiedApiName FROM BI_Metric_Fields__mdt LIMIT 1], 'MasterLabel', 'Test 123');
    }
}