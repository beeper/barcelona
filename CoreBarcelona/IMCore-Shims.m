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

@interface CNGeminiManager: NSObject
@end

@implementation CNGeminiManager: NSObject
@end

CommunicationsFilterBlockList* ERSharedBlockList() {
    return [NSClassFromString(@"CommunicationsFilterBlockList") sharedInstance];
}

IMPersonRegistrar* ERSharedPersonRegistrar() {
    return [NSClassFromString(@"IMPersonRegistrar") sharedInstance];
}

NSXPCListener* ERConstructXPCListener(NSString* machServiceName) {
    NSXPCListener* xpcListener = [NSXPCListener new];
    return [xpcListener performSelector:NSSelectorFromString(@"initWithMachServiceName:") withObject:machServiceName];
}
