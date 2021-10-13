//
//  IMCore-Shims.m
//  imessage-rest
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommunicationsFilter/CommunicationsFilter.h>
#import <IMCore/IMCore.h>
#import "swizzleInstance.h"

#ifndef TARGET_OS_IPHONE

@interface CNGeminiManager: NSObject
@end

@implementation CNGeminiManager: NSObject
@end

#endif

CommunicationsFilterBlockList* ERSharedBlockList() {
    return [NSClassFromString(@"CommunicationsFilterBlockList") sharedInstance];
}

NSXPCListener* ERConstructXPCListener(NSString* machServiceName) {
    NSXPCListener* xpcListener = [NSXPCListener new];
    return [xpcListener performSelector:NSSelectorFromString(@"initWithMachServiceName:") withObject:machServiceName];
}

@implementation IMChat (HistoryLoadingPatch)
+(void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzleInstance(IMChat.class, @selector(_updateChatItemsWithReason:block:shouldPost:), @selector(_ghetto_updateChatItemsWithReason:block:shouldPost:));
    });
}
-(void)_ghetto_updateChatItemsWithReason:(NSString*)arg2 block:(void *)arg3 shouldPost:(char)arg4 {
    /// Damn tired of this shit
    if (arg4 == 0x1) {
        arg4 = ![arg2 isEqualToString:@"history query"];
    }
    
    [self _ghetto_updateChatItemsWithReason:arg2 block:arg3 shouldPost:arg4];
}
@end

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
