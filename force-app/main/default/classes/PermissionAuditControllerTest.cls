@IsTest
private class PermissionAuditControllerTest {
    @testSetup
    static void setupData() {
        // Create test users via factory
        List<User> users = TestDataFactory.createUsers(2);
        System.runAs(users[0]) {
            TestDataFactory.createUserPermissionRecords(users);
        }

        // Create a test permission set and assign to user
        PermissionSet ps = TestDataFactory.createPermissionSet();
        TestDataFactory.createObjectPermissions(ps.Id);
        TestDataFactory.assignPermissionSetToUser(ps, users[0]);

        // Add object permissions for user's profile as well
        TestDataFactory.createObjectPermissions(users[0].ProfileId);
    }

    @IsTest
    static void testGetPermissions_UserTab() {
        User u = [SELECT Id FROM User LIMIT 1];
        Test.startTest();
        List<PermissionAuditController.ObjectPermissionsForUser> result =
            PermissionAuditController.getPermissions(u.Id, 'user');
        Test.stopTest();
        Assert.isNotNull(result, 'Result list should not be null');
    }

}