/**
 *  AccountTrigger
 *    @description Our single trigger for handling all Account trigger logic.
 *    @author Avodaas
 **/
trigger Avodaas_AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new Avodaas_AccountModel().onTrigger();
}
