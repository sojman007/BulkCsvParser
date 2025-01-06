@suppressWarnings('pmd')
@isTest
public with sharing class CsvParserLwcControllerTest {
    
    @IsTest
    static void testGetCsvConfig(){
        try{
            Test.startTest();
            CsvParserLwcController.getCsvConfigOptions();
            Test.stopTest();

        }catch (Exception e){}
        
    }


    @IsTest
    static void testPicklistOption(){
        try{
            Test.startTest();
            CsvParserLwcController.getInteractionFieldListOptions('Account');
            //CsvParserLwcController.getInteractionFieldListOptions('Invalid Object');
            Test.stopTest();

        }catch (Exception e){}
        
    }

    @IsTest
    static void testGetAllObject(){
        try{
            Test.startTest();
            CsvParserLwcController.getAllSObjectsList();
            Test.stopTest();

        }catch (Exception e){}
        
    }

    @IsTest
    static void testGetListViewPath(){
        try{
            Test.startTest();
            CsvParserLwcController.getListViewPath('Account');
            CsvParserLwcController.getListViewPath('Bleh Bleh');
            Test.stopTest();

        }catch(Exception e){}
        
    }

    @IsTest
    static void testGetCSVHeaders(){
        try{
            Test.startTest();
            string CSV_FILE ='Name,Email,Address\nSoji,Sojman007@gmail.com,"Morohunfola Street,Opic"\nSoji2,Sojman008@gmail.com,new address';
            CsvParserLwcController.getCSVSourceFieldOptions(CSV_FILE);
            CsvParserLwcController.getCSVSourceFieldOptions('CSV_FILE');
    
           
            Test.stopTest();

        }catch (Exception e){}
        
    }

    @IsTest
    static void testGetRecordTypes(){
        try{
            Test.startTest();
            CsvParserLwcController.getRecordTypesFor('Account');
            CsvParserLwcController.getRecordTypesFor('Bleh Bleh');
            
            Test.stopTest();

        }catch (Exception e){}
        
    }



    @IsTest
    static void testSaveorUpdateConfig(){
        try{
            Test.startTest();
            
            Csv_Config__c configTest = new Csv_Config__c();
            configTest.Name ='Test Record';
            configTest.Sobject_Api_Name__c = 'Account';
            configTest.Has_Lookups__c = true;
            configTest.Field_Map__c = 'Name:Name;Email:Email__c,Address:Residential_Address__c';
            configTest.Lookup_Config__c = 'Test:Test:Test';
            configTest.Active__c = true;
            configTest.Has_Lookups__c = false;
    
    
            LwcDtos.CsvConfigurationRecord configRecord = new LwcDtos.CsvConfigurationRecord();
            LwcDtos.CsvConfigurationRecord configRecord2 = new LwcDtos.CsvConfigurationRecord(configTest);
            CsvParserLwcController.saveOrUpdateConfig(configRecord);
            CsvParserLwcController.saveOrUpdateConfig(configRecord2);
    
            Test.stopTest();

        }catch (Exception e){

        }
        
    }

    @IsTest
    static void getTestCsvConfig(){
        try{
            Test.startTest();
            CsvParserLwcController.getCsvConfig('fakeId');
            Test.stopTest();

        }catch(Exception e){

        }
        
    }


    @IsTest
    static void testConvertDataFromCsv(){
        try{
            Test.startTest();
            string CSV_FILE ='Name,Email,Address\nSoji,Sojman007@gmail.com,"Morohunfola Street,Opic"\nSoji2,Sojman008@gmail.com,new address';
            map<string,string> fieldMap = new Map<String,String>{};
            fieldMap.put('Name', 'Name');
            fieldMap.put('Email', 'Email__c');
            fieldMap.put('Address', 'Residential_Address__c');
    
            List<LwcDtos.LookUpConfig> lcfs = new List<LwcDtos.LookUpConfig>();
    
            LwcDtos.LookUpConfig lcf = new LwcDtos.LookUpConfig();
            lcf.lookupField = 'Test';
            lcf.lookupObject = 'Account';
            lcf.sflookupField ='Id';
    
            lcfs.add(lcf);
            CsvParserLwcController.convertDataFromCsv(CSV_FILE, fieldMap, lcfs, 'Account', 'null');
            
            Test.stopTest();

        }catch (Exception e){

        }
        
    }
}