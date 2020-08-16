//
//  imessage_rest_ios.m
//  imessage-rest-ios
//
//  Created by Eric Rabil on 8/15/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import "imessage_rest_ios.h"

@implementation imessage_rest_ios

// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
- (void)upperCaseString:(NSString *)aString withReply:(void (^)(NSString *))reply {
    NSString *response = [aString uppercaseString];
    reply(response);
}

@end
