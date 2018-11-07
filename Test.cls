global class AddressCountryRelationshipHandler implements Loop.IApexDataSource {
    
    private string countryAddress = 'ApexSoqlAddress'; 
    private string contactLanguage = 'ApeSoqlContact'; 
    
    public Set<string> getGlobalDescribe() {
        // Return a set of object names that this Apex class will provide data for.
        // In this example, we will provide data for a single Opportunity.
        return new Set<string>{
            contactLanguage,
            countryAddress
        };
    }
    
     public Set<string> getChildRelationships(string objectName) {
        // Return a set of object names corresponding to the children for the objectName specified
        // In this example, there are no child objects.
        return new Set<string>();
    }
    
    public List<Loop.ExternalData.DataObject> describeObjects(List<string> objectNames) {
        // Describe each object in objectNames.
        // In this example, we will use all fields for each Salesforce object being used.
        
        // Declare the variable to be returned.
        List<Loop.ExternalData.DataObject> describeObjectResults = new List<Loop.ExternalData.DataObject>();
               
        // Loop through each object in objectNames and add to the result
        // 
             
        for (string objectName : objectNames) {
            // Declare variable to store field data for the object
            List<Loop.ExternalData.FieldInfo> fields = new List<Loop.ExternalData.FieldInfo>();
            
            if (objectName == countryAddress) {
                // Describe the fields for this object.
                fields.add(new Loop.ExternalData.FieldInfo('Country__c', Schema.DisplayType.STRING));
                fields.add(new Loop.ExternalData.FieldInfo('Address__c', Schema.DisplayType.STRING));
                fields.add(new Loop.ExternalData.FieldInfo('Company_Line__c', Schema.DisplayType.STRING));
                fields.add(new Loop.ExternalData.FieldInfo('Email__c', Schema.DisplayType.STRING));
                // Loop through fields on the Opportunity object, store the info, and add to fields
            }
            
            if(objectName == contactLanguage){
                fields.add(new Loop.ExternalData.FieldInfo('Language__c', Schema.DisplayType.STRING));
            }
            
            // Declare variable to add to results list using fields described above
            Loop.ExternalData.DataObject describeObjectResult = new Loop.ExternalData.DataObject(objectName, fields);
            
            // Add to results list
            describeObjectResults.add(describeObjectResult);
        }
        
        return describeObjectResults;
    }
    
  public Loop.ExternalData.QueryResultSet query(Loop.ExternalData.QueryRequestInfo requestInfo) {
        // Provide data for each object in requestInfo.GetObjectNames()
        // Assume that the Document Package is run from the Opportunity
        Id contractId = requestInfo.RecordId;
        List <SVMXC__Service_Contract__c> currentContract;
        List <LS_Drawloop_Country_Data_Map__mdt> records;
        // Declare the variable to be returned.
        Loop.ExternalData.QueryResultSet queryResultSet = new Loop.ExternalData.QueryResultSet();
        // Loop through all objects requested. The QueryResultSet instance returned needs to contain a QueryResult instance for each object requested.
        List<String> objectList = new List<String> {'ApexSoqlAddress', 'ApexSoqlContact'};
        for (string objectName : objectList) {
        //for (string objectName :  fakeList) {
            string query;
            // Declare fields list for QueryResult instance
            List<string> fields = new List<string>();
  
            // set up fields list and query to get data for QueryResult instance
            if (objectName == countryAddress) {
                // Get list of fields from the Opportunity object
                fields = new List<string>{ 'Country__c', 'Address__c', 'Company_Line__c', 'Email__c'};

                Loop.ExternalData.QueryResult queryResult = new Loop.ExternalData.QueryResult(objectName, fields);
                
                currentContract = Database.query('SELECT GEHCLS_Country__c, HCLS_Bill_to_Account_Address__c, SVMXC__Contact__r.Language__c FROM SVMXC__Service_Contract__c WHERE Id = :contractId');
                String countryName = currentContract[0].GEHCLS_Country__c;
                String sampleSoqlQuery = 'SELECT Country__c, Address__c, Company_Line__c, Language__c, Email__c, Different_Addreses__c FROM LS_Drawloop_Country_Data_Map__mdt WHERE Country__c = :countryName';
                
                records = Database.query(sampleSoqlQuery);
   
                // for each row of data returned by the query
                for (LS_Drawloop_Country_Data_Map__mdt record : records) {
                   // System.debug(record.Different_Addreses__c);
                    // Store the values (as strings) from the record in the same order of the fields defined in the QueryResult instance
                    List<string> recordValues = new List<string>();
                    for (string field : fields) {
                        //if(field == 'Address__c'){
                            //if(record.Different_Addreses__c){
                                //String countryBillingAddress = currentContract[0].HCLS_Bill_to_Account_Address__c;
                             	//record.Address__c = getAddressForCountry(record.Address__c, countryBillingAddress);
                            //}
                        //}
                        recordValues.add(getFieldValue(record, field));
                        
                    }
                    // Add the values to the QueryResult instance rows
                    
                    queryResult.rows.add(recordValues);
                    
                }
                
                queryResultSet.add(queryResult);
               
            }
            
            if (objectName == contactLanguage) {
                
                fields = new List<string>{ 'Language__c'};
                Loop.ExternalData.QueryResult queryResult = new Loop.ExternalData.QueryResult(objectName, fields);
                
                String conLanguage = currentContract[0].SVMXC__Contact__r.Language__c;
                List <String> languagesForCurrentCountry = records[0].Language__c.replaceAll( '\\s+', '').split(',');
                
                if(!languagesForCurrentCountry.contains(conLanguage)){
                    conLanguage = languagesForCurrentCountry[0];
                }
   
                List<string> recordValues = new List<string>();
                
                for (string field : fields) {
                      recordValues.add(conLanguage);
                }
                
                queryResult.rows.add(recordValues);
                queryResultSet.add(queryResult); 
            }
        }
            
        return queryResultSet;
  }
    
    
    private String getAddressForCountry(String recordJson, String countryBillingAddress){
        
           String address = '';
           Map<String, String> allAddresses = (Map<String,String>) JSON.deserialize(recordJson, Map<String,String>.class);
        		for (String city : allAddresses.keySet()){
                    if(countryBillingAddress.contains(city)){
                        List <String> splittedAddress = allAddresses.get(city).split('\\|');
                        for(String line: splittedAddress){
                            address += (line + ' \r\n');
                        }
                        return address;
                    }
                }
        	return address;
    }
    
    // Helper method
    
    // This method properly retrieves a field value from an SObject for fields used through lookup relationships, 
    // e.g. PricebookEntry.Product2.ProductCode on the OpportunityLineItem object.
    private string getFieldValue(sObject obj, string field) {
        if (obj == null) return '';
        string[] fieldParts = field.split('\\.');
        if (fieldParts.size() == 3) {
            sObject sobj = obj.getSObject(fieldParts[0]);
            if (sobj == null) return '';
            sobj = sobj.getSObject(fieldParts[1]);
            if (sobj == null) return '';
            return string.valueOf(sobj.get(fieldParts[2]));
        }
        else if (fieldParts.size() == 2) {
            sObject sobj = obj.getSObject(fieldParts[0]);
            if (sobj == null) return '';
            return string.valueOf(sobj.get(fieldParts[1]));
        }
        return string.valueOf(obj.get(field));
    }
}
