//
//  IMChatItem+CountFix.m
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import <IMCore/IMCore.h>

@implementation IMChatItem (CountFix)
-(int) count {
    return 1;
}
-(IMChatItem*) objectAtIndex:(id)index {
    return self;
}
@end
