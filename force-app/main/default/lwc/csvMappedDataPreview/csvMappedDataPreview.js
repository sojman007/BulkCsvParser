import { LightningElement, wire, api , track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import convertDataFromCsv from '@salesforce/apex/CsvParserLwcController.convertDataFromCsv';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import getListViewPath from '@salesforce/apex/CsvParserLwcController.getListViewPath';

export default class CsvMappedDataPreview extends NavigationMixin(LightningElement) {

    @api
    sobjectApiName
    @api
    csvFile
    @api
    fieldMap
    @api
    lookUpConfigs
    
    @api
    recordTypeId
    
    formats =[ 'font', 'size', 'bold', 'italic', 'background', 'code', 'code-block', 'color']

    
    
    
    processingStatus ='PROCESSING';
    displayDoneButton = false;
    listViewPath ='';
    @track 
    batchUpdate = {
        failedRecords : 0 , passedRecords : 0
    }
    

    @track
    conversionUpdate = {
        processedRecords :0 , failedRecords:0, errorMessages :''
    }

    subscription={}
    channelName ='/event/Csv_Parser_Notification__e';
    
    connectedCallback(){
        subscribe(this.channelName , -1 , this.handlePlatformEventMessage.bind(this)).then(response =>{
            this.subscription = response;
        });
    }
    
    

        
    
    disconnectedCallback(){
        unsubscribe(this.subscription);
    }

    @wire(convertDataFromCsv,{csvFile:'$csvFile', fieldMappings:'$fieldMap' , lookupConfigs:'$lookUpConfigs', objectApiName:'$sobjectApiName', recordTypeId :'$recordTypeId'})
    onConvert({error,data}){
        if(error){
            const event = new ShowToastEvent({
                title:'Record Translation Error',
                variant:'error',
                message: error.body.message
            })
            this.dispatchEvent(event)
        }else if(data){
            
            const event = new ShowToastEvent({
                title:'Csv Parser Extraction',
                variant:'info',
                message: 'Record Extraction Process Initiated'
            })
            this.dispatchEvent(event)
            //this.dataMappingResponse = data.records;
        }
    }


    handlePlatformEventMessage(message){
        const payload = message.data.payload;
        //console.log('payload' , JSON.parse(JSON.stringify(payload)));
        
        if(payload.Event_Type__c === 'EXTRACT_START'){
            this.processingStatus ='EXTRACTING DATA FROM CSV';
        }
        if(payload.Event_Type__c === 'EXTRACT_END'){
            this.processingStatus ='CSV DATA EXTRACTION COMPLETE';
        }
        if(payload.Event_Type__c === 'CONVERT_START'){
            this.processingStatus ='CONVERTING DATA TO SALESFORCE RECORDS';
        }
        if(payload.Event_Type__c ==='CONVERT_END'){
            this.processingStatus ='DATA CONVERSION TO SALESFORCE RECORDS COMPLETE';
            const parsedPayload = JSON.parse(payload.Message_Json__c)
            const toastEvent = new ShowToastEvent({title:'Conversion Complete' , variant:parsedPayload.status , message:parsedPayload.message});
            this.dispatchEvent(toastEvent);
            
            if(parsedPayload.status==='error'){
                this.displayDoneButton = true;
            }
            
        }
        if(payload.Event_Type__c ==='CONVERT_PROGRESS'){
            this.processingStatus ='CONVERTING CSV DATA TO SALESFORCE RECORDS BATCH BY BATCH';
            const payloadParsed = JSON.parse(payload.Message_Json__c);
            this.conversionUpdate = payloadParsed;
        }

        if(payload.Event_Type__c === 'BATCH_START'){
            this.processingStatus = 'SAVING RECORDS TO DB IN BATCH';
            const toastEvent = new ShowToastEvent({title:'Batch Record Save Start' , variant:'Info' , message:'Saving Successfully Parsed Records In Batches to the Database'});
            this.dispatchEvent(toastEvent);

        }

        if(payload.Event_Type__c ==='BATCH_PROGRESS'){
            const payloadParsed = JSON.parse(payload.Message_Json__c);
            this.batchUpdate = payloadParsed;
        }

        if(payload.Event_Type__c === 'BATCH_ERROR'){
            const parsedPayload = JSON.parse(payload.Message_Json__c)
            const toastEvent = new ShowToastEvent({title:'Batch Record Save Error' , variant:'error' , message:parsedPayload.error});
            this.dispatchEvent(toastEvent);

        }


        if(payload.Event_Type__c === 'BATCH_END'){
            this.processingStatus ='BATCH DB RECORD SAVE COMPLETE';
            const parsedPayload = JSON.parse(payload.Message_Json__c)
            this.displayDoneButton = true;
            const event = new ShowToastEvent({
                title:'Record Save Process Complete',
                variant:'success',
                message: `${parsedPayload.success} Records Saved Successfully. ${parsedPayload.failed} Records Failed`
            })
            this.dispatchEvent(event)
            getListViewPath({objectApiName: this.sobjectApiName}).then(res => this.listViewPath = res).catch(error =>{
                alert(`An error occured ${error.body?.message}`); 
            })
            
        }

    }

    
    get sobjectName(){
        return this.sobjectApiName;
    }

    
    get done(){
        return this.displayDoneButton;
    }
    
    

    get fileProcessingStatus(){
        return this.processingStatus;
    }
    get showTableData(){
        return true;
    }

    get totalNumberOfRecords(){
        return this.conversionUpdate.processedRecords;
    }

    get failedRecordCount(){
        return this.conversionUpdate.failedRecords;
    }

    get errorStream(){
        return this.conversionUpdate.errorMessages;

    }

    get dbFailCount(){
        return this.batchUpdate.failedRecords;
    }

    get dbSuccessCount(){
        return this.batchUpdate.passedRecords;
    }


    handleGoToRecordListView(){
        window.location.href = this.listViewPath;
    }



    handleErrorStreamChange(event){
        const errorMessage = this.conversionUpdate.errorMessages;
        this.conversionUpdate.errorMessages = errorMessage;
    }


    
}