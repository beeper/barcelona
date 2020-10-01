//
//  BarcelonaFoundation.h
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 9/25/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for BarcelonaFoundation.
FOUNDATION_EXPORT double BarcelonaFoundationVersionNumber;

//! Project version string for BarcelonaFoundation.
FOUNDATION_EXPORT const unsigned char BarcelonaFoundationVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <BarcelonaFoundation/PublicHeader.h>


#ifdef __IPHONE_9_0
#import "xpc.h"
#import "AppSupport+RocketBootstrap.h"
#endif
