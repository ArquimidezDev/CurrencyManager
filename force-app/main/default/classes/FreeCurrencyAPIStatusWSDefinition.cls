/**
 * @description       : Class used as wrapper to desserialize WS data from Free Currency API Status request
 * @author            : Arquimidez Mora
 * @group             : 
 * @last modified on  : 04-29-2025
 * @last modified by  : Arquimidez Mora
 * Modifications Log
 * Ver   Date         Author            Modification
 * 1.0   04-29-2025   Arquimidez Mora   Initial Version
**/
public without sharing class FreeCurrencyAPIStatusWSDefinition {
    @AuraEnabled @InvocableVariable
    public QuotasData Quotas;

    public static FreeCurrencyAPIStatusWSDefinition parse(string strJsonPayload) {
        return (FreeCurrencyAPIStatusWSDefinition)System.JSON.deserialize(strJsonPayload, FreeCurrencyAPIStatusWSDefinition.class);
    }

    public class QuotasData{
        public MonthData Month;
    }

    public class MonthData{
        @AuraEnabled
        public integer total;
        
        @AuraEnabled
        public integer used;
        
        @AuraEnabled
        public integer remaining;
    }
}