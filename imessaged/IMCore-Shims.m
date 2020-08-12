//
//  IMCore-Shims.m
//  imessaged
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import <CommunicationsFilter/CommunicationsFilter.h>
#import "RichLinkProvider.h"

@implementation CNGeminiManager: NSObject
@end

CommunicationsFilterBlockList* ERSharedBlockList() {
    return [NSClassFromString(@"CommunicationsFilterBlockList") sharedInstance];
}

RichLinkPluginDataSource* ERValidateDataSource(id arg1) {
    if ([arg1 isKindOfClass:NSClassFromString(@"RichLinkPluginDataSource")]) {
        return arg1;
    }
    return nil;
}
