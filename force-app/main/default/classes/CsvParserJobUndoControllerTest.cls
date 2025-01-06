@suppressWarnings('pmd')
@isTest
public with sharing class CsvParserJobUndoControllerTest {
    
    @IsTest
    static void testundoController(){
        
        Test.startTest();
        Test.setCurrentPage(Page.CsvParserJobUndo);
        CsvParserJobUndoController ct = new CsvParserJobUndoController(null);
        ct.undo();
        ct.navToParserHomePage();

        Test.stopTest();
        
    }
}