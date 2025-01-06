import { LightningElement , wire , track , api } from 'lwc';
import { loadFile } from 'c/csvParserHelpers';
import getCsvConfigOptions from '@salesforce/apex/CsvParserLwcController.getCsvConfigOptions';

export default class CsvUploadAndConfig extends LightningElement {


    csvFile;
    selectedOption = "null";
    fileName;

    @track
    errorMessages = []
    
    @track
    mdtOptions =[{
        label:"None" , value:"null"
    }]
    renderedCallback(){
        //console.log('rendered')
        this.csvFile = localStorage.getItem('csvFile') ?? undefined;
        this.fileName = localStorage.getItem('fileName') ?? '';
    }
   

    @wire(getCsvConfigOptions)
    onLoadConfig({error, data}){
        if(data){
            console.log('opt',data)
            let opt = [...this.mdtOptions]
            for(let item of data){
                opt = [...opt ,{label: item.name , value : item.value}]
            }
            //console.log( data,JSON.stringify(opt))
            this.mdtOptions = opt;
        }else if(error){
            console.log('error' , error);
        }

    }


    get options(){
        return this.mdtOptions;
    }

    handleOptionSelected(event){
        // publish an event to be handled by parent component.
        console.log('selected ', event.detail.value);
        this.selectedOption = event.detail.value;
    }

   async handleFileUploaded(event){
        //console.log('uploaded files ' ,event.target.files , event.detail.value);
        const file = event.detail.files[0]
        
        this.fileName = event.detail.value;

        const extractedCSV  = await loadFile(file);
        //console.log(extractedCSV);
        this.csvFile = extractedCSV;
        localStorage.setItem('csvFile',extractedCSV);
        localStorage.setItem('fileName',event.detail.value);
    }

    @api 
    validate(){
        let valid = true;
        if(!this.selectedOption){
            valid = false;
            this.addErrorMessage('No Option Selected.');
        }
        if(!this.csvFile){
            valid = false;
            this.addErrorMessage('No Csv File Uploaded');
        }
        if(!this.fileName){
            valid = false;
            this.addErrorMessage('No Provided Csv File Name');
        }

        return valid;
    }

    @api
    get_Data(){
        return {
            csvFile : this.csvFile,
            fileName : this.fileName,
            mappingType : this.selectedOption
        }
    }

    @api
    getNextPageIncrement(){
        return 1;
    }

    @api
    getErrorMessages(){
        const messages =[... this.errorMessages]
        return messages;
    }


    
    addErrorMessage(message){
        const errors = [...this.errorMessages,message]
        this.errorMessages =[...errors];

    }




}