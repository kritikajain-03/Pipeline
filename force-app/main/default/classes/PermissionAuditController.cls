/*
PermissionAuditController is an Apex controller designed to provide detailed audit information 
about Users, Profiles, and Permission Sets within the Salesforce org. It retrieves assigned 
permissions, object-level permissions, and privileged permissions for the specified records, 
encapsulating the results in wrapper classes for easy use in Lightning components or Aura pages. 
The controller supports caching for improved performance and provides methods to fetch both 
summary data (like user counts, object counts, and permission counts) and detailed permissions 
at the object and privileged permission level. It leverages dynamic SOQL queries to handle 
metadata-driven privileged permissions efficiently across different record types.
*/
public with sharing class PermissionAuditController {
    
    public class PermissionAuditWrapper {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public String relatedName;
        @AuraEnabled public Integer userCount;
        @AuraEnabled public Integer objectCount;
        @AuraEnabled public Integer assignedPermissionCount;
        @AuraEnabled public List<String> enabledPermissions;
        @AuraEnabled public String assignedPermissions;
    }

    public class ObjectPermissionsForUser {  
        @AuraEnabled public String sObjectType;
        @AuraEnabled public String objectLabel;
        @AuraEnabled public Boolean createPerm;
        @AuraEnabled public Boolean readPerm;
        @AuraEnabled public Boolean editPerm;
        @AuraEnabled public Boolean deletePerm;
        @AuraEnabled public Boolean viewAll;
        @AuraEnabled public Boolean modifyAll;
    }

    @AuraEnabled(cacheable=true)
    public static List<PermissionAuditWrapper> getUserAuditData() {
        List<User> userList = [
            SELECT Id, Name, Username, Profile.Name
            FROM User
            WHERE IsActive = true AND Profile.Name != null
            ORDER BY Name
        ];

        Set<Id> userIds = new Map<Id, User>(userList).keySet();

        List<User_Permissions__c> userPrivPermsList = [
            SELECT Id, User__c, Assigned_Permissions__c
            FROM User_Permissions__c
            WHERE User__c IN :userIds
        ];

        Map<Id, Integer> userPrivPermCountMap = new Map<Id, Integer>();
        for (User_Permissions__c up : userPrivPermsList) {
            if (String.isNotBlank(up.Assigned_Permissions__c)) {
                userPrivPermCountMap.put(up.User__c, up.Assigned_Permissions__c.split(';').size());
            }
        }

        List<PermissionAuditWrapper> result = new List<PermissionAuditWrapper>();
        for (User u : userList) {
            PermissionAuditWrapper auditWrap = new PermissionAuditWrapper();
            auditWrap.recordId = u.Id;
            auditWrap.name = u.Username;
            auditWrap.label = u.Name;
            auditWrap.relatedName = u.Profile.Name;
            auditWrap.type = 'User';
            auditWrap.assignedPermissionCount = userPrivPermCountMap.get(u.Id) == null ? 0 : userPrivPermCountMap.get(u.Id);
            result.add(auditWrap);
        }
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<PermissionAuditWrapper> getProfileAuditData() {
        List<Privileged_Permission__mdt> privPerms = [SELECT Permission_API_Name__c, Display_Name__c FROM Privileged_Permission__mdt];

        Map<String, Schema.SObjectField> profileFieldsMap = Profile.SObjectType.getDescribe().fields.getMap();
        Map<String, String> permApiToLabel = new Map<String, String>();
        for (Privileged_Permission__mdt p : privPerms) {
            String apiName = p.Permission_API_Name__c.startsWith('Permissions') ? p.Permission_API_Name__c : 'Permissions' + p.Permission_API_Name__c;
            if (profileFieldsMap.containsKey(apiName)) permApiToLabel.put(apiName, p.Display_Name__c);
        }
        if (permApiToLabel.isEmpty()) return new List<PermissionAuditWrapper>();

        List<String> conditions = new List<String>();
        for (String f : permApiToLabel.keySet()) conditions.add(f + ' = true');

        String query = 'SELECT Id, Name';
        for (String f : permApiToLabel.keySet()) query += ', ' + f;
        query += ' FROM Profile WHERE ' + String.join(conditions, ' OR ') + ' ORDER BY Name ASC';

        List<Profile> profiles = Database.query(query);
        Set<Id> profileIds = new Map<Id, Profile>(profiles).keySet();

        Map<Id, Integer> profileUserCountMap = new Map<Id, Integer>();
        for (AggregateResult ar : [SELECT ProfileId, COUNT(Id) cnt FROM User WHERE ProfileId IN :profileIds GROUP BY ProfileId]) {
            profileUserCountMap.put((Id)ar.get('ProfileId'), (Integer)ar.get('cnt'));
        }

        Map<Id, Integer> profileObjCountMap = new Map<Id, Integer>();
        for (AggregateResult ar : [SELECT Parent.ProfileId pId, COUNT(Id) cnt FROM ObjectPermissions WHERE (PermissionsViewAllRecords = true OR PermissionsModifyAllRecords = true) AND Parent.ProfileId IN :profileIds GROUP BY Parent.ProfileId]) {
            profileObjCountMap.put((Id)ar.get('pId'), (Integer)ar.get('cnt'));
        }

        List<PermissionAuditWrapper> result = new List<PermissionAuditWrapper>();
        for (Profile p : profiles) {
            PermissionAuditWrapper auditWrap = new PermissionAuditWrapper();
            auditWrap.recordId = p.Id;
            auditWrap.name = p.Name;
            auditWrap.type = 'Profile';
            auditWrap.userCount = profileUserCountMap.get(p.Id) != null ? profileUserCountMap.get(p.Id) : 0;
            auditWrap.objectCount = profileObjCountMap.get(p.Id) != null ? profileObjCountMap.get(p.Id) : 0;
            auditWrap.enabledPermissions = new List<String>();
            for (String f : permApiToLabel.keySet()) if ((Boolean)p.get(f)) auditWrap.enabledPermissions.add(permApiToLabel.get(f));
            auditWrap.assignedPermissionCount = auditWrap.enabledPermissions.size();
            auditWrap.assignedPermissions = String.join(auditWrap.enabledPermissions, ', ');
            result.add(auditWrap);
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<PermissionAuditWrapper> getPermissionSetAuditData() {
        Set<String> privPerms = new Set<String>();
        for (Privileged_Permission__mdt perm : [SELECT Permission_API_Name__c FROM Privileged_Permission__mdt]) privPerms.add(perm.Permission_API_Name__c);
        if (privPerms.isEmpty()) return new List<PermissionAuditWrapper>();

        Map<String, Schema.SObjectField> psFieldMap = Schema.SObjectType.PermissionSet.fields.getMap();
        Set<String> validPerms = new Set<String>();
        for (String p : privPerms) if (psFieldMap.containsKey(p)) validPerms.add(p);
        if (validPerms.isEmpty()) return new List<PermissionAuditWrapper>();

        String query = 'SELECT Id, Name, Label';
        for (String f : validPerms) query += ', ' + f;
        query += ' FROM PermissionSet WHERE IsOwnedByProfile = false ORDER BY Name ASC';

        List<SObject> permSets = Database.query(query);
        Set<Id> psIds = new Set<Id>();
        for (SObject ps : permSets) psIds.add((Id)ps.get('Id'));

        Map<Id, Integer> psUserCountMap = new Map<Id, Integer>();
        for (AggregateResult ar : [SELECT PermissionSetId psId, COUNT(Id) cnt FROM PermissionSetAssignment WHERE PermissionSetId IN :psIds GROUP BY PermissionSetId]) {
            psUserCountMap.put((Id)ar.get('psId'), (Integer)ar.get('cnt'));
        }

        List<PermissionAuditWrapper> result = new List<PermissionAuditWrapper>();
        List<ObjectPermissions> allObjPerms = [SELECT PermissionsViewAllRecords, PermissionsModifyAllRecords, ParentId FROM ObjectPermissions WHERE ParentId IN :psIds];

        Map<Id, Integer> psObjCountMap = new Map<Id, Integer>();
        for (ObjectPermissions op : allObjPerms) {
            if (op.PermissionsViewAllRecords || op.PermissionsModifyAllRecords) {
                psObjCountMap.put(op.ParentId, (psObjCountMap.get(op.ParentId) == null ? 0 : psObjCountMap.get(op.ParentId)) + 1);
            }
        }

        for (SObject ps : permSets) {
            List<String> enabledPerms = new List<String>();
            for (String f : validPerms) if ((Boolean)ps.get(f)) enabledPerms.add(psFieldMap.get(f).getDescribe().getLabel());
            if (!enabledPerms.isEmpty()) {
                Id psId = (Id)ps.get('Id');
                PermissionAuditWrapper auditWrap = new PermissionAuditWrapper();
                auditWrap.recordId = psId;
                auditWrap.name = (String)ps.get('Name');
                auditWrap.label = (String)ps.get('Label');
                auditWrap.type = 'PermissionSet';
                auditWrap.userCount = psUserCountMap.get(psId) != null ? psUserCountMap.get(psId) : 0;
                auditWrap.objectCount = psObjCountMap.get(psId) != null ? psObjCountMap.get(psId) : 0;
                auditWrap.enabledPermissions = enabledPerms;
                auditWrap.assignedPermissionCount = enabledPerms.size();
                auditWrap.assignedPermissions = String.join(enabledPerms, ', ');
                result.add(auditWrap);
            }
        }
        return result;
    }

    private static Boolean isValidId(String value) {
        try {
            Id tempId = (Id) value;
            return true;
        } catch (Exception e) {
            return false;
        }
    }


    @AuraEnabled(cacheable=true)
    public static List<ObjectPermissionsForUser> getPermissions(String currentId, String activeTab) {
         if (!isValidId(currentId)) {
            return new List<ObjectPermissionsForUser>();
        }
        List<Id> permissionSetIds = new List<Id>();
        if (activeTab == 'user') {
            List<User> users = [
                SELECT ProfileId
                FROM User
                WHERE Id = :currentId
                LIMIT 1
            ];
        
            if (users.isEmpty()) {
                return new List<ObjectPermissionsForUser>();
            }
        
            Id profileId = users[0].ProfileId;
        
            List<PermissionSet> psList = [
                SELECT Id
                FROM PermissionSet
                WHERE ProfileId = :profileId
            ];
        
            for (PermissionSet ps : psList) {
                permissionSetIds.add(ps.Id);
            }
        }
         else if(activeTab == 'profile') {
            List<PermissionSet> psList = [SELECT Id FROM PermissionSet WHERE ProfileId = :currentId];
            for(PermissionSet ps : psList) {
                permissionSetIds.add(ps.Id);
            }
        } else if(activeTab == 'permissionSet') {
            permissionSetIds.add(currentId);
        }
        if(permissionSetIds.isEmpty()) return new List<ObjectPermissionsForUser>();

        List<ObjectPermissions> objectPermissionList = [SELECT Id, PermissionsCreate, PermissionsRead, PermissionsEdit, PermissionsDelete,
            PermissionsViewAllRecords, PermissionsModifyAllRecords, SObjectType, ParentId FROM ObjectPermissions 
            WHERE ParentId IN :permissionSetIds ORDER BY SObjectType];
          
        Set<String> apiNames = new Set<String>();
        for (ObjectPermissions p : objectPermissionList) {
            apiNames.add(p.SObjectType);
        }
       
        List<EntityDefinition> entityDefinitionList = [  
            SELECT QualifiedApiName, Label 
            FROM EntityDefinition 
            WHERE QualifiedApiName IN :apiNames
        ];
        
        Map<String, String> apiToLabelMap = new Map<String, String>();
        for (EntityDefinition ed : entityDefinitionList) {
            if (!apiToLabelMap.containsKey(ed.QualifiedApiName)) {
                apiToLabelMap.put(ed.QualifiedApiName, ed.Label);
            }
        }

        List<ObjectPermissionsForUser> obejctPermissionWrapperList = new List<ObjectPermissionsForUser>(); 
        for (ObjectPermissions op : objectPermissionList) {
            if (!apiToLabelMap.containsKey(op.SObjectType) || !op.PermissionsRead) {
                continue;
            }
            ObjectPermissionsForUser permObj = new ObjectPermissionsForUser();   
            permObj.sObjectType = op.SObjectType;
            permObj.objectLabel = apiToLabelMap.get(op.SObjectType);
            permObj.createPerm = op.PermissionsCreate;
            permObj.readPerm = op.PermissionsRead;
            permObj.editPerm = op.PermissionsEdit;
            permObj.deletePerm = op.PermissionsDelete;
            permObj.viewAll = op.PermissionsViewAllRecords;
            permObj.modifyAll = op.PermissionsModifyAllRecords;
            obejctPermissionWrapperList.add(permObj);
        }
        return obejctPermissionWrapperList;
    }

    @AuraEnabled
    public static List<String> getPrivilegedPerms(String currentId, String recordType) {
        if(recordType == 'user'){ 
            List<User_Permissions__c> uppList = [SELECT Assigned_Permissions__c FROM User_Permissions__c WHERE User__c = :currentId LIMIT 1];
            if(uppList.isEmpty()) return new List<String>();
            return String.isNotBlank(uppList[0].Assigned_Permissions__c) ? uppList[0].Assigned_Permissions__c.split(';') : new List<String>();
        } else if(recordType == 'profile' || recordType == 'permissionSet') {
            return getPrivilegedPermissionsOfBoth(currentId, recordType);
        } else return new List<String>();
    }

    public static List<String> getPrivilegedPermissionsOfBoth(Id recordId, String sObjectType) {
        List<String> privilegedPermissionList = new List<String>();
        List<Privileged_Permission__mdt> privPerms = [SELECT Permission_API_Name__c, Display_Name__c FROM Privileged_Permission__mdt];
        if(privPerms.isEmpty()) return privilegedPermissionList;

        Map<String, Schema.SObjectField> fieldsMap = (sObjectType == 'Profile') ? Profile.SObjectType.getDescribe().fields.getMap() : PermissionSet.SObjectType.getDescribe().fields.getMap();
        Map<String, String> permissionApiToDisplayNameMap = new Map<String, String>();
        for (Privileged_Permission__mdt permObj : privPerms) {
            String api = permObj.Permission_API_Name__c.startsWith('Permissions') ? permObj.Permission_API_Name__c : 'Permissions' + permObj.Permission_API_Name__c;
            if (fieldsMap.containsKey(api)) permissionApiToDisplayNameMap.put(api, permObj.Display_Name__c);
        }
        if(permissionApiToDisplayNameMap.isEmpty()) return privilegedPermissionList;

        String query = 'SELECT Id';
        for (String fieldApi : permissionApiToDisplayNameMap.keySet()) query += ', ' + fieldApi;
        query += ' FROM ' + sObjectType + (sObjectType == 'PermissionSet' ? ' WHERE Id = :recordId AND IsOwnedByProfile = false' : ' WHERE Id = :recordId');

        SObject record = Database.query(query);
        for (String fieldApi : permissionApiToDisplayNameMap.keySet()) {
            if ((Boolean)record.get(fieldApi)) privilegedPermissionList.add(permissionApiToDisplayNameMap.get(fieldApi));
        }
        return privilegedPermissionList;
    }
}