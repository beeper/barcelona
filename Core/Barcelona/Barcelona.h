//
//  CoreBarcelona.h
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/15/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Contacts/CNContact.h>

//! Project version number for CoreBarcelona.
FOUNDATION_EXPORT double CoreBarcelonaVersionNumber;

//! Project version string for CoreBarcelona.
FOUNDATION_EXPORT const unsigned char CoreBarcelonaVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <CoreBarcelona/PublicHeader.h>

#import <CommunicationsFilter/CommunicationsFilter.h>

CommunicationsFilterBlockList* ERSharedBlockList();
NSXPCListener* ERConstructXPCListener(NSString*);

@interface CNPhoneNumber ()
- (nonnull instancetype)initWithStringValue:(nonnull NSString *)stringValue countryCode:(nullable NSString *)countryCode;
+(nonnull NSString*)dialingCodeForISOCountryCode:(nonnull NSString*)countryCode;
-(nonnull NSString*)digitsRemovingDialingCode;
@end

@interface CNPredicate : NSPredicate <NSCopying> {
    NSPredicate * _cn_predicate;
}
- (instancetype)initWithPredicate:(NSPredicate *)predicate NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;
- (NSPredicate *)cn_predicate;
@end
