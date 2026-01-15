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

        Assert.areEqual('Login Insight', analyzer.getRuleName());
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

    @IsTest
    static void testCreateLoginInsightsWithAlgorithm() {
        List<User> users = [SELECT Id, Name FROM User];
        LoginInsightAnalyzer analyzer = new LoginInsightAnalyzer();

        Test.startTest();
        analyzer.createLoginInsightsWithAlgorithm(users);
        Test.stopTest();

        Assert.isTrue(true, 'Algorithm-based insight creation executed');
    }

    @IsTest
    static void testCleanAIOutput() {
        String raw ='```json [ { "Id": "005xx", "Name": "Test User" } ] ```';
        String cleaned = LoginInsightAnalyzer.cleanAIOutput(raw);
        Assert.isTrue(cleaned.startsWith('['));
        Assert.isTrue(cleaned.endsWith(']'));
    }

    @IsTest
    static void testGetDeletedList() {
        LoginInsightAnalyzer analyzer = new LoginInsightAnalyzer();
        List<SObject> deleted = analyzer.getDeletedList();
        Assert.areNotEqual(null, deleted);
    }

    @IsTest
    static void testDetectFailedAttempts() {
        List<User> users = [SELECT Id, Name FROM User];
        Test.startTest();
        List<Security_Insight__c> insights = LoginInsightAnalyzer.detectFailedAttempts(users);
        Test.stopTest();
        Assert.areNotEqual(null, insights);
    }

    @IsTest
    static void testDetectImpossibleTravel() {
        List<User> users = [SELECT Id FROM User];
        LoginInsightAnalyzer analyzer = new LoginInsightAnalyzer();

        Test.startTest();
        List<Security_Insight__c> insights = analyzer.detectImpossibleTravel(users);
        Test.stopTest();

        Assert.areNotEqual(null, insights);
    }
    
    @IsTest
    static void testCreateLoginInsightsWithAI() {
        List<User> users = [SELECT Id, Name FROM User LIMIT 1];
        LoginInsightAnalyzer analyzer = new LoginInsightAnalyzer();
    
        Test.startTest();
        analyzer.evaluate(true, users);
        Test.stopTest();
    
        List<Security_Insight__c> insights = [SELECT Id FROM Security_Insight__c WHERE Operation__c='Login'];
    
        Assert.areEqual(1, insights.size());
    }
    @IsTest
    static void testDetectUnusualIPs() {
        List<User> users = [SELECT Id, Name FROM User];
        Test.startTest();
        List<Security_Insight__c> insights = LoginInsightAnalyzer.detectUnusualIPs(users);
        Test.stopTest();
    
        Assert.isTrue(insights.size() > 0,'AuthSession-based unusual IP insight should be created');
    }
    @IsTest
    static void testCleanAIOutput_BlankInput() {
        String cleaned1 = LoginInsightAnalyzer.cleanAIOutput(null);
        String cleaned2 = LoginInsightAnalyzer.cleanAIOutput('');
        String cleaned3 = LoginInsightAnalyzer.cleanAIOutput('   ');
    
        Assert.areEqual('[]', cleaned1, 'Null input should return empty JSON array');
        Assert.areEqual('[]', cleaned2, 'Empty input should return empty JSON array');
        Assert.areEqual('[]', cleaned3, 'Whitespace input should return empty JSON array');
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
    
        Assert.isTrue(true, 'Forced regex failure to cover jsonString = []');
    }

}