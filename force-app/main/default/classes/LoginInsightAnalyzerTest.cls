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
    static void testJsonStringElseBranch() {
        List<User> users = [SELECT Id, Name FROM User LIMIT 1];
    
        LoginInsightAnalyzer.FORCE_REGEX_FAIL = true;
    
        LoginInsightAnalyzer analyzer = new LoginInsightAnalyzer();
        Test.startTest();
        analyzer.evaluate(true, users);
        Test.stopTest();
    
        LoginInsightAnalyzer.FORCE_REGEX_FAIL = false;
    
        Assert.isFalse(true, 'Forced regex failure to cover jsonString = []');
    }

}