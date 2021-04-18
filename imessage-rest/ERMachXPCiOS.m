//
//  ERMachXPCiOS.m
//  imessage-rest
//
//  Created by Eric Rabil on 9/21/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppSupport/AppSupport.h>
#import <os/log.h>
#import "kern_memorystatus.h"

void ERTellJetsamToFuckOff() {
    if (memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_HIGH_WATER_MARK, getpid(), 150, 0, 0) != 0 || memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT, getpid(), 200, 0, 0) != 0) {
        NSLog(@"Failed to tell Jetsam to fuck off! %s", strerror(errno));
        exit(1);
    }
}

NSXPCListener* ERMachXPCiOS(NSString* identifier) {
    os_log(os_log_create("ERMachXPC", "XPCConstruction"), "Constructing privileged mach listener with identifier %{public}@", identifier);
    return [[NSXPCListener alloc] performSelector:NSSelectorFromString(@"initWithMachServiceName:") withObject:identifier];
}

NSUInteger XPCPrivilegedOption() {
    return NSXPCConnectionPrivileged;
}
