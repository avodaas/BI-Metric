/**
 *  ContactModel
 *    @description Base class for Contact object code, including static methods and variables
 *    @testclass  ContactModel_Test
 *    @author Avodaas
 *    @date   Feb 2021
 **/
public with sharing class Avodaas_ContactModel extends BaseBIModel{
    // ========== Static Object Variables ========== //
    // ============================================= //

    
    // ========== Trigger Handler ========== //
    // ===================================== //

    /**
     * @description Populate records with the appropriate values on all Trigger.isBefore events
     **/
    public override void processBeforeEvents() {
        if (Trigger.isInsert || Trigger.isUpdate) {}
    }

    /**
    * @description Update related records on all Trigger.isAfter events
    **/
    public override void processAfterEvents() {
        if (Trigger.isInsert) { }
        if (Trigger.isUpdate) {}
    }


    // ========== Trigger Helpers ========== //
    // ===================================== //


}