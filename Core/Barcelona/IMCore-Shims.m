//
//  IMCore-Shims.m
//  imessage-rest
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommunicationsFilter.h>
#import <IMCore.h>
#import <IMSharedUtilities.h>
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

@implementation IMChatItem (CountFix)
-(int) count {
    return 1;
}
-(IMChatItem*) objectAtIndex:(id)index {
    return self;
}
@end

@implementation IMChatRegistry (IMChatRegistry_NerfedIntents)
-(void)setUserActivityForChat:(id)arg1 orHandles:(id)arg2 title:(id)arg3 {
    
}
-(void)setUserActivityForChat:(id)arg1 message:(id)arg2 orHandles:(id)arg3 title:(id)arg4 {
    
}
@end

@implementation IMContactStore (AlwaysCache)
+(BOOL)isContactsCachingEnabled {
    return NO;
}

+(BOOL)isContactsBatchingEnabled {
    return YES;
}
@end


NSArray<IMItem*>* ERCreateIMMessageItemsFromSerializedArray(NSArray<NSDictionary*>* serializedItems) {
    if ([serializedItems count] == 0) {
        return NULL;
    }
    NSMutableArray<IMItem*>* items = [[NSMutableArray alloc] init];
    for (NSDictionary* dict in serializedItems) {
        Class cls = [IMItem classForMessageItemDictionary:dict];
        if (cls == NULL) {
            continue;
        }
        IMItem* item = [[cls alloc] initWithDictionary:dict];
        if (item != NULL) {
            [items addObject:item];
        }
    }
    if ([items count] == 0) {
        return NULL;
    }
    return items;
}

NSArray<NSDictionary*>* ERCreateSerializedIMMessageItemsFromArray(NSArray<IMItem*>* items) {
    if ([items count] == 0) {
        return NULL;
    }
    NSMutableArray<NSDictionary*>* serializedItems = [[NSMutableArray alloc] init];
    for (IMItem* item in items) {
        NSDictionary* dictionary = [item dictionaryRepresentation];
        if ([dictionary count] == 0) {
            continue;
        }
        [serializedItems addObject:dictionary];
    }
    if ([serializedItems count] == 0) {
        return NULL;
    }
    return serializedItems;
}
