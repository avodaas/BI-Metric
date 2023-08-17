/**
 *	
 *	  @description Abstract class for initializing Airvet-specific data for unit tests.
 *	  @example  TestBIModel.initData();
 *				TestBIModel.city1.ParentId = TestBIModel.country1.Id;
 *				update TestBIModel.city1;
 *	  @author Avodaas
 *	  @date	Aug 2020
 */
public abstract with sharing class TestBIModel {

    public static Account hospital1, clinic1;
    public static Contact vet1, vet2, secretary1;
    public static Opportunity opp1, opp2;
    public static Lead myLead, campaignLead, badLandingPageLead, leadWithParams;
    public static Campaign landingPageCamp, noLandingPageCamp;
   // public static Onboarding__c onboard1;
    //public static Milestone__c milestone1, milestone2;
    public static User user1, user2;
    public static Group supportQueueGroup;
    public static QueuesObject supportQueue;
    public static Case case1;
    public static Product2 prod1, prod2;
    public static PricebookEntry pbe1, pbe2;
    public static OpportunityLineItem oli1, oli2, oli3;

    public static void initData(){

        
        List<User> users = (List<User>)SmartFactory.createSObjectList('User', false, 2);
        user1 = users[0];
        user1.FirstName = 'A nice';
        user1.LastName = 'name';
        user1.Email = 'test@test1.com';
        user2 = users[1];
        user2.FirstName = 'Another';
        user2.LastName = 'name';
        user2.Email = 'test2@test.com';
        insert users;

        supportQueueGroup = (Group)SmartFactory.createSObject('Group');
        supportQueueGroup.Type = 'Queue';
        supportQueueGroup.Name = 'Support Queue';
        //hard coding because of the following error: IncludeBosses should only be specified for public groups
        supportQueueGroup.DoesIncludeBosses = null;
        insert supportQueueGroup;


        //because this is a setup object, it needs to be run in a different context
        System.runAs(new User(Id=UserInfo.getUserId())){
            supportQueue = new QueueSObject(QueueID = supportQueueGroup.Id, SObjectType = 'Case');
            insert supportQueue;
        }



        List<Account> accts = (List<Account>)SmartFactory.createSObjectList('Account', false, 2);
        hospital1 = accts[0];
        hospital1.Name = 'The hospital';
        clinic1 = accts[1];
        clinic1.Name = 'Clinic 1';
        insert accts;

        List<Contact> cons = (List<Contact>)SmartFactory.createSObjectList('Contact', false, 3);
        vet1 = cons[0];
        vet1.LastName = 'Vet';
        vet2 = cons[1];
        vet2.LastName = 'Erin';
        secretary1 = cons[2];
        secretary1.LastName = 'Organized';
        insert cons;

        List<Campaign> campaigns = (List<Campaign>)SmartFactory.createSObjectList('Campaign', false, 2);
        landingPageCamp = campaigns[0];
        landingPageCamp.Name = 'A form campaign';
        landingPageCamp.IsActive = true;
        noLandingPageCamp = campaigns[1];
        noLandingPageCamp.Name = 'No form campaign';
        noLandingPageCamp.IsActive = true;
        insert new List<Campaign>{landingPageCamp, noLandingPageCamp};

        List<Lead> leads = (List<Lead>)SmartFactory.createSObjectList('Lead', false, 5);
        myLead = leads[0];
        myLead.lastName = 'Test';
        myLead.Email = 'lead@email.com';
        myLead.Company = 'A nice company';
        myLead.OwnerId = user1.Id;
        campaignLead = leads[1];
        campaignLead.LastName = 'Test Again';
        campaignLead.Email = 'campaign@email.com';
        campaignLead.Company = 'Another Company';
        badLandingPageLead = leads[2];
        badLandingPageLead.LastName = 'Another test';
        badLandingPageLead.Email = 'bad@email.com';
        badLandingPageLead.Company = 'Company';
        leadWithParams = leads[3];
        leadWithParams.lastName = 'Last';
        leadWithParams.Company = 'Last Company';
        leadWithParams.Email = 'params@email.com';
        insert new List<Lead>{myLead, campaignLead, badLandingPageLead, leadWithParams};

       /* onboard1 = (Onboarding__c)SmartFactory.createSObject('Onboarding__c');
        onboard1.Account__c = hospital1.Id;
        onboard1.Start_Date__c = System.Date.today();
        onboard1.Target_End_Date__c = System.Date.today().addDays(30);
        onboard1.Description__c = 'Lets get this hospital off the ground.';
        onboard1.Next_Steps__c = 'We need to set up a meeting.';
        insert onboard1;

        List<Milestone__c> milestones = (List<Milestone__c>)SmartFactory.createSObjectList('Milestone__c', false, 2);
        milestone1 = milestones[0];
        milestone1.Onboarding__c = onboard1.Id;
        milestone1.Due_Date__c = System.today().addDays(50);
        milestone1.Objectives__c = 'Nice objectivs, work well together.';

        milestone2 = milestones[1];
        milestone2.Account__c = clinic1.Id;
        milestone2.Due_Date__c = System.today().addDays(300);
        milestone2.Objectives__c = 'Multiply customer subscription by 100%';

        insert milestones;*/

        case1 = (Case)SmartFactory.createSObject('Case');
        case1.OwnerId = user1.Id;
        case1.ContactId = vet1.Id;
        case1.Subject = 'Help!!';
        insert case1;

        List<Product2> prods = (List<Product2>)SmartFactory.createSObjectList('Product2', false, 2);
        prod1 = prods[0];
        prod1.Name = 'Onboarding Fee';
        prod2 = prods[1];
        prod2.Name = 'Platform Fee';

        insert prods;

        List<PricebookEntry> pbes = (List<PricebookEntry>)SmartFactory.createSObjectList('PricebookEntry', false, 2);
        Id pbId = Test.getStandardPricebookId();
        pbe1 = pbes[0];
        pbe1.Pricebook2Id = pbId;
        pbe1.Product2Id = prod1.Id;
        pbe1.UnitPrice = 100.00;
        pbe1.IsActive = true;
        pbe2 = pbes[1];
        pbe2.Pricebook2Id = pbId;
        pbe2.Product2Id = prod2.Id;
        pbe2.UnitPrice = 300.00;
        pbe2.IsActive = true;
        insert pbes;

        List<Opportunity> opps = (List<Opportunity>)SmartFactory.createSObjectList('Opportunity', false, 2);
        opp1 = opps[0];
        opp1.AccountId = hospital1.Id;
        opp1.CloseDate = System.today().addDays(30);
        opp1.Amount = 300;
        opp1.OwnerId = user1.Id;
        opp2 = opps[1];
        opp2.AccountId = clinic1.Id;
        opp2.CloseDate = System.today().addMonths(3);
        opp2.Revenue_Recognition_Date__c = System.today().addMonths(5);
        opp2.Amount = 5000;
        opp2.OwnerId = user1.Id;
        insert opps;

        List<OpportunityLineItem> olis = (List<OpportunityLineItem>)SmartFactory.createSObjectList('OpportunityLineItem', false, 3);
        oli1 = olis[0];
        oli1.OpportunityId = opp1.Id;
        oli1.Quantity = 3;
        oli1.pricebookEntryId = pbe2.Id;
        oli1.TotalPrice = 3 * pbe2.UnitPrice;
        oli2 = olis[1];
        oli2.OpportunityId = opp1.Id;
        oli2.Quantity = 1;
        oli2.PricebookEntryId = pbe1.Id;
        oli2.TotalPrice = pbe1.UnitPrice;
        oli3 = olis[2];
        oli3.OpportunityId = opp2.Id;
        oli3.Quantity = 1;
        oli3.PricebookEntryId = pbe1.Id;
        oli3.TotalPrice = pbe1.UnitPrice;
        insert olis;
    }
}
