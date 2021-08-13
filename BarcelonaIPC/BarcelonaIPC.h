//
//  BarcelonaIPC.h
//  BarcelonaIPC
//
//  Created by Eric Rabil on 8/12/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for BarcelonaIPC.
FOUNDATION_EXPORT double BarcelonaIPCVersionNumber;

//! Project version string for BarcelonaIPC.
FOUNDATION_EXPORT const unsigned char BarcelonaIPCVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <BarcelonaIPC/PublicHeader.h>

#if TARGET_OS_IPHONE

/*    NSPortMessage.h
    Copyright (c) 1994-2019, Apple Inc. All rights reserved.
*/

@class NSPort, NSDate, NSArray, NSMutableArray;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(PortMessage)
@interface NSPortMessage : NSObject {
    @private
    NSPort         *localPort;
    NSPort         *remotePort;
    NSMutableArray     *components;
    uint32_t        msgid;
    void        *reserved2;
    void        *reserved;
}

- (instancetype)initWithSendPort:(nullable NSPort *)sendPort receivePort:(nullable NSPort *)replyPort components:(nullable NSArray *)components NS_DESIGNATED_INITIALIZER;

@property (nullable, readonly, copy) NSArray *components;
@property (nullable, readonly, retain) NSPort *receivePort;
@property (nullable, readonly, retain) NSPort *sendPort;
- (BOOL)sendBeforeDate:(NSDate *)date;

@property uint32_t msgid;

@end

NS_ASSUME_NONNULL_END

#endif
