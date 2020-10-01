//
//  AppSupport+RocketBootstrap.m
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 9/30/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppSupport/AppSupport.h>

#ifdef __IPHONE_9_0
//#import "rocketbootstrap.h"
#import "dlfcn.h"
#import <os/log.h>

void *rockethandle;
void (*rocketbootstrap_distributedmessagingcenter_apply)(CPDistributedMessagingCenter*);
void (*rocketbootstrap_unlock)(const char*);

void ERTouchCPDistributedMessagingCenterInappropriately(CPDistributedMessagingCenter* center) {
    if (rocketbootstrap_distributedmessagingcenter_apply == nil) {
        if (rockethandle == nil) {
            rockethandle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_NOW);
        }
        
        *(void **)(&rocketbootstrap_distributedmessagingcenter_apply) = dlsym(rockethandle, "rocketbootstrap_distributedmessagingcenter_apply");
    }
    
    rocketbootstrap_distributedmessagingcenter_apply(center);
}

void ERUnlockMachPort(NSString* port) {
    if (rocketbootstrap_unlock == nil) {
        if (rockethandle == nil) {
            rockethandle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_NOW);
        }
        
        *(void **)(&rocketbootstrap_unlock) = dlsym(rockethandle, "rocketbootstrap_unlock");
    }
}
#else
void ERTouchCPDistributedMessagingCenterInappropriately(CPDistributedMessagingCenter* center) {
    
}

void ERUnlockMachPort(NSString* port) {
    
}
#endif
