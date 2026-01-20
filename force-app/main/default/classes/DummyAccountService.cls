public class DummyAccountService {

    // Method to create a new Account
    public static Account createAccount(String accName) {
        Account acc = new Account();
        acc.Name = accName;
        insert acc;
        return acc;
    }

    // Method to fetch an Account by Id
    public static Account getAccountById(Id accountId) {
        return [
            SELECT Id, Name
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
    }
}