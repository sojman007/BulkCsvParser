@suppressWarnings('pmd')
public without sharing class CsvDataExtractorLinkedList implements System.Queueable{
    
    public  List<CsvParserRecordWrapper> results = new List<CsvParserRecordWrapper>();
    public  map<string,string> fieldMap;
    private string recordTypeId;
    public  Schema.SobjectType sobjectType;
    private List<LwcDtos.LookUpConfig> lookupConfigurations;
    private List<string> errorLines = new List<String>();
    private integer nodeCount = 0;
    private map<integer,List<string>> nodeErrors = new map<integer,List<string>>();
    private List<CsvDataExtractorLLNode> nodes = new List<CsvDataExtractorLLNode>();
    private integer index = 0;
    private string errorCsv ='';
    private static final string ERROR_LINE = '<p><strong> CSV CONVERSION RESULTS</strong><p><ul><li><i>Total Number Of  Converted Records From CSV : {0}</i></li><li><i>Total Number Of Unconverted Records From CSV : {1}</i></li>';


    public void appendNode(CsvDataExtractorLLNode node){
        node.setParent(this);
        nodeCount += 1;
        nodes.add(node.setIndex(nodeCount));
    }

    private boolean hasNext(){
        return this.nodes.size()  > (this.index +1);
    }

    private CsvDataExtractorLLNode getNode(integer index){
        return this.nodes[index];
    }
   

    public integer getNodeCount(){
        return this.nodeCount;
    }

    
    public void addErrorLog(string errorLine){
        errorLines.add(errorLine);
    }

    public void addErrorLineFornode(integer node , string errorMessage){
        if(nodeErrors.containsKey(node)){
            nodeErrors.get(node).add(errorMessage);
        }else{
            nodeErrors.put(node, new List<string>{errorMessage});
        }
    }

    public void appendDataToErrorCsv(map<string,object> csvData){
        string errorCsvCopy = this.errorCsv;
        if(String.isBlank(errorCsvCopy)){
            errorCsv = String.join(csvData.keySet(), ',');
            
        }
        List<string> lineData = new List<string>();
        for(object value : csvData.values()){
            string valueAsString = (String)value;
            if(valueAsString.contains(',')){
                valueAsString ='"'+valueAsString+'"';
            }
            lineData.add(valueAsString);
        }
        errorCsv +=  '\n'+ String.join(lineData ,',');
    }


     public void execute(QueueableContext qtx){
        boolean limitHit = false;
        while(limitHit == false){
            CsvDataExtractorLLNode next = getNode(this.index);
            next.execute();
            limitHit = Limits.getQueries() >= (Limits.getLimitQueries() - next.getQueryLimitCount()); 
            if(this.hasNext()){
                this.index += 1;
            }else{
                break;
            }
        }
        
        logEvent();
        if(this.hasNext()){
            this.index += 1;
            if(!Test.isRunningTest()){
                System.enqueueJob(this);
            }
        }else{
            finish();
        }

    }  

            

        
    
        
            
       

     
    public void logEvent(){
        string errorStream = '<ol>';
        for(List<string> errormessages : nodeErrors.values()){
            errorStream += String.join(errormessages,'\n');
        }
        errorStream +='</ol>';
        map<string,object> metricsMap = new map<string,object>{'processedRecords' => this.results.size() ,'failedRecords' => this.nodeErrors.size() , 'errorMessages'=> errorStream };
        publishNotificationEvent('CONVERT_PROGRESS', JSON.serialize(metricsMap));
    }
     

    public  void addResult(integer index,Sobject record){
       results.add(new CsvParserRecordWrapper(record , index));
    }

    public void setRecordTypeId(string recordTypeId){
        this.recordTypeId = recordTypeId;
    }

    public  void setSobjectType(string objectApiName){
        sobjectType = SobjectDescribeUtils.getSobjectTypeIgnoreCase(objectApiName);
     }

    public void setFieldMap(map<string,string> fieldMapx){
        fieldMap = fieldMapx;
    }

    public void setLookupConfigs( List<LwcDtos.LookUpConfig> config){
        this.lookupConfigurations = config;
    }

    public  List<LwcDtos.LookUpConfig> getLookupConfigs(){
        return this.lookupConfigurations;
    }
    public string getRecordTypeId(){
        return this.recordTypeId;
    }
    public List<CsvParserRecordWrapper> getResults(){
        return new List<CsvParserRecordWrapper>(this.results);
    }

    public boolean hasRecordType(){
        return String.isNotBlank(this.recordTypeId);
    }
   

    public void finish(){
        // save records in batches;
        map<string,Object> result = new map<string,Object>();
        string status = '';
        string message ='';
        string errorLogId ='';
        if(nodeErrors.size() > 0){
            errorLogId = writeErrors();
        }

        if(!this.results.isEmpty()){
            message = 'The parser has successfully converted ' +this.results.size() + ' rows into Salesforce records';
            status = 'success';
            CsvParserBatchInsertApex batchWriteToDb = new CsvParserBatchInsertApex(this.results , errorLogId);
            Database.executeBatch(batchWriteToDb, 200);
            
        }else{
            message = 'There were no records parsed from the csv due to some errors';
            status = 'error';
        }
        result.put('message',message);
        result.put('status',status);
        publishNotificationEvent('CONVERT_END', JSON.serialize(result));
    }



    private string writeErrors(){
        Csv_Parser_Log__c log = new Csv_Parser_Log__c();
        log.Name = UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + ' | CSV PARSER OPERATION RESULTS @ ' + Datetime.now().addHours(1);
        log.Log_Lines_Formatted__c = String.format(ERROR_LINE, new List<integer>{this.results.size(), nodeErrors.size()});
        StanbicIbtcCompliantDml.dmlInsert(new List<Csv_Parser_Log__c>{log});
        
        Attachment csvAttachment  = new Attachment();
        csvAttachment.Body = Blob.valueOf(errorCsv);
        csvAttachment.ParentId = log.Id;
        csvAttachment.Name ='Csv Parser Errors - '+ Datetime.now().addHours(1) +'.csv';
        csvAttachment.ContentType='text/csv';
        StanbicIbtcCompliantDml.dmlInsert(new List<Attachment>{csvAttachment});

        return log.Id;
    }


    private void publishNotificationEvent(string eventType, string payload){
        List<Csv_Parser_Notification__e> platformEvents = new List<Csv_Parser_Notification__e>();
        Csv_Parser_Notification__e event = new Csv_Parser_Notification__e(
            Event_Type__c =eventType
        );
        if(payload != null){
            event.Message_Json__c = payload;
        }
        platformEvents.add(event);
        EventBus.publish(platformEvents);
    }







}