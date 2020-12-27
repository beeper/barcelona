//
//  IMBalloonPluginManager+IMBalloonPluginManager_GetOutOfMyWay.m
//  imcore-rest
//
//  Created by Eric Rabil on 8/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import <IMCore/IMCore.h>
#import "swizzleInstance.h"

/**
 IMBallonPluginManager checks if I'm allowed to load balloon plugins... in the process... dumbest security ever.
 */
@implementation IMBalloonPluginManager (IMBalloonPluginManager_GetOutOfMyWay)
/**
 Mimic the behavior of the original init class (based on what I could ascertain from disassemblers) but without the security check
 */
+(void) load {
    static dispatch_once_t otherOnceToken;
    dispatch_once(&otherOnceToken, ^{
        swizzleInstance(IMBalloonPluginManager.class, @selector(dataSourceForPluginPayload:), @selector(_ghetto_dataSourceForPluginPayload:));
    });
}
-(IMBalloonPluginDataSource*) _ghetto_dataSourceForPluginPayload:(IMPluginPayload*)pluginPayload {
    if (pluginPayload.pluginBundleID == nil) {
        NSLog(@"pluginPayload.pluginBundleID == nil for messageGUID %@", pluginPayload.messageGUID);
    }
    
    return [self _ghetto_dataSourceForPluginPayload:pluginPayload];
}
@end

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
