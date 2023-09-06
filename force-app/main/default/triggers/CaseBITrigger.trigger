/**
 *  CaseTrigger
 *    @description Our single trigger for handling all Case trigger logic.
 *    @author Avodaas
 *    @date  Feb 2021
 **/
trigger CaseBITrigger on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new CaseBIModel().onTrigger();
}

