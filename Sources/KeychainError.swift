//
//  KeychainError.swift
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

public struct KeychainError: Hashable, LocalizedError, CustomNSError {

    static var allocate: Self { .init(errSecAllocate) }
    static var authenticationFailed: Self { .init(errSecAuthFailed) }
    static var bufferTooSmall: Self { .init(errSecBufferTooSmall) }
    static var createChainFailed: Self { .init(errSecCreateChainFailed) }
    static var dataNotAvailable: Self { .init(errSecDataNotAvailable) }
    static var dataNotModifiable: Self { .init(errSecDataNotModifiable) }
    static var dataTooLarge: Self { .init(errSecDataTooLarge) }
    static var decode: Self { .init(errSecDecode) }
    static var duplicateCallback: Self { .init(errSecDuplicateCallback) }
    static var duplicateItem: Self { .init(errSecDuplicateItem) }
    static var duplicateKeychain: Self { .init(errSecDuplicateKeychain) }
    static var inDarkWake: Self { .init(errSecInDarkWake) }
    static var interactionNotAllowed: Self { .init(errSecInteractionNotAllowed) }
    static var interactionRequired: Self { .init(errSecInteractionRequired) }
    static var invalidCallback: Self { .init(errSecInvalidCallback) }
    static var invalidKeychain: Self { .init(errSecInvalidKeychain) }
    static var invalidItemReference: Self { .init(errSecInvalidItemRef) }
    static var invalidParameters: Self { .init(errSecParam) }
    static var invalidPreferenceDomain: Self { .init(errSecInvalidPrefsDomain) }
    static var invalidSearchReference: Self { .init(errSecInvalidSearchRef) }
    static var itemNotFound: Self { .init(errSecItemNotFound) }
    static var keySizeNotAllowed: Self { .init(errSecKeySizeNotAllowed) }
    static var missingEntitlement: Self { .init(errSecMissingEntitlement) }
    static var noCertificateModule: Self { .init(errSecNoCertificateModule) }
    static var noDefaultKeychain: Self { .init(errSecNoDefaultKeychain) }
    static var noPolicyModule: Self { .init(errSecNoPolicyModule) }
    static var noStorageModule: Self { .init(errSecNoStorageModule) }
    static var noSuchAttribute: Self { .init(errSecNoSuchAttr) }
    static var noSuchClass: Self { .init(errSecNoSuchClass) }
    static var noSuchKeychain: Self { .init(errSecNoSuchKeychain) }
    static var notAvailable: Self { .init(errSecNotAvailable) }
    static var readOnly: Self { .init(errSecReadOnly) }
    static var readOnlyAttribute: Self { .init(errSecReadOnlyAttr) }
    static var unimplemented: Self { .init(errSecUnimplemented) }
    static var wrongVersion: Self { .init(errSecWrongSecVersion) }

    public let errorCode: OSStatus
    public var errorDomain: String { "com.codablekeychain" }

    public var errorDescription: String? {
        if #available(iOS 11.3, tvOS 11.3, watchOS 4.3, macOS 10.3, *) {
            return SecCopyErrorMessageString(errorCode, nil) as String?
        }
        switch self {
        case .allocate:
            return "Failed to allocate memory."
        case .authenticationFailed:
            return "Authorization and/or authentication failed."
        case .bufferTooSmall:
            return "The buffer is too small."
        case .createChainFailed:
            return "The attempt to create a certificate chain failed."
        case .dataNotAvailable:
            return "The data is not available."
        case .dataNotModifiable:
            return "The data is not modifiable."
        case .dataTooLarge:
            return "The data is too large for the particular data type."
        case .decode:
            return "Unable to decode the provided data."
        case .duplicateCallback:
            return "More than one callback of the same name exists."
        case .duplicateItem:
            return "The item already exists."
        case .duplicateKeychain:
            return "A keychain with the same name already exists."
        case .inDarkWake:
            return "The user interface cannot be displayed because the system is in a dark wake state."
        case .interactionNotAllowed:
            return "Interaction with the Security Server is not allowed."
        case .interactionRequired:
            return "User interaction is required."
        case .invalidCallback:
            return "The callback is not valid."
        case .invalidItemReference:
            return "The item reference is invalid."
        case .invalidKeychain:
            return "The keychain is not valid."
        case .invalidParameters:
            return "One or more parameters passed to the function are not valid."
        case .invalidPreferenceDomain:
            return "The preference domain specified is invalid."
        case .invalidSearchReference:
            return "The search reference is invalid."
        case .itemNotFound:
            return "The item cannot be found."
        case .keySizeNotAllowed:
            return "The key size is not allowed."
        case .missingEntitlement:
            return "Keychain entitlement has not been added."
        case .noCertificateModule:
            return "There is no certificate module available."
        case .noDefaultKeychain:
            return "A default keychain does not exist."
        case .noPolicyModule:
            return "There is no policy module available."
        case .noStorageModule:
            return "There is no storage module available."
        case .noSuchAttribute:
            return "The attribute does not exist."
        case .noSuchClass:
            return "The keychain item class does not exist."
        case .noSuchKeychain:
            return "The keychain does not exist."
        case .notAvailable:
            return "No trust results are available."
        case .readOnly:
            return "Read only error."
        case .readOnlyAttribute:
            return "The attribute is read only."
        case .unimplemented:
            return "A function or operation is not implemented."
        case .wrongVersion:
            return "The version is incorrect."
        default:
            return "An unknown error occurred."
        }
    }

    public init(_ errorCode: OSStatus) {
        self.errorCode = errorCode
    }

}
