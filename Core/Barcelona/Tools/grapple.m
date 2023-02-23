//
//  grapple.m
//  grapple
//
//  Created by Eric Rabil on 11/24/21.
//

#import <Foundation/Foundation.h>

@implementation ObjC: NSObject

+ (id)catchException:(id(^)())tryBlock error:(__autoreleasing NSError **)error {
    @try {
        id result = tryBlock();
        return result;
    }
    @catch (NSException *exception) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
        }
        return nil;
    }
}

@end
