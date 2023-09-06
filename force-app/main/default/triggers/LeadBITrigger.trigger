/**
 *  LeadTrigger
 *    @description Our single trigger for handling all Lead trigger logic.
 *    @author BMiller
 *    @date  Sept 2017
 **/
trigger LeadBITrigger on Lead (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new LeadBIModel().onTrigger();
}
