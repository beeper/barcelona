//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Oct 15 2018 10:31:50).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2015 by Steve Nygard.
//

#import <MediaPlayer/MPMusicPlayerQueueDescriptor.h>

@class MPMediaItem, MPMediaItemCollection, MPMediaQuery;

@interface MPMusicPlayerMediaItemQueueDescriptor : MPMusicPlayerQueueDescriptor
{
    MPMediaQuery *_query;
    MPMediaItemCollection *_itemCollection;
    MPMediaItem *_startItem;
}

+ (_Bool)supportsSecureCoding;

@property(retain, nonatomic) MPMediaItem *startItem; // @synthesize startItem=_startItem;
- (_Bool)isEmpty;
@property(readonly, nonatomic) MPMediaItemCollection *itemCollection;
@property(readonly, copy, nonatomic) MPMediaQuery *query;
- (void)setEndTime:(double)arg1 forItem:(id)arg2;
- (void)setStartTime:(double)arg1 forItem:(id)arg2;
- (id)copyWithZone:(struct _NSZone *)arg1;
- (void)encodeWithCoder:(id)arg1;
- (id)initWithCoder:(id)arg1;
- (_Bool)isEqual:(id)arg1;
- (id)initWithItemCollection:(id)arg1;
- (id)initWithQuery:(id)arg1;

@end
