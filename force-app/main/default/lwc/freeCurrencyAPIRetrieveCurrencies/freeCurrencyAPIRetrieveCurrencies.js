import { LightningElement } from 'lwc';
import retrieveAPIKey from "@salesforce/apex/FreeCurrencyAPIController.getCurrencyMetadata";
import storeCurrencies from '@salesforce/apex/FreeCurrencyAPIController.saveCurrencyData';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class FreeCurrencyAPIRetrieveCurrencies extends LightningElement {
    hasRendered = false;
    isLoading = true;
    apiDetails = {};
    currencyData = [];
    currencyRatesData = [];
    selectedRecords = [];
    strCurrencyList = '';

    currencyColumns = [
        {label: 'Code', fieldName: 'code'},
        {label: 'Name', fieldName: 'name'},
        {label: 'Name Plural', fieldName: 'name_plural'},
        {label: 'Symbol', fieldName: 'symbol'},
        {label: 'Symbol Native', fieldName: 'symbol_native'},
        {label: 'Decimal Digits', fieldName: 'decimal_digits'},
        {label: 'Rounding', fieldName: 'rounding'},
        {label: 'Type', fieldName: 'type'}
    ];

    renderedCallback(){
        if(this.hasRendered === false){
            this.hasRendered = true;
            this.getMetadataValues();
        }
    };

    async getMetadataValues() {
        retrieveAPIKey().then((result) => {
            this.apiDetails = result;
            this.executeFreeCurrencyAPIRequest('getCurrencies', 'currencies');
        }).catch((error) => {
            this.showError("Could not get the metadata values: " + JSON.stringify(error, null, 4));
        });
    }

    async executeFreeCurrencyAPIRequest(strRequestType, strEndpoint) {
        try {
            const response = await fetch(this.apiDetails.URL__c+strEndpoint,{
                method:"GET",
                headers:{
                    "Content-Type": "application/json",
                    "apikey": this.apiDetails.ApiKey__c
                }
            });

            const statusCode = response.status;
            if (statusCode != null && statusCode < 300) {
                const responseData = await response.json();
                this.processFCARequest(strRequestType, responseData);
            }else{
                throw Error(response);
            }
        } catch (error) {
            this.isLoading = false;
            this.showError("There's a problem with your fetch operation: " + error);
        }
    }

    processFCARequest(strRequestType, responseData){
        switch(strRequestType){
            case 'getCurrencies':
                this.handleCurrencyResponse(responseData);
                break;
            case 'getConsumptionRates':
                this.handleConsumptionRatesResponse(responseData);
                break;
            case 'getCurrencyRates':
                this.handleCurrencyRatesResponse(responseData);
                break;
        }
    }

    async handleCurrencyResponse(responseData) {
        this.currencyData = Object.values(responseData.data);
        this.isLoading = false;
    }

    async handleConsumptionRatesResponse(responseData){
        if(responseData.quotas.month.remaining > 0){
            this.executeFreeCurrencyAPIRequest('getCurrencyRates', encodeURI('latest?currencies='+this.strCurrencyList));
        }else{
            this.isLoading = false;
            this.showError("Free Currency API Monthly Quota has been consumed.");
        }
    }

    async handleCurrencyRatesResponse(responseData) {
        for (const [key, value] of Object.entries(responseData.data)) {
            let rateData = {
                code: key,
                rate: value
            };
            this.currencyRatesData.push(rateData);
        }
        this.saveRecords();
    }

    async saveRecords() {
        storeCurrencies({strCurrencyData: JSON.stringify(this.selectedRecords), strCurrencyRateData: JSON.stringify(this.currencyRatesData)}).then((result) => {
            let objResult = JSON.parse(result);
            if(objResult.success){
                this.showNotification({title: "Success", msg: "Currency records were saved successfully", variant: "success"});
            }else{
                this.showError(objResult.errorCode + ": " + objResult.errorMessage);
            }
            this.isLoading = false;
        }).catch((error) => {
            this.isLoading = false;
            this.showError("Save Error: " + JSON.stringify(error, null, 4));
        });
    }

    getSelectedRows(event){
        this.selectedRecords = event.detail.selectedRows;
    }
    
    handleStoreSelected(event) {
        if(this.selectedRecords.length > 0){
            this.isLoading = true;
            this.currencyRatesData = [];
            let lstCurrencies = [];
            this.selectedRecords.forEach(objCurrencyData => {
                lstCurrencies.push(objCurrencyData.code);
            });
            this.strCurrencyList = lstCurrencies.join(',');
            this.executeFreeCurrencyAPIRequest('getConsumptionRates', 'status');
        }else{
            this.showNotification({title: "No Records Selected", msg: "Please select at least one Currency record to store", variant: "warning"});
        }
    }

    showNotification(options) {
        const evt = new ShowToastEvent({
            title: options.title,
            message: options.msg,
            variant: options.variant,
        });
        this.dispatchEvent(evt);
    }

    showError(msg) {
        this.showNotification({title: "Error", msg: msg, variant: "error"});
    }
}