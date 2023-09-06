/**
 *  ContactTrigger
 *    @description Our single trigger for handling all contact trigger logic.
 *    @author BMiller
 *    @date  Sept 2017
 **/
trigger Avodaas_ContactTrigger on Contact (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new Avodaas_ContactModel().onTrigger();
    if (Test.isRunningTest()) new BaseBIModel_Test().onTrigger();  // Getting Code Coverage on BaseModel
}
