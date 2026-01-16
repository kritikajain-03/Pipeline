/*
This Apex controller provides audit log data required for rendering 
a line chart in LWC components. It accepts a single 
Security_Insight__c record Id, validates it, and retrieves the associated 
user's audit activity for the same object and operation over the last 
six months.
*/
public with sharing class LineChartController {
    @AuraEnabled(cacheable=true)
    public static Map<Date, Integer> getAuditData(String currentId) {
        List<Security_Insight__c> siList = [
            SELECT Id, User__c, ResourceName__c, Operation__c
            FROM Security_Insight__c
            WHERE Id = :currentId
        ];
        if (siList.isEmpty()) {
            throw new AuraHandledException('No Security Insight record found for provided Id.');
        }
        Security_Insight__c si = siList[0];
        Date sixMonthsAgo = Date.today().addMonths(-6);

        List<Database__c> logs = [
            SELECT Record_Count__c, Operation__c, ObjectName__c, User__c, LogDate__c
            FROM Database_Audit__c
            WHERE LogDate__c >= :sixMonthsAgo
            AND User__c = :si.User__c
            AND ObjectName__c = :si.ResourceName__c
            AND Operation__c = :si.Operation__c
            ORDER BY LogDate__c ASC
        ];

        Map<Date, Integer> result = new Map<Date, Integer>();
        for (Database_Audit__c log : logs) {
            Date logDate = log.LogDate__c;
            Integer count = result.containsKey(logDate) ? result.get(logDate) : 0;
            result.put(logDate, count + (Integer)log.Record_Count__c);
        }

        return result;
    }
}