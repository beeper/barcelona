//
//  swizzleInstance.m
//  CoreBarcelona
//
//  Created by Eric Rabil on 12/19/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import <objc/runtime.h>

void swizzleInstance(Class class, SEL original, SEL swizzled) {
    Method originalMethod = class_getInstanceMethod(class, original);
    Method swizzledMethod = class_getInstanceMethod(class, swizzled);
    
    BOOL didAddMethod = class_addMethod(class, original, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class, swizzled, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}
