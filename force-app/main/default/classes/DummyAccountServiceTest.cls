@IsTest
public class DummyAccountServiceTest {

    @IsTest
    static void testCreateAndGetAccount() {

        // Start test context
        Test.startTest();

        // Call method to create account
        Account acc = DummyAccountService.createAccount('Test Account');

        // Fetch account using service method
        Account fetchedAcc = DummyAccountService.getAccountById(acc.Id);

        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, acc.Id, 'Account should be created');
        System.assertEquals('Test Account', fetchedAcc.Name, 'Account name should match');
    }
}