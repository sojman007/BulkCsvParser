public without sharing class LwcDtos {
    
    public class Option{
        @AuraEnabled
        public string name {get;set;}
        @AuraEnabled
        public string value {get;set;}

        public Option(string n , string v){
            name = n;
            value = v;
        }
    }

    public class LookUpConfig{
        @auraEnabled
        public string lookupObject {get;set;}
        @auraEnabled
        public string sflookupField {get;set;}
        @auraEnabled
        public string lookupField {get;set;}
    }
    
    public class FieldMap {
        @auraEnabled
        public string source {get;set;}
        @auraEnabled
        public string destination {get;set;}
    }
    public class CsvConversionResult{
        @auraEnabled
        public boolean success {get;set;}

        @auraEnabled
        public List<Sobject> records {get;set;}


        public CsvConversionResult setSuccess(boolean suc){
            success = suc;
            return this;
        }
        public CsvConversionResult setRecords(List<Sobject> rec){
            records = new List<Sobject>(rec);
            return this;
        }
    }

    public class CsvConfigurationRecord{
        @auraEnabled
        public string configId {get;set;}
        @auraEnabled
        public string recordTypeId {get;set;}
        @auraEnabled
        public string destinationObject {get;set;}
        @auraEnabled
        public boolean hasLookup {get;set;}
        @auraEnabled
        public string configName {get;set;}
        @auraEnabled
        public List<LwcDtos.LookupConfig> lookupConfigs {get;set;}
        @auraEnabled
        public List<LwcDtos.FieldMap> fieldMaps {get;set;}

        public CsvConfigurationRecord(){
            configId ='';
            configName='New Config - ' + String.valueOfGmt(Datetime.now());
            destinationObject ='';
            hasLookup = false;
            lookupConfigs = new List<LwcDtos.LookUpConfig>();
            fieldMaps = new List<LwcDtos.FieldMap>();
        }

        public CsvConfigurationRecord(Csv_Config__c csvConfig){
            this.configId = csvConfig.Id;
            this.recordTypeId = csvConfig.Record_Type_Id__c;
            this.destinationObject = csvConfig.Sobject_Api_Name__c;
            this.hasLookup = csvConfig.Has_Lookups__c;
            this.configName = csvConfig.Name;
            lookupConfigs = new List<LwcDtos.LookUpConfig>();
            fieldMaps = new List<LwcDtos.FieldMap>();
            if(csvConfig.Field_Map__c != null){
                loadFieldMap(csvConfig.Field_Map__c);
            }
            if(csvConfig.Lookup_Config__c != null){
                loadLookupConfigs(csvConfig.Lookup_Config__c);
            }



        }

        public Csv_Config__c toRecord(){
            Csv_Config__c configR = new Csv_Config__c(
                Sobject_Api_Name__c = destinationObject,
                Has_Lookups__c = hasLookup,
                Name = configName
            );
            if(String.isNotBlank(configId)){
                configR.Id = configId;
            }
            if(String.isNotBlank(recordTypeId)){
                configR.Record_Type_Id__c = recordTypeId;
            }

            string lookUpConfigString = '';
            string fieldMapString ='';

            for(LwcDtos.LookUpConfig lcfg : lookupConfigs ){
                lookUpConfigString += String.join(new List<String>{lcfg.lookupObject,lcfg.sflookupField,lcfg.lookupField },':')+',';
            }
            lookUpConfigString = lookUpConfigString.removeEnd(',');
            configR.Lookup_Config__c = lookUpConfigString;
            for(LwcDtos.FieldMap fMap : fieldMaps ){
                fieldMapString += String.join(new List<String>{fMap.source , fMap.destination}, ':') + ',';
            }
            fieldMapString = fieldMapString.removeEnd(',');
            configR.field_map__c = fieldMapString;

            return configR;


        }

        private void loadFieldMap(string fieldMapString){
            for(string fieldMap : fieldMapString.split(',')){
                LwcDtos.Fieldmap fMap = new LwcDtos.FieldMap();
                fMap.destination = fieldMap.substringAfter(':').trim();
                fMap.source = fieldMap.substringBefore(':').trim();
                fieldMaps.add(fMap);
            }
        }

        private void loadLookupConfigs(string configString){
            for(string config : configString.split(',')){
                List<string> splitConfig = config.split(':');
                LwcDtos.LookUpConfig lookUpConfigObj = new LwcDtos.LookUpConfig();
                lookUpConfigObj.lookupObject = splitConfig[0];
                lookUpConfigObj.sflookupField = splitConfig[1];
                lookUpConfigObj.lookupField = splitConfig[2];
                lookupConfigs.add(lookUpConfigObj);
            }
        }





    }


}