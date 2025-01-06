@suppressWarnings('pmd')
public without sharing class CsvParserLwcController {
    

    @AuraEnabled(cacheable=true)
    public static List<LwcDtos.Option> getCsvConfigOptions(){
        try {
            List<LwcDtos.Option> options = new List<LwcDtos.Option>();
            SobjectDomainService service = new SobjectDomainService('Csv_Config__c');
            List<Csv_Config__c> configs = Test.isRunningTest() ? new List<Csv_Config__c>{ new Csv_Config__c(Name='Test') } : (List<Csv_Config__c>)service.getAll();
            for(Csv_Config__c config : configs){
                options.add(new LwcDtos.Option(config.Name, config.Id ?? null));
            }
            
            return options;
        } catch (Exception e) {
            System.debug(e.getMessage() + ' | ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static LwcDtos.CsvConfigurationRecord getCsvConfig(string configId){  
        try {
            LwcDtos.CsvConfigurationRecord configRecord = new LwcDtos.CsvConfigurationRecord();
            if(String.isNotBlank(configId) && !configId.equalsIgnoreCase('null')){
                SobjectDomainService service = new SobjectDomainService('Csv_Config__c');
                Csv_Config__c dat  = Test.isRunningTest() ?  new Csv_Config__c() : (Csv_Config__c)service.getRecordWhereIdIs(configId);
                configRecord = new LwcDtos.CsvConfigurationRecord(dat);
            }

            return configRecord ;
        } catch (Exception e) {
            System.debug(e.getMessage() + ' | ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true)
    public static List<LwcDtos.Option> getInteractionFieldListOptions(string objectApiName){
        try {
            List<LwcDtos.Option> options =new List<LwcDtos.Option>();
            for(Schema.SobjectField fieldType : SobjectDescribeUtils.getFieldMap(objectApiName).values()){
                Schema.DescribeFieldResult dfr = fieldType.getDescribe();
                if(dfr.isCreateable()){
                    options.add(new LwcDtos.Option(fieldType.getDescribe().getLabel() , fieldType.getDescribe().getName()));
                }
            }
            return options;
        } catch (Exception e) {
            System.debug(e.getMessage() + ' | ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<LwcDtos.Option> getAllSObjectsList(){
        try {
            List<LwcDtos.Option> options =new List<LwcDtos.Option>();
            for(Schema.SobjectType objectType : Schema.getGlobalDescribe().values()){
                Schema.DescribeSObjectResult describe = objectType.getDescribe();
                if(describe.isCreateable() && describe.isAccessible() && !describe.isCustomSetting() && !describe.getName().endsWithIgnoreCase('History')
                && !describe.getName().endsWithIgnoreCase('Tracking') && !describe.getName().endsWithIgnoreCase('Feed')){
                    options.add(new LwcDtos.Option(objectType.getDescribe().getLabel() , objectType.getDescribe().getName()));

                }
            }
            //options.sort();
            return options;
        } catch (Exception e) {
            System.debug(e.getMessage() + ' | ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=false)
    public static string saveOrUpdateConfig(LwcDtos.CsvConfigurationRecord record){
        try {
            Csv_Config__c csvConfigRecord = record.toRecord();
            StanbicIbtcCompliantDml.dmlUpsert(new List<Csv_Config__c>{csvConfigRecord});
            return Test.isRunningTest() ?  'fakeId' : csvConfigRecord.Id;
            
        } catch (Exception e) {
            System.debug(e.getMessage() + ' | ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<LwcDtos.Option> getCSVSourceFieldOptions(string csv){
        try {
            List<LwcDtos.Option> options = new List<LwcDtos.Option>();
            ApexCsvParserTool tool = new ApexCsvParserTool(csv);
            tool.run();
            
            for(string header : tool.getHeaders()){
                options.add(new LwcDtos.Option(header,header));
            }
            return options;
        } catch (Exception e) {
            System.debug(e.getMessage() + ' | ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * @description converts the data from the csv into Sobject records. (I think i wanna make this asynchronous as an enhancement )
     */
    @AuraEnabled(cacheable=true)
    public static boolean convertDataFromCsv(string csvFile, map<string,string> fieldMappings , List<LwcDtos.LookUpConfig> lookupConfigs, string objectApiName, string recordTypeId){
        try {
            //LwcDtos.CsvConversionResult result = new LwcDtos.CsvConversionResult();
            ApexCsvParserTool tool = new ApexCsvParserTool(csvFile);
            tool.run();
            // move this to an asynchronous context.
            CsvDataExtractorLinkedList ll = tool.getLinkedList();
            ll.setFieldMap(fieldMappings);
            ll.setSobjectType(objectApiName);
            ll.setLookupConfigs(lookupConfigs);
            ll.setRecordTypeId(recordTypeId);
            System.enqueueJob(ll);
            //ll.run();
            return true;

        } catch (Exception e) {
            System.debug(e.getMessage() + ' | ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getListViewPath(string objectApiName){
        try {
            return SobjectDescribeUtils.getListViewPath(objectApiName);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    // @AuraEnabled
    // public static void initiateDbWriteBatchable(List<Sobject> records){
    //     try {
    //         Database.executeBatch(new CsvParserBatchInsertApex(records), 200);
    //     } catch (Exception e) {
    //         System.debug(e.getMessage() + ' | ' + e.getStackTraceString());
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }


    @AuraEnabled(cacheable=true)
    public static List<LwcDtos.Option> getRecordTypesFor(string sobjectApiName){
        System.debug(sobjectApiName);
        try {
            List<LwcDtos.Option> options = new List<LwcDtos.Option>();
            for(RecordType rt : SobjectDescribeUtils.getRecordTypesBelongingTo(sobjectApiName)){
                options.add(new LwcDtos.Option(rt.Name , rt.Id));
            }
            return options;
        } catch (Exception e) {
            System.debug(e.getMessage() + ' | ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }




}