//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Oct 15 2018 10:31:50).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2015 by Steve Nygard.
//

#import <objc/NSObject.h>

#import <MediaPlayer/MPAVErrorResolverDelegate-Protocol.h>

@class MPAVErrorResolver, NSString;

@interface MPAVErrorResolverBlockHandler : NSObject
{
    MPAVErrorResolverBlockHandler *_strongSelf;
    MPAVErrorResolver *_errorResolver;
    id _resolutionHandler;
}


@property(copy, nonatomic) id resolutionHandler; // @synthesize resolutionHandler=_resolutionHandler;
@property(readonly, nonatomic) MPAVErrorResolver *errorResolver; // @synthesize errorResolver=_errorResolver;
- (void)resolveError:(id)arg1;
- (void)errorResolver:(id)arg1 didResolveError:(id)arg2 withResolution:(long long)arg3;
- (id)initWithErrorResolver:(id)arg1;

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long hash;
@property(readonly) Class superclass;

@end
