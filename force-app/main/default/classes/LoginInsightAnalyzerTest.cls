@isTest
public class LoginInsightAnalyzerTest {

    @isTest
    static void testBusinessHour_trueCase() {
        Boolean result = LoginInsightAnalyzer.isBusinessHour(10);
        System.assertEquals(true, result, '10 AM should be business hour');
    }

    @isTest
    static void testBusinessHour_falseCase() {
        Boolean result = LoginInsightAnalyzer.isBusinessHour(22);
        System.assertEquals(false, result, '10 PM should not be business hour');
    }

    @isTest
    static void testBusinessHour_nullCase() {
        Boolean result = LoginInsightAnalyzer.isBusinessHour(null);
        System.assertEquals(false, result, 'Null hour should return false');
    }
}
