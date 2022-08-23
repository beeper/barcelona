//
//  CNContact+Fuzz.swift
//  Barcelona
//
//  Created by Eric Rabil on 1/12/22.
//

import Foundation
import IMSharedUtilities
import CBarcelona

internal func CBCopyPhoneNumberWithoutDialingCode(_ phoneNumber: String, countryCode: String) -> String {
    CNPhoneNumber(stringValue: phoneNumber, countryCode: countryCode).digitsRemovingDialingCode()
}

internal func CBCopyFuzzyPhoneNumbers(_ phoneNumber: String, countryCode: String) -> [String] {
    let stripped = CBCopyPhoneNumberWithoutDialingCode(phoneNumber, countryCode: countryCode)
    
    return [phoneNumber, stripped, "0" + stripped]
}

private func with<A,B>(_ value: @autoclosure () -> A, _ block: (A) throws -> B) rethrows -> B {
    try block(value())
}

private let _PNCopyIndexStringsForAddressBookSearch: (
    @convention(c) (CFString, CFString) -> Unmanaged<CFArray>
) = CBWeakLink(against: .privateFramework(name: "CorePhoneNumbers"), .symbol("_PNCopyIndexStringsForAddressBookSearch"))!

internal extension CNContact {
    static func predicateForContacts(matchingHandleID handleID: String, countryCode: String) -> CNPredicate {
        with(CBCopyFuzzyPhoneNumbers(handleID, countryCode: countryCode)) { fuzzed in
            CNPredicate(format: "SUBQUERY(phoneNumbers, $rmo, ($rmo.value.unformattedInternationalStringValue IN %@ OR $rmo.value.digits IN %@)).@count != 0", fuzzed, fuzzed)
        }
    }
}

internal extension CNContact {
    static func contact(matchingHandleID handleID: String, countryCode: String) throws -> CNContact? {
        let fuzzyNumbers = CBCopyFuzzyPhoneNumbers(handleID, countryCode: countryCode)
        
        for contact in try IMContactStore.sharedInstance().contactStore.unifiedContacts(matching: CNContact.predicateForContacts(matchingHandleStrings: fuzzyNumbers), keysToFetch: IMContactStore.keysForCNContact() as! [CNKeyDescriptor]) {
            for phoneNumber in contact.phoneNumbers {
                if fuzzyNumbers.contains(phoneNumber.value.unformattedInternationalStringValue()) || fuzzyNumbers.contains(phoneNumber.value.digits()) {
                    return contact
                }
            }
        }
        
        return nil
    }
}
