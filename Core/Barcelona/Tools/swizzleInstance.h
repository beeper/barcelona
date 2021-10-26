//
//  swizzleInstance.h
//  imessage-rest
//
//  Created by Eric Rabil on 12/19/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import <objc/runtime.h>

void swizzleInstance(Class class, SEL original, SEL swizzled);
