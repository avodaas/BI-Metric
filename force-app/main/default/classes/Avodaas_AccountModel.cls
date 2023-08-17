/**
 *	AccountModel
 *  	@description Base class for Account object code, including static methods and variables
 *		@testclass	AccountModel_Test
 *		@author Avodaas
 *		@date   Jan 2021
 **/
public with sharing class Avodaas_AccountModel extends BaseBIModel{
    /**
	 * @description Populate records with the appropriate values on all Trigger.isBefore events
	 */
	public override void processBeforeEvents() {
		//if (Trigger.isInsert) {}
		//if (Trigger.isUpdate) {}
	}
	/**
	 * @description Update related records on all Trigger.isAfter events
	 */
	public override void processAfterEvents() {
		//if (Trigger.isInsert) {}
		//if (Trigger.isUpdate) {}
	}
}