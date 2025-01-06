@suppressWarnings('pmd')
public without sharing class ApexCsvParserTool {
    
    private string csvFile;
    private string cleanedData;
    private boolean cleaned;

    private static final string COMMA ='<COMMA>';
    private static final string CARRIAGE_RETURN ='<CARRIAGE_RETURN>';
    private static final string NEW_LINE ='<NEW_LINE>';


    private map<integer,String> headers = new map<integer,String>();
    private List<map<string,Object>> data = new List<Map<String,Object>>();

    public ApexCsvParserTool(string csvFile) {
        this.csvFile = csvFile;
    }

    public ApexCsvParserTool(Blob csvBlob) {
        this.csvFile = csvBlob.toString();
    }


    public void run(){
        try{
            this.cleanData();
            this.loadHeaders();
            this.loadData();
            cleaned = true;
        }catch(Exception e){
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            cleaned = false;
        }
    }


    private void cleanData(){
        string remainderString = this.csvFile;
        string csvLines = csvFile;

        if(String.isNotBlank(csvFile)){
            boolean hasDoubleQuotes = String.isNotBlank(remainderString) ? remainderString.contains('"') :false;
            while(hasDoubleQuotes){
                string subString = remainderString.substringBetween('"','"');
                remainderString = remainderString.substringAfter(subString+'"');
                string newSubString = subString.replaceAll('\n',NEW_LINE).replaceAll('\r',CARRIAGE_RETURN)
                    .replaceAll(',','COMMA');
                csvLines = csvLines.replace(subString,newSubString);
                hasDoubleQuotes = String.isNotBlank(remainderString) ? remainderString.contains('"') :false;
                
            }

            this.cleanedData =  csvLines;
        }
    }

    private void loadHeaders(){
        System.debug(cleanedData.split('\\n')[0]);
        List<String> splitHeader = cleanedData.split('\\n')[0].split(',');
        for(integer i =0; i < splitHeader.size(); i++ ){
            headers.put(i, splitHeader.get(i));
        }
}

    private void loadData(){
        List<String> splitLines = cleanedData.split('\n');
        map<String,Object> transformedRecord;

        for(integer i =1; i < splitLines.size(); i++ ){
           string line = splitLines[i];
           List<string> record = line.split(',');
           transformedRecord = new map<string,Object>();
           for(integer j = 0; j < record.size() ; j++){
                string value = record[j];
                transformedRecord.put(headers.get(j), value.replaceAll(COMMA, ',').replaceAll(CARRIAGE_RETURN, '\r').replaceAll(NEW_LINE, '\n'));
            }
            data.add(transformedRecord);
        }

    }

    public List<String> getHeaders(){
       return this.headers.values();
    }

    public list<map<string,Object>> getAllRows(){
        return this.data;
        
    }

    public List<String> getAllValuesAtColumn(string columnName){
        List<String>  values = new List<String>();
        for(map<string,Object> row : getAllRows()){
            values.add(String.valueOf(row.get(columnName)));
        }

        return values;
    }

    public map<string,Object> getDataAtRow(integer i){
        return this.data.get(i);
    }

    public List<Map<string,object>> getDataInRange(integer start , integer endR){
        List<Map<string,object>> rangedData = new List<Map<string,object>>();
        for(integer i = start; i <= endR ; i++){
            rangedData.add(this.data.get(i));
        }
        return rangedData;
    }

    public CsvDataExtractorLinkedList getLinkedList(){
        List<map<string,Object>> allRows = getAllRows();
        CsvDataExtractorLinkedList ll = new CsvDataExtractorLinkedList();
        for(map<string,Object> entry : getAllRows()){
            ll.appendNode(new CsvDataExtractorLLNode().setData(entry));
        }

        return ll;

    }


}