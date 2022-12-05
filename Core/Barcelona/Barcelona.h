//
//  CoreBarcelona.h
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/15/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for CoreBarcelona.
FOUNDATION_EXPORT double CoreBarcelonaVersionNumber;

//! Project version string for CoreBarcelona.
FOUNDATION_EXPORT const unsigned char CoreBarcelonaVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <CoreBarcelona/PublicHeader.h>

#import <CommunicationsFilter.h>

CommunicationsFilterBlockList* ERSharedBlockList();
NSXPCListener* ERConstructXPCListener(NSString*);

@interface ObjC: NSObject
+ (id)catchException:(id(^)())tryBlock error:(__autoreleasing NSError **)error;
@end
