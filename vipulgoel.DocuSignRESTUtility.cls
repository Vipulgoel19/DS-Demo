public class DocuSignRESTUtility {

    private static Map<String, vipulgoel__DocuSignRESTSettings__mdt> settingsMap { 
        get {
            if (settingsMap == null) {
                settingsMap = new Map<String, vipulgoel__DocuSignRESTSettings__mdt>();
                for (vipulgoel__DocuSignRESTSettings__mdt setting : [Select DeveloperName,MasterLabel, vipulgoel__Value__c from vipulgoel__DocuSignRESTSettings__mdt]) {
                    settingsMap.put(setting.MasterLabel, setting);
                    system.debug('settingsMap : '+settingsMap);
                }
            }
            return settingsMap;
        }
        set {
        }
    }

    public static String getAccessToken() {
        String access_token = null;
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        String authendpoint = settingsMap.get('RequestAuthEndpoint').Value__c;
        System.Debug(LoggingLevel.INFO, '**RequestAuthEndpoint' + authendpoint);
        req.setEndPoint(authendpoint);
        String authRequestContentType = settingsMap.get('RequestAuthContentType').Value__c;
        System.Debug(LoggingLevel.INFO, '**authRequestContentType ' + authRequestContentType);
        req.setHeader('Content-type', authRequestContentType);
        String authRequestDomain = settingsMap.get('RequestAuthDomain').Value__c;
        System.Debug(LoggingLevel.INFO, '**authRequestDomain ' + authRequestDomain);
        req.setHeader('Host', authRequestDomain);
        String alg = 'RS256';
        String iss = settingsMap.get('RequestIntegratorKey').Value__c;
        String pkey = settingsMap.get('RequestPrivateKey').Value__c;
        String scope = settingsMap.get('RequestScope').Value__c;
        DocusignJWT jwtObject = new DocusignJWT(alg, settingsMap.get('DSUserName').Value__c, iss, pkey, scope, authRequestDomain);
        system.debug('jwtObject : '+jwtObject );
        String requestBody = settingsMap.get('RequestAuthBody').Value__c + jwtObject .issue();
        System.Debug(LoggingLevel.INFO, '**RequestAuthBody' + requestBody);
        req.setBody(requestBody);
        system.debug(req.getBody());
        Http http = new Http();
        HTTPResponse res = http.send(req);

        System.Debug(LoggingLevel.INFO, '**ResponseAuthBody' + res.getbody());
        System.Debug(LoggingLevel.INFO, '**ResponseAuth' + res);
        
        if (res.getStatusCode() == 200) {
            System.JSONParser parser = System.JSON.createParser(res.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) {
                    parser.nextToken();
                    access_token = parser.getText();
                    break;
                }
            }
        }
        return access_token;

    }
    
    //This method will invoke the outbound REST call to the Docusign API
    @future(callout=true)
    public static void getDocumentDetails() {
        String accessToken = getAccessToken();
        System.Debug(LoggingLevel.INFO, '***accessToken ' + accessToken);

        if (!String.isEmpty(accessToken)) {
            Http httpProtocol = new Http();

            HttpRequest request = new HttpRequest();
            String endpoint = settingsMap.get('RequestEnvelopeEndpoint').Value__c + settingsMap.get('DSAccountID').Value__c + '/envelopes';
            System.Debug(LoggingLevel.INFO, '***endpoint ' + endpoint);
            request.setEndPoint(endpoint);
            request.setMethod('POST');
            request.setHeader('grant_type', 'Bearer');
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-type', 'application/json');

            //BODY

           
        }
    }

@future(callout=true)
    public static void createEnvelope() {
        //Get the access token
        String accessToken = getAccessToken();
        System.Debug(LoggingLevel.INFO, '***accessToken ' + accessToken);

        //Call envelope Creation service if a non-empty access token is returned
        if (!String.isEmpty(accessToken)) {
            //instantiate an Http instance  
            Http httpProtocol = new Http();

            //instantiate an HttpRequest instance  
            HttpRequest request = new HttpRequest();

            //Set the request parameters 
            // Request endpoint for createEnvelope call
            String endpoint = settingsMap.get('RequestEnvelopeEndpoint').Value__c + settingsMap.get('DSAccountID').Value__c + '/envelopes';
            System.Debug(LoggingLevel.INFO, '***endpoint ' + endpoint);
            request.setEndPoint(endpoint);

            //set the POST method
            request.setMethod('POST');

            //set Authentication Header
            request.setHeader('grant_type', 'Bearer');
            request.setHeader('Authorization', 'Bearer ' + accessToken);

            //set Accept Header
            request.setHeader('Accept', 'application/json');

            //set Content Type Header
            request.setHeader('Content-type', 'application/json');

            //create the request Body

            //create instance of the EnvelopeCreationRequest class
            DocuSignRESTUtility.EnvelopeCreationRequest requestObject = new DocuSignRESTUtility.EnvelopeCreationRequest();
            requestObject.status = settingsMap.get('RequestEnvelopeStatus').Value__c;
            requestObject.emailSubject = settingsMap.get('RequestEnvelopeSubject').Value__c;
            requestObject.templateId = settingsMap.get('RequestEnvelopeTemplateID').Value__c;

            System.Debug(LoggingLevel.INFO, '***requestObject() ' + requestObject);
            String jsonBody = json.serialize(requestObject);
            System.Debug(LoggingLevel.INFO, '***jsonBody() ' + jsonBody);
            request.setBody(jsonBody);

            //Make the request and capture the response
            HttpResponse response = httpProtocol.send(request);
            System.Debug(LoggingLevel.INFO, '***response.getBody() ' + response.getBody());
            System.debug(LoggingLevel.INFO, '***response.getStatus() ' + response.getStatus());
            
        //Parse the response
            String responseStatus = response.getStatus();
            if (responseStatus.equals('Created')) {
                DocuSignRESTUtility.EnvelopeCreationResponse responseObject = new DocuSignRESTUtility.EnvelopeCreationResponse();
                responseObject = (DocuSignRESTUtility.EnvelopeCreationResponse)System.JSON.deserialize(response.getBody(), DocuSignRESTUtility.EnvelopeCreationResponse.class);
                System.Debug(LoggingLevel.INFO, '***responseObject ' + responseObject);
            }
        }
    }

    //wrapper class for Envelope Creation Request
    //This class can be further re-vamped to create complex Envelopes to be passed to the createEnvelope Service
    //For more information refer https://developers.docusign.com/esign-rest-api/reference/Envelopes/Envelopes/create
    public class EnvelopeCreationRequest {
        public String emailSubject { get; set; }
        public String status { get; set; }
        public String templateId { get; set; }
    }

    //wrapper class for Envelope Creation Response
    public class EnvelopeCreationResponse {
        public String envelopeId { get; set; }
        public String uri { get; set; }
        public String status { get; set; }
        public String statusDateTime { get; set; }
    }

}