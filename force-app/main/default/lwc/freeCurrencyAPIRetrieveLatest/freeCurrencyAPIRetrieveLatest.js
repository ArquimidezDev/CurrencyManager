import { LightningElement } from 'lwc';
import retrieveAPIKey from "@salesforce/apex/FreeCurrencyAPIController.getCurrencyMetadata";
import storeCurrencieRates from '@salesforce/apex/FreeCurrencyAPIController.saveCurrencyRateData';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class FreeCurrencyAPIRetrieveLatest extends LightningElement {
    isLoading = false;
    displayInfo = {
        primaryField: 'Code__c'
    };
    get options() {
        return [
            { label: 'EUR', value: 'EUR'},
            { label: 'USD', value: 'USD'},
            { label: 'CAD', value: 'CAD'},
            { label: 'CNY', value: 'CNY'},
            { label: 'MXN', value: 'MXN'},
            { label: 'INR', value: 'INR'},
            { label: 'JPY', value: 'JPY'},
            { label: 'AUD', value: 'AUD'},
            { label: 'BGN', value: 'BGN'},
            { label: 'BRL', value: 'BRL'},
            { label: 'CHF', value: 'CHF'},
            { label: 'CZK', value: 'CZK'},
            { label: 'DKK', value: 'DKK'},
            { label: 'GBP', value: 'GBP'},
            { label: 'HKD', value: 'HKD'},
            { label: 'HRK', value: 'HRK'},
            { label: 'HUF', value: 'HUF'},
            { label: 'IDR', value: 'IDR'},
            { label: 'ISK', value: 'ISK'},
            { label: 'ILS', value: 'ILS'},
            { label: 'KRW', value: 'KRW'},
            { label: 'MYR', value: 'MYR'},
            { label: 'NOK', value: 'NOK'},
            { label: 'NZD', value: 'NZD'},
            { label: 'PHP', value: 'PHP'},
            { label: 'PLN', value: 'PLN'},
            { label: 'RON', value: 'RON'},
            { label: 'RUB', value: 'RUB'},
            { label: 'SEK', value: 'SEK'},
            { label: 'SGD', value: 'SGD'},
            { label: 'THB', value: 'THB'},
            { label: 'TRY', value: 'TRY'},
            { label: 'ZAR', value: 'ZAR'}
        ];
    }
    strBaseCurrency = 'USD';
    selectedCurrencies = '';
    currencyRatesData = [];
    apiDetails = {};
    hasRendered = false;

    renderedCallback(){
        if(this.hasRendered === false){
            this.hasRendered = true;
            this.getMetadataValues();
        }
    };

    async getMetadataValues() {
        retrieveAPIKey().then((result) => {
            this.apiDetails = result;
        }).catch((error) => {
            this.showError("Could not get the metadata values: " + JSON.stringify(error, null, 4));
        });
    }

    handleChange(event) {
        this.strBaseCurrency = event.detail.value;
    }
    handleChangeMultiple(event) {
        this.selectedCurrencies = event.detail.value;
    }

    handleStoreSelected() {
        if (this.strBaseCurrency === '') {
            this.showNotification({title: "No Records Selected", msg: "Please select a Base Currency", variant: "warning"});
        }else{
            this.isLoading = true;
            this.executeFreeCurrencyAPIRequest('getConsumptionRates', 'status');
        }
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
            case 'getConsumptionRates':
                this.handleConsumptionRatesResponse(responseData);
                break;
            case 'getCurrencyRates':
                this.handleCurrencyRatesResponse(responseData);
                break;
        }
    }

    async handleConsumptionRatesResponse(responseData){
        if(responseData.quotas.month.remaining > 0){
            this.executeFreeCurrencyAPIRequest('getCurrencyRates', 
                encodeURI('latest?currencies='+this.selectedCurrencies+'&base_currency='+this.strBaseCurrency));
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
        console.log('***- selectedCurrencies: ', JSON.stringify(this.selectedCurrencies, null, 4));
        console.log('***- currencyRatesData: ', JSON.stringify(this.currencyRatesData, null, 4));
        console.log('***- strBaseCurrency: ', JSON.stringify(this.strBaseCurrency, null, 4));
        storeCurrencieRates({strCurrencyRateData: JSON.stringify(this.currencyRatesData), strBaseCurrencyCode: this.strBaseCurrency}).then((result) => {
            let objResult = JSON.parse(result);
            console.log('***- save result: ', JSON.stringify(objResult, null, 4));
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

    async handleCurrencyRatesResponse(responseData) {
        this.currencyRatesData = [];
        for (const [key, value] of Object.entries(responseData.data)) {
            let rateData = {
                code: key,
                rate: value
            };
            this.currencyRatesData.push(rateData);
        }
        this.saveRecords();
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