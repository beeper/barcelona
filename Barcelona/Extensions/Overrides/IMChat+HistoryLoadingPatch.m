//
//  IMChat+HistoryLoadingPatch.m
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/19/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import <IMCore/IMCore.h>
#import <objc/runtime.h>
#import "swizzleInstance.h"

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
