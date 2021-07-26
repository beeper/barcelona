//
//  IMBalloonPluginManager+IMBalloonPluginManager_GetOutOfMyWay.m
//  imcore-rest
//
//  Created by Eric Rabil on 8/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import <IMCore/IMCore.h>
#import "swizzleInstance.h"

//IMP originalImplementation;

@implementation NSBundle (I_AM_GOD)
+(void) load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzleInstance([self class], @selector(bundleIdentifier), @selector(_ghetto_bundleIdentifier));
    });
}
-(NSString*)_ghetto_bundleIdentifier {
    if (self != [NSBundle mainBundle]) {
        return [self _ghetto_bundleIdentifier];
    }
    
    return @"com.apple.iChat";
}
@end
