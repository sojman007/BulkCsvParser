@suppressWarnings('pmd')
@isTest
public without sharing class CsvDataExtractorLinkedListAndNodeTest {
   
    
    @isTest
    public static void testLinkedList(){
        Test.startTest();
        CsvDataExtractorLinkedList ll = new CsvDataExtractorLinkedList();
        for(map<string,object> record : getTestData()){
            ll.appendNode(new CsvDataExtractorLLNode().setData(record));
        }
        ll.addResult(1, new Account(Name ='Test'));
        ll.setFieldMap(new map<string,string>{'Name' => 'Name' ,'Email' =>'Email__c' , 'Address' =>'Residential_Address__c'});
        //List<LwcDtos.LookUpConfig> lookupConfigs = new List<LwcDtos.LookUpConfig>{new LwcDtos.LookUpConfig('Account','Name','Id')};
        ll.setSobjectType('Account');
        //ll.setLookupConfigs(lookupConfigs);
        ll.setRecordTypeId((String)Account.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get('SIAML').getRecordTypeId());
        System.enqueueJob(ll);

        Test.stopTest();

    }

    @IsTest

    static void testNode(){
        Test.startTest();

        map<string,Schema.SObjectField> fieldmap = Account.getSObjectType().getDescribe().fields.getMap();
        
        LwcDtos.LookUpConfig config = new LwcDtos.LookUpConfig();
        config.lookupField = 'Email';
        config.lookupObject= 'Account';
        config.sflookupField = 'AccountId';

        

        CsvDataExtractorLinkedList ll = new CsvDataExtractorLinkedList();
        ll.setFieldMap(new map<string,string>{'Name' => 'Name' ,'Email' =>'Email__c' , 'Address' =>'Residential_Address__c'});
        ll.setLookupConfigs(new List<LwcDtos.LookUpConfig>{config});
        ll.sobjectType = Account.getSObjectType();
        
        CsvDataExtractorLLNode node = new CsvDataExtractorLLNode();
        node.setParent(ll);
        node.setData(new map<string,object>{'Name' => 'Test','Email' =>'Adesoji@gmail.com'});
        node.getData();
        node.setIndex(1);
        node.getNodeNumber();
        node.getDataFormatted();
        node.execute(null);
        node.tryGetVal('Test', fieldmap.get('name').getDescribe());
        node.tryGetVal('500000', fieldmap.get('annualrevenue').getDescribe());
        node.tryGetVal('05/05/2025', fieldmap.get('issue_date__c').getDescribe());
        node.tryGetVal(Datetime.now(), fieldmap.get('createddate').getDescribe());
        node.tryGetVal('30.5', fieldmap.get('cashflow_cycle__c').getDescribe());
        node.tryGetVal('True', fieldmap.get('do_not_call__c').getDescribe());
        

        
        
        Test.stopTest();
        
    }


    private static list<map<string,Object>> getTestData(){

        return new list<map<string,Object>>{
            new map<string,Object>{'Name' =>'Adesoji','Email' =>'Sojman@gmail.com','Address'=>'"Test Street , Some Place"'},
            new map<string,Object>{'Name' =>'Adesoji2','Email' =>'Sojman1@gmail.com','Address'=>'"Test Street 2 , Some Place"'},
            new map<string,Object>{'Name' =>'Adesoji3','Email' =>'Sojman2@gmail.com','Address'=>'"Test Street 3 , Some Place"'}
            
        };
    }
}