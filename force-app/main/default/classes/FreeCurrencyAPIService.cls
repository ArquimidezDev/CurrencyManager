/**
 * @description       : Service methods for Free Currency API related operations against SF currency records
 * @author            : Arquimidez Mora
 * @group             : 
 * @last modified on  : 04-30-2025
 * @last modified by  : Arquimidez Mora
 * Modifications Log
 * Ver   Date         Author            Modification
 * 1.0   04-29-2025   Arquimidez Mora   Initial Version
**/
public with sharing class FreeCurrencyAPIService {
    
    /**
    * @description Gets the metadata records where the APIKey from Free Currency API is stored
    * @author Arquimidez Mora | 04-30-2025 
    * @return Free_Currency_API_Key__mdt 
    **/
    public static Free_Currency_API_Key__mdt retrieveAPIKey(){
        Free_Currency_API_Key__mdt objAPIKeyMDT = Free_Currency_API_Key__mdt.getInstance('FreeCurrencyAPI');
        return objAPIKeyMDT;
    }


    /**
    * @description Stores Currency data to SF
    * @author Arquimidez Mora | 04-30-2025 
    * @param List<Currency__c> lstCurrencyData 
    * @param List<Currency_Exchange_Rate__c> lstCurrencyRateData 
    * @return boolean 
    **/
    public static boolean saveCurrencies(List<Currency__c> lstCurrencyData, List<Currency_Exchange_Rate__c> lstCurrencyRateData){
        Boolean isSaveSuccess = saveRecordsByExternalIds(lstCurrencyData, Currency__c.Fields.Code__c);

        if(isSaveSuccess){
            isSaveSuccess = saveRecordsByExternalIds(lstCurrencyRateData, Currency_Exchange_Rate__c.Fields.Code__c);
            if(isSaveSuccess){
                List<Currency__c> lstCurrencies = new List<Currency__c>();
                for(Currency_Exchange_Rate__c objCurrencyRateData : lstCurrencyRateData){
                    Currency__c objCurrency = new Currency__c();
                    objCurrency.Code__c = objCurrencyRateData.Currency__c;
                    objCurrency.USD_rate__c = objCurrencyRateData.Rate__c;
                    lstCurrencies.add(objCurrency);
                }

                return saveRecordsByExternalIds(lstCurrencies, Currency__c.Fields.Code__c);
            }
        }

        return false;
    }

    /**
    * @description Stores Currency Rate data to SF
    * @author Arquimidez Mora | 04-30-2025 
    * @param List<Currency_Exchange_Rate__c> lstCurrencyRateData 
    * @return boolean 
    **/
    public static boolean saveCurrencyRates(List<Currency_Exchange_Rate__c> lstCurrencyRateData){
        return saveRecordsByExternalIds(lstCurrencyRateData, Currency_Exchange_Rate__c.Fields.Code__c);
    }

    /**
    * @description Upserts records to SF using external Id
    * @author Arquimidez Mora | 04-30-2025 
    * @param List<SObject> lstRecords 
    * @param Schema.SObjectField objExternalIdField 
    * @return Boolean 
    **/
    private static Boolean saveRecordsByExternalIds(List<SObject> lstRecords, Schema.SObjectField objExternalIdField){
        Boolean isSuccess = true;
        Database.UpsertResult[] srList = Database.upsert(lstRecords,objExternalIdField,false);
        for (Database.UpsertResult objSaveResult : srList) {
            if (!objSaveResult.isSuccess()) {
                isSuccess = false;
                for(Database.Error objError : objSaveResult.getErrors()) {
                    System.debug('An error has occurred. ' + objError.getStatusCode() + ': ' + objError.getMessage());
                    System.debug('Fields that affected this error: ' + objError.getFields());
                    
                }
            }
        }

        return isSuccess;
    }
}