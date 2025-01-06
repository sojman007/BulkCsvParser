public without sharing class CsvParserBatchInsertApex implements Database.Batchable<CsvParserRecordWrapper>, Database.Stateful {
    

    private List<CsvParserRecordWrapper> recordsToSave = new List<CsvParserRecordWrapper>();
    private integer insertedSize = 0;
    private Csv_Parser_Save_Job__c  parserJob;
    private string parserLogId ='';
    map<integer ,List<String>> errors = new Map<integer, List<String>>();
    private static final string BATCH_RESULT_LOGLINE = '<p><strong>BATCH RECORD SAVE RESULTS</strong></p><ul><li><i>Number Of Successfully Saved Records : {0} </i> </li><li><i>Number Of Failed Records : {1} </i> </li></ul>';

    
    public CsvParserBatchInsertApex(List<CsvParserRecordWrapper> records , string parserLogId) {
        recordsToSave.addAll(records);
        this.parserLogId = parserLogId;
        parserJob = new Csv_Parser_Save_Job__c();
        parserJob.Name = UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + ' | Batch Save Job  ' + String.valueOfGmt(Datetime.now().addHours(1));
        parserJob.Record_Ids__c ='';
        parserJob.Sobject_Type_Api_Name__c = records[0].getRecord().getSObjectType().getDescribe().getName();
        insert parserJob;
    }

    public Iterable<CsvParserRecordWrapper> start(Database.BatchableContext cont){
        List<Csv_Parser_Notification__e> platformEvents = new List<Csv_Parser_Notification__e>();
        Csv_Parser_Notification__e event = new Csv_Parser_Notification__e(
            Event_Type__c ='BATCH_START'
        );
        platformEvents.add(event);
        EventBus.publish(platformEvents);

        return this.recordsToSave;
    }

    public void execute(Database.BatchableContext ctx , List<CsvParserRecordWrapper> scope){
        try{
            map<integer, Sobject> toSaveMap = CsvParserRecordWrapper.listToRecordmap(scope);
            map<integer, CsvParserRecordWrapper> toSaveWrapperMap = CsvParserRecordWrapper.listToWrappermap(scope);
            List<Sobject> toSave = toSaveMap.values();
            List<Database.SaveResult> saveResults =   Database.insert(toSave, false, System.AccessLevel.USER_MODE);
            handleDatabaseSaveResults(saveResults, toSaveWrapperMap);
            
            
        }catch(exception e){
            List<Csv_Parser_Notification__e> platformEvents = new List<Csv_Parser_Notification__e>();
            map<string,object> errorMessage = new map<string,Object>{'error'=> e.getMessage()};
            Csv_Parser_Notification__e event = new Csv_Parser_Notification__e(
                Event_Type__c ='BATCH_ERROR', Message_Json__c = JSON.serialize(errorMessage)
            );
            platformEvents.add(event);
            EventBus.publish(platformEvents);
        }
    }


    private string getErrorDump(){
        string errorDump = '';
        for(integer index : errors.keySet()){
            errorDump += '\nDb Errors At Row : ' + index + '\n';
            errorDump += String.join(errors.get(index),'' + '\n');
        }

        return errorDump;


    }

    private void handleDatabaseSaveResults(List<Database.SaveResult> saveResults, map<integer, CsvParserRecordWrapper> toSaveWrapperMap){
        integer successSize = 0;
        integer index = 0;
        integer failedSize = 0;
        List<integer> indices = new List<integer>(toSaveWrapperMap.keySet());
        for(Database.SaveResult result :saveResults){ 
            if(result.success){
                successSize +=1;
                parserJob.Record_Ids__c += result.id  + ',';
            }else{
                failedSize += 1;
                List<string> errList = new List<String>();
                for(Database.Error error  : result.getErrors()){
                    errList.add('   - ' + error.getMessage() + '. Fields [ ' + String.join(error.getFields() ,', ') + ' ]');
                }
                errors.put(indices.get(index), errList);
            }
            index += 1;
        }
        insertedSize += successSize;

        if(failedSize > 0){
            List<Csv_Parser_Notification__e> platformEvents = new List<Csv_Parser_Notification__e>();
            map<string,object> errorMessage = new map<string,Object>{'failedRecords'=> this.errors.size() , 'passedRecords' => this.insertedSize};
            
            Csv_Parser_Notification__e event = new Csv_Parser_Notification__e(
                Event_Type__c ='BATCH_PROGRESS', Message_Json__c = JSON.serialize(errorMessage)
            );
            platformEvents.add(event);
            EventBus.publish(platformEvents);

        }
    }


    public void finish(Database.BatchableContext ctx){
        
        SobjectDomainService service = new SobjectDomainService('Csv_Parser_Log__c');
        Csv_Parser_Log__c log = String.isNotBlank(parserLogId) ?  (Csv_Parser_Log__c)service.getRecordWhereIdIs(parserLogId) : new Csv_Parser_Log__c();
       
        if(String.isBlank(parserLogId)){
            log.Name = UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + ' | CSV PARSER OPERATION RESULTS ' + Datetime.now().addHours(1);
        }
        string formattedString =  String.format(BATCH_RESULT_LOGLINE, new List<Integer>{ this.insertedSize , errors.size() });
        log.Log_Lines_Formatted__c = String.isNotBlank(log.Log_Lines_Formatted__c) ? (log.Log_Lines_Formatted__c + '\n' + formattedString) : formattedString;
        StanbicIbtcCompliantDml.dmlUpsert(new List<Csv_Parser_Log__c>{log});
        
        if(errors.size() > 0){
            Attachment errorAttachmentFile = new Attachment();
            errorAttachmentFile.Name = log.Name + ' ERROR LOG FILE';
            errorAttachmentFile.ParentId = log.Id;
            errorAttachmentFile.ContentType = 'text/plain';
            errorAttachmentFile.Body = Blob.valueOf(getErrorDump());
            StanbicIbtcCompliantDml.dmlInsert(new List<Attachment>{errorAttachmentFile});
        }

        List<Csv_Parser_Notification__e> platformEvents = new List<Csv_Parser_Notification__e>();
        Csv_Parser_Notification__e event = new Csv_Parser_Notification__e(
            Event_Type__c ='BATCH_END' , Message_JSON__c = JSON.serialize(new map<string,Object>{'success' => this.insertedSize ,'failed' => errors.size()})
        );
        platformEvents.add(event);
        
        EventBus.publish(platformEvents);
        parserJob.Total_Number_Of_Records__c = this.insertedSize;
        update parserJob;
    }
}