import { LightningElement , api , track,wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCSVSourceFieldOptions from '@salesforce/apex/CsvParserLwcController.getCSVSourceFieldOptions';
import getInteractionFieldListOptions from '@salesforce/apex/CsvParserLwcController.getInteractionFieldListOptions';
import getAllSObjectsList from '@salesforce/apex/CsvParserLwcController.getAllSObjectsList';
import getRecordTypesFor from '@salesforce/apex/CsvParserLwcController.getRecordTypesFor';
import getCsvConfig from '@salesforce/apex/CsvParserLwcController.getCsvConfig';
import saveOrUpdateConfig from '@salesforce/apex/CsvParserLwcController.saveOrUpdateConfig';

// add ability to save field mapping as a configuration metadata record
export default class CsvDataMapping extends LightningElement {


    @api
    configId

    @track
    fieldMap = {}
    @track
    lookupSelection = []
    
    @track
    csvMappingConfig = {}
    
    errorMessages =[];
    
    
    
    objectTargetName
    selectedSourceField;
    selectedDestinationField;
    selectedSobject ='';
    selectedParentSObject;
    selectedLookupCsvField;
    selectedParentIdentifierField
    selectedRecordTypeId;
    
    hasLookup = false;
    hasRecordTypes = false;
    objectSelectionDisabled = false;

    @track
    csvHeaders = [];

    @track
    sobjectNames =[]

    @track 
    recordTypes = []
    
    @track
    sobjectFields = []
    @track
    sobjectLookupFields =[]


    @wire(getCSVSourceFieldOptions,{csv:localStorage.getItem('csvFile')})
    loadSourceOptions({error,data}){
        if(error){
            console.log('error loading headers ' ,error)
            const event = new ShowToastEvent({
                title:'Error Loading Headers',
                variant:'error',
                message: error.body.message
            })
            this.dispatchEvent(event)
        }else if(data){
            let options =[];
            for(let item of data){
               options =[ ...options, {label: item.name , value :item.value}];
            }
            this.csvHeaders = options;
        }
    }

    @wire(getAllSObjectsList)
    loadSobjects({error,data}){
        if(error){
            console.log('error loading Sobject Lists ' ,error)
            const event = new ShowToastEvent({
                title:'Error While Loading Sobect List',
                variant:'error',
                message: error.body.message
            })
            this.dispatchEvent(event)
        }else if(data){
            let options =[];
            //console.log(JSON.stringify(data))
            for(let item of data){
               options =[ ...options, {label: item.name , value :item.value}];
            }
            this.sobjectNames = options;
        }
    }

    @wire(getRecordTypesFor,{sobjectApiName : '$selectedSobject'})
    getRecordTypes({error, data}){
        if(error){
            const evt = new ShowToastEvent({
                variant:'error', message:error.body?.message , title:'An Error Occured while loading Record Types'
            })
            this.dispatchEvent(evt);
            this.hasRecordTypes = false;
        }else if(data){
           // console.log('record types ' , data)
            let options = []
            for(let item of data){
                options = [...options ,{label: item.name , value: item.value}]
            }
            this.recordTypes =[...options]
            this.hasRecordTypes = options.length > 0;
        }

    }


    @wire(getCsvConfig,{configId : '$configId'})
    loadConfigById({error, data}){
        if(error){
            const event = new ShowToastEvent({
                title:'Error While Loading Selected Configuration',
                variant:'error',
                message: error.body.message
            })
            this.dispatchEvent(event)
            console.error(error)
        }else if(data){
            const event = new ShowToastEvent({
                title:'Loading Configuration',
                variant:'info',
                message: 'Loading Configuration'
            })
            this.dispatchEvent(event)
            this.csvMappingConfig = data;
            this.loadDefaults();


            const event2 = new ShowToastEvent({
                title:'Loading Configuration Success',
                variant:'success',
                message: 'Configuration Loaded Successfully'
            })
            this.dispatchEvent(event2)
        }

    }
    


    @api
    getErrorMessages(){
        console.log('error messages mapping : ', this.errorMessages)
        return [...this.errorMessages];
    }



    // will run validation on the field mappings to confirm that what's mapped is accurate
    @api 
    validate(){
        let valid = true;
        this.errorMessages = [];
        if(!this.fieldMap || Object.keys(this.fieldMap).length < 0){
            valid = false;
            this.addErrorMessage('There is No Field Map. Please Map fields');
        }
        if(this.hasRecordTypes && !this.selectedRecordTypeId){
            valid = false;
            this.addErrorMessage('Object has Record Types but no record type was selected')

        }
        if(this.hasLookup && this.lookupSelection.length <= 0){
            valid = false;
            this.addErrorMessage('Lookup indicator selected but No Look Up Configuration has been added.')
        }
        console.log(valid)
        return valid ;
    }

    @api
    get_Data(){
        //should return field mappings (after validation).
        return {
            fieldMap : this.fieldMappingData,
            sobjectApiName : this.selectedSobject,
            lookupConfigs:this.lookupSelection,
            recordTypeId : this.selectedRecordTypeId
        }
    }

    @api
    getNextPageIncrement(){
        return 1;
    }

    get sourceCsvOptions(){
        return this.csvHeaders;
    }
    get destinationFieldOptions(){
        return this.sobjectFields;
    }
    get sourceObjectOptions(){
        return this.sobjectNames;
    }
    get recordTypeOptions(){
        return this.recordTypes;
    }
    get hasParents(){
        return this.hasLookup
    }
    get disableSelectObject(){
        return this.objectSelectionDisabled;
    }
    get displayRecordTypeSelection(){
        return this.hasRecordTypes;
    }


    get lookupFieldOptions(){
        return this.sobjectLookupFields;
    }
    get columnNames(){
        return [{
                    label:'Source Field', fieldName:'source', type:'text'
                },{
                    label:'Destination Field', fieldName:'destination',type:'text'
                },
                {
                    type:'action',
                    typeAttributes: { rowActions: [{label:'Delete Selection' , name:'delete'}]}
                }
    
        ]
    }

    get lookupColumnNames(){
        return [{
            label:'Lookup SObject', fieldName:'lookupObject', type:'text'
        },{
            label:'SF Lookup Field', fieldName:'sflookupField',type:'text'
        },{
            label:'Csv Lookup Column', fieldName:'lookupField',type:'text'
        },{
            type:'action',
            typeAttributes: { rowActions: [{label:'Delete Selection' , name:'deletelookup'}]}
        }

]
    }

    //returns the field map to the lwc data table
    get fieldMappingData(){

        let fieldMapData = []
        for(let key of Object.keys(this.fieldMap)){
            fieldMapData = [...fieldMapData ,{source:key , destination : this.fieldMap[key]}]
        }
        return fieldMapData;
    }

    // returns the lookup selections  to the lwc data table
    get lookupFieldMappingData(){
        return [...this.lookupSelection];
    }

    get computeLayoutSizeUpper(){
        return this.hasRecordTypes ? 3 : 4;
    }

    
    onChangeField(e){
        if(e.target.name ==='source'){
            this.selectedSourceField = e.detail.value;
            localStorage.setItem('selectedSource', e.detail.value)
        }else if(e.target.name ==='recordType'){
            this.selectedRecordTypeId = e.detail.value;
            localStorage.setItem('selectedRecordType', e.detail.value)
        }else if(e.target.name ==='destination'){
            this.selectedDestinationField = e.detail.value;
            localStorage.setItem('selectedDestination', e.detail.value)
        }else if(e.target.name === 'lookup'){
            this.selectedLookupCsvField = e.detail.value;
            localStorage.setItem('lookupField', e.detail.value)
        }else if(e.target.name === 'sflookup'){
            this.selectedParentIdentifierField = e.detail.value;
            localStorage.setItem('sflookupField', e.detail.value)
        }else if(e.target.name==='hasparent'){
            this.hasParent = e.detail.checked;
        }

    }

    addErrorMessage(message){
        let copy = [...this.errorMessages , message];
        this.errorMessages =[...copy];
        
    }
    handleObjectTargetOptionLoad(options){
        if(this.objectTargetName === 'main'){
            this.sobjectFields = options;
        }else{
            this.sobjectLookupFields = options;
        }
        
    }

    setValueOnConfigObject(key, value){
         let configCopy = {...this.csvMappingConfig}
         configCopy[key] = value;
         console.log(JSON.stringify(configCopy))
         this.csvMappingConfig = configCopy;
    }
    
    onChangeObject(e){
        this.objectTargetName = e.target.name;
        if(e.target.name === 'main'){
            this.selectedSobject = e.detail.value;
            this.setValueOnConfigObject('destinationObject', e.detail.value);

        }else if(e.target.name ==='parent'){
            this.selectedParentSObject = e.detail.value
        }


        getInteractionFieldListOptions({objectApiName : e.detail.value})
        .then(res => {
            let options =[];
            for(let item of res){
                options =[ ...options, {label: item.name , value :item.value}];
            }
            
            if(this.objectTargetName ==='main'){
                this.sobjectFields = options;
                this.objectSelectionDisabled = true;
            }else{
                this.sobjectLookupFields = options;
            }

        }).catch( err=>{
            console.log('error loading sobject fields ' , err)
        })

    
        
    }

    copyFieldMapToConfig(){
        
        let newFieldMap =[]
        const fieldMapCopy = {...this.fieldMap}
        for(let source of Object.keys(fieldMapCopy)){
            //console.log(source, fieldMapCopy[source])
            newFieldMap =[...newFieldMap, {source: source , destination:fieldMapCopy[source]}]
        }
        this.setValueOnConfigObject('fieldMaps',newFieldMap)
    }
    


    



    addSelection(){
        let selection = {...this.fieldMap}
        selection[this.selectedSourceField] = this.selectedDestinationField;
        this.fieldMap = {...selection};
        this.copyFieldMapToConfig();
        
    }

    addLookUpSelection(){
        let updatedData = [...this.lookupSelection]
        updatedData =[...updatedData ,{lookupField:this.selectedLookupCsvField , lookupObject : this.selectedParentSObject , sflookupField:this.selectedParentIdentifierField}]
        this.lookupSelection =[...updatedData]
        this.setValueOnConfigObject('lookupConfigs',[...updatedData])
        
    }

    // load object , load field map , load lookup configs
    loadDefaults(){
        
        this.selectedSobject = this.csvMappingConfig['destinationObject'];
        this.selectedRecordTypeId = this.csvMappingConfig['recordTypeId'];
        this.onChangeObject({target:{name:'main'}, detail:{value : this.csvMappingConfig['destinationObject'] }})
        if(this.csvMappingConfig['fieldMaps']){
            const existingFieldMap =[... this.csvMappingConfig['fieldMaps']]
            const convertedFieldMap = {}
            for(let fMap of existingFieldMap){
                convertedFieldMap[fMap.source] = fMap.destination;
            }
            this.fieldMap = {...convertedFieldMap}

        }

        if(this.csvMappingConfig['lookupConfigs']){
            this.hasLookup = true;
            this.lookupSelection = [...this.csvMappingConfig['lookupConfigs']];


        }
        
    }

    toggleHasParents(e){
        this.hasLookup = e.target.checked;
        this.setValueOnConfigObject('hasLookup',e.target.checked)
        
    }

    saveAsConfig(){
        //console.log('saving as config !!!')
        //console.log(JSON.stringify(this.csvMappingConfig));
        const configCopy = {...this.csvMappingConfig}
        saveOrUpdateConfig({record:configCopy}).then(res =>{
            console.log('config record Id ' , res)
            this.setValueOnConfigObject('configId',res);
            const toastEvent = new ShowToastEvent({title:'Configuration Saved', message:'The Configuration record has been Updated', variant:'success' })
            this.dispatchEvent(toastEvent);
        }).catch(error =>{
            const event = new ShowToastEvent({
                title:'An error occured while saving config record' ,
                variant:'error',
                message: error.body?.message
            })
            this.dispatchEvent(event)
            console.log('an error occured while saving config record' , error.body)
        })
    }


    deleteRow(row){
        const rowData = {...row}
        const allDataCopy = {...this.fieldMap} 
        console.log('all data' , allDataCopy)
        delete allDataCopy[rowData.source];
        this.fieldMap ={...allDataCopy};
        console.log('after delete ', allDataCopy)


    }
    deleteLookupRow(row){
        const rowData = {...row}
        const allDataCopy = [...this.lookUpSelection]
        this.lookupSelection = allDataCopy.filter(row => {
            if(row.lookupObject !== rowData.lookupObject){
                return row;
            }
        })

    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        //console.log('actionname' ,actionName);
        const row = event.detail.row;
       
        switch (actionName) {
            case 'delete':
                this.deleteRow(row);
                break;
            case 'deletelookup':
                this.deleteLookupRow(row);
                break;
            default:
        }
    }

    

}