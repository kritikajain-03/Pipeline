@isTest
public class LineChartControllerTest {
    private static Security_Insight__c createSI() {
        User u = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        Security_Insight__c si = new Security_Insight__c(
            User__c = u.Id,
            ResourceName__c = 'Account',
            Operation__c = 'UPDATE',
            Severity__c = 'Low'
        );
        insert si;
        
        Database_Audit__c log1 = new Database_Audit__c(
            User__c = u.Id,
            ObjectName__c = 'Account',
            Operation__c = 'UPDATE',
            LogDate__c = Date.today().addDays(-3),
            Record_Count__c = 5
        );
        Database_Audit__c log2 = new Database_Audit__c(
            User__c = u.Id,
            ObjectName__c = 'Account',
            Operation__c = 'UPDATE',
            LogDate__c = Date.today().addDays(-3),
            Record_Count__c = 7
        );
        insert new List<Database_Audit__c>{ log1, log2 };

        return si;
    }

    @isTest
    static void testValidId() {
        Security_Insight__c si = createSI();

        Test.startTest();
        Map<Date, Integer> result = LineChartController.getAuditData(si.Id);
        Test.stopTest();
        system.debug('testing');
        Assert.isTrue(!result.isEmpty(), 'Result should not be empty');
        Assert.areEqual(12, result.get(Date.today().addDays(-3)),
            'Expected aggregated count 5 + 7 = 12');
    }
}