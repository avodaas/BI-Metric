/**
 * @name BIMetricSortable
 * @description Implements Comparable, allows sorting of BI_Metric__c
 *              records by created date DESCENDING: ie returns the newest
 * @testclass Code coverage in LeadModel_test
 * @author  Avodaas Feb 2021
 */
global class BIMetricSortable implements Comparable {

    public BI_Metric__c metric;
    
    public BIMetricSortable(BI_Metric__c biMetric) {
        metric = biMetric;
    }

    global Integer compareTo(Object compareTo) {
        BIMetricSortable otherMetric = (BIMetricSortable)compareTo;
        // The return value of 0 indicates that both elements are equal.
        if (metric.CreatedDate < otherMetric.metric.CreatedDate) return 1;
        if (metric.CreatedDate > otherMetric.metric.CreatedDate) return -1;
        return 0;
    }
}
