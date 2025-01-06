import { LightningElement  } from 'lwc';
import { getNavParams } from 'c/csvParserHelpers';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

window.onbeforeunload = ()=> {
    localStorage.clear()
    
}

export default class CsvParserLwc extends LightningElement {

    pageNumber = 1;
    

    state = {
        mappingType:'null'
    }

    connectedCallback(){
        console.log('component reconnected');
    }


    get parserTitleText(){
        return "Stanbic IBTC Bulk Interactions Upload";
    }

    get uploadAndConfigPage(){
        return this.pageNumber == 1;
    }

    get manualMappingPage(){
        return this.pageNumber == 2;
    }

    get dataPreviewPage(){
        return this.pageNumber == 3;
    }

    get mappingIsManual(){
        return this.state.mappingType == 'null'
    }

    get displayPreviousButton(){
        const navParams = getNavParams(this.pageNumber);
        return navParams.backward;
    }

    get displayNextButton(){
        const navParams = getNavParams(this.pageNumber);
        return navParams.forward;
    }

    get fieldMap(){
        let fM = {}
        //console.log(this.state)
        for(let field of this.state.fieldMap){
            fM[field.source] = field.destination
        }
        return fM;
    }

    get sobjectApiName(){
        return this.state.sobjectApiName;
    }

    get csvFile(){
        return this.state.csvFile;
    }
    get lookupConfigs(){
        return this.state.lookupConfigs;
    }

    get recordTypeId(){
        return this.state.recordTypeId;
    }

    get configId(){
        return this.state.mappingType;
    }


    navigateToNext(){
        const navParams = getNavParams(this.pageNumber);
        const templateComponent = this.template.querySelector(navParams.componentDomId);
        
        if(navParams.forward === true){
            if(templateComponent.validate()){
                const data = templateComponent.get_Data();
                this.state = {...this.state , ...data}
                this.pageNumber  += templateComponent.getNextPageIncrement();
            }else{
                const errorMessages = [...templateComponent.getErrorMessages()];
                for(let message of errorMessages){
                    console.log(message);
                    const evt = new ShowToastEvent({
                        title:'Validation Error',
                        message : message,
                        variant:'warning'
                    })
                    this.dispatchEvent(evt);
                }
            }
        }
            
    }

    navigateToPrevious(){
        const navParams = getNavParams(this.pageNumber);
        
        if(navParams.backward === true){
            this.pageNumber -= 1;
        }
    }

    



}