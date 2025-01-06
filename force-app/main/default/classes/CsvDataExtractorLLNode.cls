public with sharing class CsvDataExtractorLLNode implements System.Queueable {
    
    private map<string,Object> data;
    CsvDataExtractorLinkedList parent;
    private integer index;

    public CsvDataExtractorLLNode setParent(CsvDataExtractorLinkedList par){
        parent = par;
        return this;
    }
    public CsvDataExtractorLLNode setData(map<string,Object> dat){
        this.data = dat;
        return this;
    }
    
    public CsvDataExtractorLLNode  setIndex(integer ind){
        index = ind;
        return this;
    }

    public integer getNodeNumber(){
        return this.index;
    }



    

    public void execute(System.QueueableContext context){
        execute();
    }

    public map<string,Object> getData(){
        return this.data;
    }

    public string getDataFormatted(){
        return JSON.serialize(this.data);
    }

    public integer getQueryLimitCount(){
        return parent?.getLookupConfigs()?.size() ?? 0;
    }
    public void execute(){
        try{
            Sobject newRecord = parent.sobjectType.newSObject();
            if(parent.hasRecordType()){
                newRecord.put('RecordTypeId', parent.getRecordTypeId());
            }
            Schema.DescribeSObjectResult objectDescribe = newRecord.getSObjectType().getDescribe();
            map<string,Schema.SObjectField> sobjectfieldMap = objectDescribe.fields.getMap();
            map<string,Id> lookupIds = getLookupIds();
            
            for(string csvField : parent.fieldMap.keySet()){
                Schema.DescribeFieldResult fieldDescribe = sobjectFieldMap.get(parent.fieldMap.get(csvField)).getDescribe();
                String sfFieldApiName = fieldDescribe.getName();
                if(lookupIds.containsKey(csvField)){
                    newRecord.put(sfFieldApiName, lookupIds.get(csvField));
                }else{
                    Object csvValue = data.get(csvField);
                    if(csvValue != null){
                        newRecord.put(sfFieldApiName, tryGetVal(data.get(csvField), fieldDescribe));
                    }
                }

            }
               
            parent.addResult(getNodeNumber(),newRecord);
           

        }catch(Exception e){
            System.debug(e.getMessage() + ' | ' + e.getStackTraceString());
            string errorMessage =  ' <li> Error  at Row #' + this.getNodeNumber() + ' : ' +e.getMessage() + ' @trace: ' + e.getStackTraceString() + '</li> ';
            parent.addErrorLineFornode(getNodeNumber(), errorMessage);
            this.data.put('Conversion Error', errorMessage);
            parent.appendDataToErrorCsv(this.data);
        }
    }

    @suppressWarnings('pmd')
    private map<string,ID> getLookupIds(){
        map<string,Id> result = new map<string,Id>();
        List<LwcDtos.LookUpConfig> lookUpConfigs = parent.getLookupConfigs();
        for(LwcDtos.LookUpConfig dto : lookUpConfigs){
            string config = dto.lookupObject;
            string csvColumn = dto.lookupField;
            string lookupField = dto.sflookupField;

            string lookupval = (string)data.get(csvColumn);

            if(String.isNotBlank(lookupval)){
                string query = 'Select Id   FROM ' + config + ' WHERE  ' + lookupField + ' =:lookupvalue LIMIT 1';
                System.debug(config + ' ' + lookupval);
                System.debug(query);
                Sobject queryresult = Test.isRunningTest()  ? new Account(Name='Test' , Id ='0015i000006iNjdAAE') 
                : Database.queryWithBinds(query, new map<string,string>{'lookupvalue'=>lookupval}, System.AccessLevel.SYSTEM_MODE).get(0);
                if(queryresult != null){
                    result.put(csvColumn,(Id)queryresult.get('Id'));
                }
            }
        }


        return result;

        
    }
    
    /**
     * @description : try to cast the value from the csv to itrs appropriate type depending on 
     * the value of the displayType enum on the  destination salesforce field 
     */
    public object tryGetVal(object csvVal , Schema.DescribeFieldResult describeResult){

        System.debug('copying data into field : ' + describeResult.getName() + ' value ' + csvVal);
        switch on describeResult.getType() {
            when  STRING , PICKLIST , EMAIL , TEXTAREA, URL , PHONE  {
                return String.valueOf(csvVal);
                
            }
            when INTEGER {
                return Integer.valueOf(csvVal);
            }
            
            when DOUBLE{

                return Double.valueOf(string.valueOf(csvVal));
            } 
            
            when DATE{
                string dateString = String.valueOf(csvVal);
                List<string> dateSplit = dateString.split('/');
                //yyyy-MM-dd
                string newDateString = dateSplit[2]+'-'+dateSplit[1] + '-' + dateSplit[0];
                return Date.valueOf(newDateString);
            }
            when DATETIME{
                return Datetime.valueOf(string.valueOf(csvVal));
            }
            
            when CURRENCY {
                return Decimal.valueOf(Double.valueOf(String.valueOf(csvval)));
            }
            // reference 
            when else {
                return String.valueOf(csvVal);
            }
        }
    }



    
}