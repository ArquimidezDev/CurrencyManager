/**
 * @description       : Methods to work with Free Currency API front end components
 * @author            : Arquimidez Mora
 * @group             : 
 * @last modified on  : 04-30-2025
 * @last modified by  : Arquimidez Mora
 * Modifications Log
 * Ver   Date         Author            Modification
 * 1.0   04-29-2025   Arquimidez Mora   Initial Version
**/
public with sharing class FreeCurrencyAPIController {
    
    /**
    * @description Gets the Metadata record that holds the API Key from Free Currency API
    * @author Arquimidez Mora | 04-30-2025 
    * @return Free_Currency_API_Key__mdt 
    **/
    @AuraEnabled
    public static Free_Currency_API_Key__mdt getCurrencyMetadata(){
        try {
            return FreeCurrencyAPIService.retrieveAPIKey();
        } catch (Exception e) {
            System.debug('***- Error completing request:' + e.getMessage());
            return null;
        }
    }

    /**
    * @description Parses frontend data, builds a list of currency SF records with it and saves them.
    * @author Arquimidez Mora | 04-30-2025 
    * @param String strCurrencyData 
    * @param String strCurrencyRateData 
    * @return string 
    **/
    @AuraEnabled
    public static string saveCurrencyData(String strCurrencyData, String strCurrencyRateData){
        ResponseWrapper objResponse = new ResponseWrapper();
        try {
            if(strCurrencyData != null && !String.isBlank(strCurrencyData)){
                List<Currency__c> lstCurrencies = new List<Currency__c>();
                List<Currency_Exchange_Rate__c> lstCurrencyRates = new List<Currency_Exchange_Rate__c>();

                List<CurrencyDataWrapper> lstCurrencyData = (List<CurrencyDataWrapper>)System.JSON.deserialize(strCurrencyData, List<CurrencyDataWrapper>.class);
                List<CurrencyRateDataWrapper> lstCurrencyRateData = (List<CurrencyRateDataWrapper>)System.JSON.deserialize(strCurrencyRateData, List<CurrencyRateDataWrapper>.class);
                
                for(CurrencyDataWrapper objCurrencyData : lstCurrencyData){
                    lstCurrencies.add(createCurrency(objCurrencyData));
                }

                for(CurrencyRateDataWrapper objCurrencyRateData : lstCurrencyRateData){
                    lstCurrencyRates.add(createCurrencyRate(objCurrencyRateData, 'USD'));
                }

                Boolean isSaveSuccess = FreeCurrencyAPIService.saveCurrencies(lstCurrencies, lstCurrencyRates);
                objResponse.success = isSaveSuccess;

                if(!isSaveSuccess){
                    objResponse.errorCode = 'FCAERR-02';
                    objResponse.errorMessage = 'Error saving data';
                }
            }else{
                objResponse.success = false;
                objResponse.errorCode = 'FCAERR-01';
                objResponse.errorMessage = 'No data was received';
            }
        } catch (Exception e) {
            objResponse.success = false;
            objResponse.errorCode = 'FCAERR-00';
            objResponse.errorMessage = 'Error processing request: ' + e.getMessage() + '\n' + e.getStackTraceString();
        }
        return System.JSON.serialize(objResponse);
    }

    /**
    * @description Parses frontend data, builds a list of currency rate SF records with it and saves them.
    * @author Arquimidez Mora | 04-30-2025 
    * @param String strCurrencyRateData 
    * @param String strBaseCurrencyCode 
    * @return string 
    **/
    @AuraEnabled
    public static string saveCurrencyRateData(String strCurrencyRateData, String strBaseCurrencyCode){
        ResponseWrapper objResponse = new ResponseWrapper();
        try {
            if(strCurrencyRateData != null && !String.isBlank(strCurrencyRateData)){
                List<Currency_Exchange_Rate__c> lstCurrencyRates = new List<Currency_Exchange_Rate__c>();
                List<CurrencyRateDataWrapper> lstCurrencyRateData = (List<CurrencyRateDataWrapper>)System.JSON.deserialize(strCurrencyRateData, List<CurrencyRateDataWrapper>.class);

                for(CurrencyRateDataWrapper objCurrencyRateData : lstCurrencyRateData){
                    lstCurrencyRates.add(createCurrencyRate(objCurrencyRateData, strBaseCurrencyCode));
                }

                Boolean isSaveSuccess = FreeCurrencyAPIService.saveCurrencyRates(lstCurrencyRates);
                objResponse.success = isSaveSuccess;
                
                if(!isSaveSuccess){
                    objResponse.errorCode = 'FCAERR-CR-02';
                    objResponse.errorMessage = 'Error saving data';
                }
            }else{
                objResponse.success = false;
                objResponse.errorCode = 'FCAERR-CR-01';
                objResponse.errorMessage = 'No data was received';
            }
        } catch (Exception e) {
            objResponse.success = false;
            objResponse.errorCode = 'FCAERR-CR-00';
            objResponse.errorMessage = 'Error processing request: ' + e.getMessage() + '\n' + e.getStackTraceString();
        }
        return System.JSON.serialize(objResponse);
    }

    /**
    * @description Support method to convert front end data into a SF object
    * @author Arquimidez Mora | 04-30-2025 
    * @param CurrencyDataWrapper objCurrencyData 
    * @return Currency__c 
    **/
    private static Currency__c createCurrency(CurrencyDataWrapper objCurrencyData){
        return new Currency__c(
            Name = objCurrencyData.name,
            Name_Plural__c = objCurrencyData.name_plural,
            Code__c = objCurrencyData.code,
            Symbol__c = objCurrencyData.symbol,
            Symbol_Native__c = objCurrencyData.symbol_native,
            Type__c = objCurrencyData.type,
            Decimal__c = Integer.valueOf(objCurrencyData.decimal_digits),
            Rounding__c = Integer.valueOf(objCurrencyData.rounding));
    }

    /**
    * @description Support method to convert front end data into a SF object
    * @author Arquimidez Mora | 04-30-2025 
    * @param CurrencyRateDataWrapper objCurrencyRateData 
    * @param String strBaseCurrencyCode 
    * @return Currency_Exchange_Rate__c 
    **/
    private static Currency_Exchange_Rate__c createCurrencyRate(CurrencyRateDataWrapper objCurrencyRateData, String strBaseCurrencyCode){
        return new Currency_Exchange_Rate__c(
            Base_Currency__c = strBaseCurrencyCode,
            Currency__c = objCurrencyRateData.code,
            Rate__c = objCurrencyRateData.rate,
            Code__c =  strBaseCurrencyCode + '-' + objCurrencyRateData.code + '-' + Date.today().format());
    }

    //Wrapper for getting FrontEnd data
    public class CurrencyDataWrapper{
        public String code;
        public String name;
        public String symbol;
        public String name_plural;
        public String symbol_native;
        public Integer decimal_digits;
        public Integer rounding;
        public String type;
    }

    //Wrapper for getting FrontEnd data
    public class CurrencyRateDataWrapper{
        public String code;
        public Decimal rate;
    }

    //Wrapper to store data that will be send to front end
    public class ResponseWrapper{
        public boolean success;
        public String errorCode;
        public String errorMessage;
    }
}