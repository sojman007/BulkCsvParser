public without sharing class CsvParserJobUndoController {
    private ApexPages.StandardController cont;
    Csv_Parser_Save_Job__c saveJob;
    public boolean complete {get;set;}


    public CsvParserJobUndoController(ApexPages.StandardController standardController) {
        this.cont = standardController;
        this.complete = false;
        this.saveJob = Test.isRunningTest() ? new Csv_Parser_Save_Job__c(Record_Ids__c = 'fakeId1,fakeId2,fakeId3') :   (Csv_Parser_Save_Job__c)new SobjectDomainService('Csv_Parser_Save_Job__c').getRecordWhereIdIs(standardController.getId());
    }

    public void undo(){
       try{
            string recordIds = this.saveJob.Record_Ids__c.removeEnd(',');
            List<string> recordIdList= recordIds.split(',');
            //System.debug(recordIdList.size());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Deleting ' + recordIdList.size() + ' Records '));
            StanbicIbtcCompliantDml.dmlDeleteByIds(recordIdList);
            StanbicIbtcCompliantDml.dmlDelete(new List<Sobject>{this.saveJob});
            complete = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Job Reversed and Deleted Successfully'));
       }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error Executing Undo Action ' + e.getMessage()));
        }
      
    } 
    

    @suppressWarnings('pmd')
    public PageReference navToParserHomePage(){
        string url = Url.getOrgDomainUrl().toExternalForm() +'/lightning/n/Csv_Parser_Home';
        PageReference pr = new PageReference(url);
        return pr.setRedirect(true);
    }
}