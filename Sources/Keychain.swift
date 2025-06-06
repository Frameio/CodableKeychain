//
//  Keychain.swift
//
//  Copyright (c) 2017 Todd Kramer (http://www.tekramer.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import Security

public final class Keychain {

    public enum AccessError: Error {
        case invalidAccountRetrievalResult
        case invalidQueryResult
    }

    private enum Constants {
        static let accessible = kSecAttrAccessible.stringValue
        static let accessGroup = kSecAttrAccessGroup.stringValue
        static let account = kSecAttrAccount.stringValue
        static let `class` = kSecClass.stringValue
        static let matchLimit = kSecMatchLimit.stringValue
        static let returnData = kSecReturnData.stringValue
        static let returnAttributes = kSecReturnAttributes.stringValue
        static let service = kSecAttrService.stringValue
        static let valueData = kSecValueData.stringValue
        @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
        static let useDataProtectionKeychain = kSecUseDataProtectionKeychain.stringValue

        static let genericPassword = kSecClassGenericPassword.stringValue
        static let matchLimitOne = kSecMatchLimitOne.stringValue
        static let matchLimitAll = kSecMatchLimitAll.stringValue
    }

    nonisolated(unsafe) static var defaultIdentifier: String = Bundle.main.infoDictionary?[kCFBundleIdentifierKey.stringValue] as? String
        ?? "com.codablekeychain.service"
    nonisolated(unsafe) public private(set) static var defaultService: String = defaultIdentifier
    nonisolated(unsafe) public private(set) static var defaultAccessGroup: String? = nil
    nonisolated(unsafe) public private(set) static var defaultAccessibility: AccessibleOption = .whenUnlocked

    nonisolated(unsafe) public static let `default` = Keychain()

    let securityItemManager: SecurityItemManaging
    private let lock = NSRecursiveLock()

    init(securityItemManager: SecurityItemManaging = SecurityItemManager.default) {
        self.securityItemManager = securityItemManager
    }

    // MARK: - Public

    public static func configureDefaults(
        withService service: String = defaultService,
        accessGroup: String? = defaultAccessGroup,
        accessibility: AccessibleOption = defaultAccessibility
    ) {
        defaultService = service
        defaultAccessGroup = accessGroup
        defaultAccessibility = accessibility
    }

    public static func resetDefaults() {
        defaultService = defaultIdentifier
        defaultAccessGroup = nil
    }

    public func store<T: KeychainStorable>(_ storable: T, service: String = defaultService, accessGroup: String? = defaultAccessGroup) throws {
        let newData = try JSONEncoder().encode(storable)
        try store(newData, accessible: storable.accessible, account: storable.account, service: service, accessGroup: accessGroup)
    }

    @discardableResult
    private func store(_ newData: Data, accessible: AccessibleOption, account: String, service: String, accessGroup: String?, updateExisting: Bool = true) throws -> Bool {
        var query = self.query(forAccount: account, service: service, accessGroup: accessGroup)
        let newAttributes: [String: Any] = [Constants.valueData: newData, Constants.accessible: accessible.rawValue]
        let status = try lock.withLock {
            if updateExisting, try containsValue(forAccount: account, service: service, accessGroup: accessGroup) {
                return securityItemManager.update(withQuery: query, attributesToUpdate: newAttributes)
            } else {
                query.merge(newAttributes) { $1 }
                return securityItemManager.add(withAttributes: query, result: nil)
            }
        }
        if let error = error(fromStatus: status) {
            if updateExisting || error != .duplicateItem {
                throw error
            } else {
                return false
            }
        } else {
            return true
        }
    }

    public func retrieveValue<T: KeychainStorable>(forAccount account: String, service: String = defaultService,
                                                   accessGroup: String? = defaultAccessGroup) throws -> T? {
        guard let data = try data(forAccount: account, service: service, accessGroup: accessGroup) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    public func retrieveAccounts(withService service: String = defaultService, accessGroup: String? = defaultAccessGroup) throws -> [String] {
        try retrieveAccounts(withService: service, accessGroup: accessGroup, useDataProtection: true)
    }

    private func retrieveAccounts(withService service: String = defaultService, accessGroup: String? = defaultAccessGroup, useDataProtection: Bool) throws -> [String] {
        return try retrieveRecordAttributes(withService: service, accessGroup: accessGroup, useDataProtection: useDataProtection).compactMap { $0[Constants.account] as? String }
    }
    
    public func retrieveRecordAttributes(withService service: String = defaultService, accessGroup: String? = defaultAccessGroup) throws -> [[String: Any]] {
        try retrieveRecordAttributes(withService: service, accessGroup: accessGroup, useDataProtection: true)
    }
    
    private func retrieveRecordAttributes(withService service: String = defaultService, accessGroup: String? = defaultAccessGroup, useDataProtection: Bool) throws -> [[String: Any]] {
        var query = self.query(forAccount: nil, service: service, accessGroup: accessGroup, useDataProtection: useDataProtection)
        query[Constants.matchLimit] = Constants.matchLimitAll
        query[Constants.returnAttributes] = kCFBooleanTrue
        var result: AnyObject?
        let status = securityItemManager.copyMatching(query, result: &result)
        if let error = error(fromStatus: status), error != .itemNotFound { throw error }
        guard result != nil else { return [] }
        guard let attributes = result as? [[String: Any]] else { throw AccessError.invalidAccountRetrievalResult }
        return attributes
    }

    public func delete<T: KeychainStorable>(_ storable: T, service: String = defaultService, accessGroup: String? = defaultAccessGroup) throws {
        let query = self.query(forAccount: storable.account, service: service, accessGroup: accessGroup)
        try delete(withQuery: query)
    }

    public func clearAll(withService service: String = defaultService, accessGroup: String? = defaultAccessGroup) throws {
        let retrievedAccounts = try retrieveAccounts(withService: service, accessGroup: accessGroup)
        try retrievedAccounts.forEach {
            let query = self.query(forAccount: $0, service: service, accessGroup: accessGroup)
            try delete(withQuery: query)
        }
    }

    /// Migrates objects that were written prior to macOS 10.15 to a format that can be read on macOS 10.15 and later.
    @available(macOS 10.15, *)
    public func migrateObjectsFromPreCatalina(
        service: String = defaultService,
        accessGroup: String? = defaultAccessGroup,
        accessible: AccessibleOption = defaultAccessibility
    ) throws {
        let accounts = try retrieveAccounts(withService: service, accessGroup: accessGroup, useDataProtection: false)
        for account in accounts {
            guard let data = try self.data(forAccount: account, service: service, accessGroup: accessGroup, useDataProtection: false) else {
                continue
            }
            if try store(data, accessible: accessible, account: account, service: service, accessGroup: accessGroup, updateExisting: false) {
                try delete(withQuery: query(forAccount: account, service: service, accessGroup: accessGroup, useDataProtection: false))
            }
        }
    }

    // MARK: - Convenience

    func delete(withQuery query: [String: Any]) throws {
        let status = lock.withLock { securityItemManager.delete(withQuery: query) }
        if let error = error(fromStatus: status), error != .itemNotFound { throw error }
    }

    // MARK: - Query

    func query(forAccount account: String?, service: String, accessGroup: String?, useDataProtection: Bool = true) -> [String: Any] {
        var query: [String: Any] = [
            Constants.service: service,
            Constants.class: Constants.genericPassword
        ]
        if let account = account {
            query[Constants.account] = account
        }
        if let accessGroup = accessGroup {
            query[Constants.accessGroup] = accessGroup
        }
        if #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *) {
            query[Constants.useDataProtectionKeychain] = useDataProtection
        }
        return query
    }

    // MARK: - Data

    func data(forAccount account: String, service: String, accessGroup: String?, useDataProtection: Bool = true) throws -> Data? {
        var query = self.query(forAccount: account, service: service, accessGroup: accessGroup, useDataProtection: useDataProtection)
        query[Constants.matchLimit] = Constants.matchLimitOne
        query[Constants.returnData] = kCFBooleanTrue
        var result: AnyObject?
        let status = lock.withLock { securityItemManager.copyMatching(query, result: &result) }
        if let error = error(fromStatus: status) {
            if error == .itemNotFound {
                return nil
            } else {
                throw error
            }
        }
        guard let result else { return nil }
        guard let resultData = result as? Data else { throw AccessError.invalidQueryResult }
        return resultData
    }

    func containsValue(forAccount account: String, service: String, accessGroup: String?) throws -> Bool {
        var query = self.query(forAccount: account, service: service, accessGroup: accessGroup)
        query[Constants.matchLimit] = Constants.matchLimitOne
        let status = lock.withLock { securityItemManager.copyMatching(query, result: nil) }
        guard let error = error(fromStatus: status) else { return true }
        if error == .itemNotFound {
            return false
        } else {
            throw error
        }
    }

    // MARK: - Error

    func error(fromStatus status: OSStatus) -> KeychainError? {
        guard status != noErr && status != errSecSuccess else { return nil }
        return KeychainError(status)
    }

}
