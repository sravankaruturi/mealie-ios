//
//  User.swift
//  mealie
//
//  Created by Sravan Karuturi on 8/7/25.
//
import SwiftData

@Model
final class User {
    
    @Attribute(.unique) var id: String
    var username: String?
    var fullName: String?
    var email: String
    var authMethod: String?
    var admin: Bool?
    var group: String
    var household: String
    var advanced: Bool?
    var canInvite: Bool?
    var canManage: Bool?
    var canManageHousehold: Bool?
    var canOrganize: Bool?
    var groupId: String
    var groupSlug: String
    var householdId: String
    var householdSlug: String
    
    init(id: String, username: String? = nil, fullName: String? = nil, email: String, authMethod: String? = nil, admin: Bool? = nil, group: String, household: String, advanced: Bool? = nil, canInvite: Bool? = nil, canManage: Bool? = nil, canManageHousehold: Bool? = nil, canOrganize: Bool? = nil, groupId: String, groupSlug: String, householdId: String, householdSlug: String) {
        self.id = id
        self.username = username
        self.fullName = fullName
        self.email = email
        self.authMethod = authMethod
        self.admin = admin
        self.group = group
        self.household = household
        self.advanced = advanced
        self.canInvite = canInvite
        self.canManage = canManage
        self.canManageHousehold = canManageHousehold
        self.canOrganize = canOrganize
        self.groupId = groupId
        self.groupSlug = groupSlug
        self.householdId = householdId
        self.householdSlug = householdSlug
    }
    
    convenience init(from user: Components.Schemas.UserOut) {
        
        self.init(
            id: user.id,
            username: user.username,
            fullName: user.fullName,
            email: user.email,
            authMethod: user.authMethod?.rawValue,
            admin: user.admin,
            group: user.group,
            household: user.household,
            advanced: user.advanced,
            canInvite: user.canInvite,
            canManage: user.canManage,
            canManageHousehold: user.canManageHousehold,
            canOrganize: user.canOrganize,
            groupId: user.groupId,
            groupSlug: user.groupSlug,
            householdId: user.householdId,
            householdSlug: user.householdSlug
        )
        
    }
    
}
