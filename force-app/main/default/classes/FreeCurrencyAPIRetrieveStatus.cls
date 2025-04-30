/**
 * @description       : 
 * @author            : Arquimidez Mora
 * @group             : 
 * @last modified on  : 04-29-2025
 * @last modified by  : Arquimidez Mora
 * Modifications Log
 * Ver   Date         Author            Modification
 * 1.0   04-29-2025   Arquimidez Mora   Initial Version
**/
global with sharing class FreeCurrencyAPIRetrieveStatus {
    @InvocableMethod
    public static List<FCAStatusResults> GetStatusResults(List<SobjectObject> lstResponses){
        String strResponse = System.JSON.Serialize(lstResponses[0]);
        FreeCurrencyAPIStatusWSDefinition objStatusResponse = FreeCurrencyAPIStatusWSDefinition.parse(strResponse);

        FCAStatusResults objResult = new FCAStatusResults();
        objResult.objStatusResult = objStatusResponse;
        return new List<FCAStatusResults>{objResult};
    }
    
    global class FCAStatusResults {
        @InvocableVariable
        global FreeCurrencyAPIStatusWSDefinition objStatusResult;
    }
}