/**
 *	BaseModel_Test
 *	  Unit tests for BaseModel class
 *		NOTE: This is being run on ContactTrigger to activate the test Contacts/code coverage
 **/
@isTest
public class BaseBIModel_Test extends Avodaas_BaseModel {
	private static String CONT_NAME = 'TestLastBase';
	private static String UPDATE_CONT_NAME = 'UpdatedTestLastBase';

	private static Account acct {
		get {
			if (acct == null) {
				acct = new Account(Name = 'TestOrg');
				insert acct;
			}
			return acct;
		}
		set;
	}

	private static Set<Id> idsBeforeInsert = new Set<Id>();
	private static Set<Id> idsAfterUpdate = new Set<Id>();

	public override void processBeforeEvents() {
		if(Trigger.isInsert) idsBeforeInsert = triggerRecordIds;

		for(Contact c : (List<Contact>)triggerRecords) {
			if(this.isFieldChanged(c, Contact.AccountId)) System.debug('Account Changed!');
			if(this.isFieldChangedTo(c, Contact.AccountId, acct.Id)) System.debug('Account Changed To: ' + acct.Id);
			if(this.isFieldChangedFrom(c, Contact.AccountId, acct.Id)) System.debug('Account Changed From: ' + acct.Id);
			this.getRecordsWithSameValue(Contact.AccountId, Contact.AccountId);
			this.getRecordsWithSameValue(Contact.AccountId, Contact.Id);

			Contact oldContact = (Contact)getOldRecord(c);
			//System.debug(oldContact);
			Id oldAccountId = (Id)getOldValue(c, Contact.AccountId);
			//System.debug(oldAccountId);
			System.debug(this.isFieldChangedToOneOf(c, Contact.LastName, new List <String>{CONT_NAME}));
			System.assertEquals(false, this.isFieldChangedToOneOf(c, Contact.LastName, new List <String>{}), 'Check If Name Changed On an Empty List');
			System.assertEquals(false, this.isFieldChangedToOneOf(c, Contact.LastName, null), 'Check If Name Changed To Null');
		}

		List<Contact> changedContacts = getChangedRecords(Contact.AccountId);
		Set<Id> trigIds = triggerRecordIds;
	}

	public override void processAfterEvents() {
		if(Trigger.isUpdate) idsAfterUpdate = triggerRecordIds;

		for(Contact c : (List<Contact>)triggerRecords) {
			System.debug(isFieldChangedTo(c, Contact.AccountId, null));
			System.debug(isFieldChangedFrom(c, Contact.AccountId, acct.Id));
			System.debug(getOldRecord(c));
			System.debug(getOldValue(c, Contact.AccountId));
			System.debug(getRecordsWithFieldValue(Contact.AccountId, acct.Id));
		}
	}

	@isTest static void CodeCoverage_Test() {

		Test.startTest();
		
		Contact c = new Contact();
		c.AccountId = acct.Id;
		c.LastName = CONT_NAME;
		insert c;

		System.assert(idsBeforeInsert.size() == 0);
		c.LastName = UPDATE_CONT_NAME;
		update c;
		System.assert(idsAfterUpdate.size() == 1);

		delete c;
		Test.stopTest();
	}
}