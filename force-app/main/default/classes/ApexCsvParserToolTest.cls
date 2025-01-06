@suppressWarnings('pmd')
@isTest
public without sharing class ApexCsvParserToolTest {
    
    private static final string CSV_FILE ='Name,Email';

    @IsTest
    static void testGoodCSV(){
        string CSV_FILE ='Name,Email,Address\nSoji,Sojman007@gmail.com,"Morohunfola Street,Opic"\nSoji2,Sojman008@gmail.com,new address';
        Test.startTest();
        ApexCsvParserTool tool = new ApexCsvParserTool(CSV_FILE);
        tool.run();
        tool.getAllRows();
        tool.getAllValuesAtColumn('Name');
        tool.getDataAtRow(1);
        tool.getDataInRange(0, 1);
        tool.getLinkedList();
        tool.getHeaders();
        Blob myBlob = Blob.valueOf(CSV_FILE);
        ApexCsvParserTool tool2 = new ApexCsvParserTool(myBlob);
        Test.stopTest();
    }




}