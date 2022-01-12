//
//  CNContact+Fuzz.swift
//  Barcelona
//
//  Created by Eric Rabil on 1/12/22.
//

import Foundation

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

internal extension CNContact {
    static func predicateForContacts(matchingHandleID handleID: String, countryCode: String) -> CNPredicate {
        with(CBCopyFuzzyPhoneNumbers(handleID, countryCode: countryCode)) { fuzzed in
            CNPredicate(format: "SUBQUERY(phoneNumbers, $rmo, ($rmo.value.unformattedInternationalStringValue IN %@ OR $rmo.value.digits IN %@)).@count != 0", fuzzed, fuzzed)
        }
    }
}
