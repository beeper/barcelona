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

#import "Extensions/Overrides/IMChatItem+CountFix.m"
#import "Extensions/Overrides/IMBalloonPluginManager+IMBalloonPluginManager_GetOutOfMyWay.m"
#import "Extensions/Overrides/IMChatRegistry+NerfedIntents.m"
#import "Extensions/Overrides/IMChat+HistoryLoadingPatch.m"
#import "Extensions/Overrides/IMContactStore+NoOverrides.m"
#import "Extensions/Overrides/IMContactStore+AlwaysCache.m"

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
