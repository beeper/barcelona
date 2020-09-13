//
//  IMContactStore+AlwaysCache.m
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import <IMSharedUtilities/IMContactStore.h>

@implementation IMContactStore (AlwaysCache)
+(BOOL)isContactsCachingEnabled {
    return YES;
}
@end
