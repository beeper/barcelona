//
//  imessage_rest_ios.h
//  imessage-rest-ios
//
//  Created by Eric Rabil on 8/15/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "imessage_rest_iosProtocol.h"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface imessage_rest_ios : NSObject <imessage_rest_iosProtocol>
@end
