public with sharing class QueueableBIMetric implements System.Queueable{
    
    public List<BIMetricModel.BIUpdateWrapper> wrappers;

    public QueueableBIMetric(List<BIMetricModel.BIUpdateWrapper> wrappersIn) {
        wrappers = wrappersIn;
    }

    public void execute(System.QueueableContext ctx) {
        BIMetricModel.createBIMetrics(this.wrappers);
    }
}
