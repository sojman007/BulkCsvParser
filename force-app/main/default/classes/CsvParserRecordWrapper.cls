public without sharing class CsvParserRecordWrapper {
    
    private integer nodeIndex;
    private Sobject record;
    
    public CsvParserRecordWrapper(Sobject rec , integer ind) {
        record = rec;
        nodeIndex = ind;

    }

    public integer getIndex(){
        return nodeIndex;
    }

    public Sobject getRecord(){
        return record;
    }



    public static map<integer , Sobject> listToRecordmap(List<CsvParserRecordWrapper> records){
        map<integer,Sobject> values = new map<integer , Sobject>();
        for(CsvParserRecordWrapper rec : records){
            values.put(rec.getIndex(), rec.getRecord());
        } 
        return values;
    }
    public static map<integer , CsvParserRecordWrapper> listToWrapperMap(List<CsvParserRecordWrapper> records){
        map<integer,CsvParserRecordWrapper> values = new map<integer , CsvParserRecordWrapper>();
        for(CsvParserRecordWrapper rec : records){
            values.put(rec.getIndex(), rec);
        } 
        return values;
    }
}