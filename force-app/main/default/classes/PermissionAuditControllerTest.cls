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

    @IsTest
    static void testGetPermissions_ProfileTab() {
        User u = [SELECT ProfileId FROM User LIMIT 1];
        Test.startTest();
        List<PermissionAuditController.ObjectPermissionsForUser> result =
            PermissionAuditController.getPermissions(u.ProfileId, 'profile');
        Test.stopTest();
        Assert.isNotNull(result, 'Result list should not be null');
    }

    @IsTest
    static void testGetPermissions_PermissionSetTab() {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'TestPermSet' LIMIT 1];
        Test.startTest();
        List<PermissionAuditController.ObjectPermissionsForUser> result =
            PermissionAuditController.getPermissions(ps.Id, 'permissionSet');
        Test.stopTest();
        Assert.isNotNull(result, 'Result list should not be null');
    }

    @IsTest
    static void testGetPermissions_EmptyList() {
        Test.startTest();
        List<PermissionAuditController.ObjectPermissionsForUser> result =
            PermissionAuditController.getPermissions('00D000000000000AAA', 'invalid');
        Test.stopTest();
        Assert.areEqual(0, result.size(), 'Should return empty list for invalid tab');
    }

    @IsTest
    static void testGetPrivilegedPerms_User() {
        User u = [SELECT Id FROM User LIMIT 1];
        Test.startTest();
        List<String> result = PermissionAuditController.getPrivilegedPerms(u.Id, 'user');
        Test.stopTest();
        Assert.isNotNull(result, 'Result should not be null');
    }

    @IsTest
    static void testGetPrivilegedPerms_Profile() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Test.startTest();
        List<String> result = PermissionAuditController.getPrivilegedPerms(p.Id, 'profile');
        Test.stopTest();
        Assert.isNotNull(result, 'Should return valid list (may be empty)');
    }

    @IsTest
    static void testGetPrivilegedPerms_PermissionSet() {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'TestPermSet' LIMIT 1];
        Test.startTest();
        List<String> result = PermissionAuditController.getPrivilegedPerms(ps.Id, 'permissionSet');
        Test.stopTest();
        Assert.isNotNull(result, 'Should return valid list (may be empty)');
    }

    @IsTest
    static void testGetPrivilegedPerms_UnsupportedType() {
        Test.startTest();
        List<String> result = PermissionAuditController.getPrivilegedPerms('001XXXXXXX00000AAA', 'unknownType');
        Test.stopTest();
        Assert.areEqual(0, result.size(), 'Should return empty list for unsupported type');
    }

    @IsTest
    static void testGetPrivilegedPermissionsOfBoth_Profile() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Test.startTest();
        List<String> result = PermissionAuditController.getPrivilegedPermissionsOfBoth(p.Id, 'Profile');
        Test.stopTest();
        Assert.isNotNull(result, 'Should not return null');
    }

    @IsTest
    static void testGetPrivilegedPermissionsOfBoth_PermissionSet() {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'TestPermSet' LIMIT 1];
        Test.startTest();
        List<String> result = PermissionAuditController.getPrivilegedPermissionsOfBoth(ps.Id, 'PermissionSet');
        Test.stopTest();
        Assert.isNotNull(result, 'Should not return null');
    }

    @IsTest
    static void testGetUserAuditData() {
        Test.startTest();
        List<PermissionAuditController.PermissionAuditWrapper> result =
            PermissionAuditController.getUserAuditData();
        Test.stopTest();
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Should have at least one active user');
    }

    @IsTest
    static void testGetProfileAuditData() {
        Test.startTest();
        List<PermissionAuditController.PermissionAuditWrapper> result =
            PermissionAuditController.getProfileAuditData();
        Test.stopTest();
        Assert.isNotNull(result, 'Result should not be null');
    }

    @IsTest
    static void testGetPermissionSetAuditData() {
        Test.startTest();
        List<PermissionAuditController.PermissionAuditWrapper> result =
            PermissionAuditController.getPermissionSetAuditData();
        Test.stopTest();
        Assert.isNotNull(result, 'Result should not be null');
    }
}