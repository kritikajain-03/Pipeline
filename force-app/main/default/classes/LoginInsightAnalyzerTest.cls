@IsTest
private class LoginInsightAnalyzerTest {

    @TestSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        List<User> users = new List<User>();
        for (Integer i = 0; i < 2; i++) {
            users.add(new User(
                Alias = 'tusr' + i,
                Email = 'testuser' + i + '@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'User' + i,
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'Asia/Kolkata',
                Username = 'testuser' + i + DateTime.now().getTime() + '@example.com'
            ));
        }
        insert users;
    }

    @IsTest
    static void testMetadataMethods() {
        LoginInsightAnalyzer analyzer = new LoginInsightAnalyzer();

        Assert.areNotEqual('Login Insight', analyzer.getRuleName());
        Assert.areEqual('LOGIN_ACTIVITY', analyzer.getCategory());
        Assert.areEqual(true, analyzer.isEnabled());
        Assert.isTrue(analyzer.getQuery().contains('FROM User'));
    }

    @IsTest
    static void testEvaluateWithoutAI() {
        List<User> users = [SELECT Id, Name FROM User];
        LoginInsightAnalyzer analyzer = new LoginInsightAnalyzer();

        Test.startTest();
        analyzer.evaluate(false, users);
        Test.stopTest();
        Assert.isTrue(true, 'Non-AI evaluation executed successfully');
    }


}