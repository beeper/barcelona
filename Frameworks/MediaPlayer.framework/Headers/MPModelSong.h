//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Oct 15 2018 10:31:50).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2015 by Steve Nygard.
//

#import <MediaPlayer/MPModelObject.h>

@class MPGaplessInfo, MPModelAlbum, MPModelArtist, MPModelComposer, MPModelFileAsset, MPModelGenre, MPModelHomeSharingAsset, MPModelLyrics, MPModelPlaybackPosition, MPModelStoreAsset, NSDate, NSString;

@interface MPModelSong : MPModelObject
{
}

+ (id)__downloadedDate_KEY;
+ (id)__playbackPosition_KEY;
+ (id)__volumeAdjustment_KEY;
+ (id)__gaplessInfo_KEY;
+ (id)__userRating_KEY;
+ (id)__storeAsset_KEY;
+ (id)__homeSharingAsset_KEY;
+ (id)__year_KEY;
+ (id)__classicalMovementNumber_KEY;
+ (id)__classicalMovementCount_KEY;
+ (id)__classicalMovement_KEY;
+ (id)__classicalWork_KEY;
+ (id)__hasCloudSyncSource_KEY;
+ (id)__libraryAddEligible_KEY;
+ (id)__lastDevicePlaybackDate_KEY;
+ (id)__libraryAddedDate_KEY;
+ (id)__libraryAdded_KEY;
+ (id)__keepLocalManagedStatus_KEY;
+ (id)__keepLocalEnableState_KEY;
+ (id)__localFileAsset_KEY;
+ (id)__artworkCatalogBlock_KEY;
+ (id)__volumeNormalization_KEY;
+ (id)__shouldShowComposer_KEY;
+ (id)__lyrics_KEY;
+ (id)__beatsPerMinute_KEY;
+ (id)__hasVideo_KEY;
+ (id)__artistUploadedContent_KEY;
+ (id)__explicitSong_KEY;
+ (id)__skipCount_KEY;
+ (id)__playCount_KEY;
+ (id)__discNumber_KEY;
+ (id)__trackNumber_KEY;
+ (id)__trackCount_KEY;
+ (id)__duration_KEY;
+ (id)__copyrightText_KEY;
+ (id)__grouping_KEY;
+ (id)__composer_KEY;
+ (id)__genre_KEY;
+ (id)__artist_KEY;
+ (id)__album_KEY;
+ (id)__title_KEY;
+ (id)kindWithVariants:(unsigned long long)arg1 options:(unsigned long long)arg2;
+ (id)kindWithVariants:(unsigned long long)arg1;
+ (id)requiredLibraryAddStatusObservationProperties;
+ (_Bool)supportsLibraryAddStatusObservation;
+ (_Bool)supportsLibraryRemoval;
+ (id)requiredLibraryRemovalProperties;
+ (_Bool)supportsKeepLocalStatusObservation;
+ (id)requiredKeepLocalStatusObservationProperties;
+ (id)requiredStoreLibraryPersonalizationProperties;
- (id)artworkCatalog;
- (id)humanDescription;
- (id)mediaItemPropertyValues;
- (struct MPLibraryAddStatusObserverConfiguration)libraryAddStatusObserverConfiguration;
- (long long)libraryRemovalSupportedOptions;
- (id)newKeepLocalStatusObserverConfiguration;
- (id)objectWithStoreLibraryPersonalizationRelativeModelObject:(id)arg1;
- (id)relativeModelObjectForStoreLibraryPersonalization;
- (id)personalizationScopedPropertiesForProperties:(id)arg1;

// Remaining properties
@property(retain, nonatomic) MPModelAlbum *album; // @dynamic album;
@property(retain, nonatomic) MPModelArtist *artist; // @dynamic artist;
@property(nonatomic, getter=isArtistUploadedContent) _Bool artistUploadedContent; // @dynamic artistUploadedContent;
@property(copy, nonatomic) id artworkCatalogBlock; // @dynamic artworkCatalogBlock;
@property(nonatomic) long long beatsPerMinute; // @dynamic beatsPerMinute;
@property(copy, nonatomic) NSString *classicalMovement; // @dynamic classicalMovement;
@property(nonatomic) long long classicalMovementCount; // @dynamic classicalMovementCount;
@property(nonatomic) long long classicalMovementNumber; // @dynamic classicalMovementNumber;
@property(copy, nonatomic) NSString *classicalWork; // @dynamic classicalWork;
@property(retain, nonatomic) MPModelComposer *composer; // @dynamic composer;
@property(copy, nonatomic) NSString *copyrightText; // @dynamic copyrightText;
@property(nonatomic) long long discNumber; // @dynamic discNumber;
@property(readonly, copy, nonatomic) NSDate *downloadedDate; // @dynamic downloadedDate;
@property(nonatomic) double duration; // @dynamic duration;
@property(nonatomic, getter=isExplicitSong) _Bool explicitSong; // @dynamic explicitSong;
@property(retain, nonatomic) MPGaplessInfo *gaplessInfo; // @dynamic gaplessInfo;
@property(retain, nonatomic) MPModelGenre *genre; // @dynamic genre;
@property(copy, nonatomic) NSString *grouping; // @dynamic grouping;
@property(nonatomic) _Bool hasCloudSyncSource; // @dynamic hasCloudSyncSource;
@property(nonatomic) _Bool hasVideo; // @dynamic hasVideo;
@property(retain, nonatomic) MPModelHomeSharingAsset *homeSharingAsset; // @dynamic homeSharingAsset;
@property(nonatomic) long long keepLocalEnableState; // @dynamic keepLocalEnableState;
@property(nonatomic) long long keepLocalManagedStatus; // @dynamic keepLocalManagedStatus;
@property(readonly, copy, nonatomic) NSDate *lastDevicePlaybackDate; // @dynamic lastDevicePlaybackDate;
@property(nonatomic, getter=isLibraryAddEligible) _Bool libraryAddEligible; // @dynamic libraryAddEligible;
@property(nonatomic, getter=isLibraryAdded) _Bool libraryAdded; // @dynamic libraryAdded;
@property(copy, nonatomic) NSDate *libraryAddedDate; // @dynamic libraryAddedDate;
@property(retain, nonatomic) MPModelFileAsset *localFileAsset; // @dynamic localFileAsset;
@property(retain, nonatomic) MPModelLyrics *lyrics; // @dynamic lyrics;
@property(nonatomic) long long playCount; // @dynamic playCount;
@property(retain, nonatomic) MPModelPlaybackPosition *playbackPosition; // @dynamic playbackPosition;
@property(nonatomic) _Bool shouldShowComposer; // @dynamic shouldShowComposer;
@property(nonatomic) long long skipCount; // @dynamic skipCount;
@property(retain, nonatomic) MPModelStoreAsset *storeAsset; // @dynamic storeAsset;
@property(copy, nonatomic) NSString *title; // @dynamic title;
@property(nonatomic) long long trackCount; // @dynamic trackCount;
@property(nonatomic) long long trackNumber; // @dynamic trackNumber;
@property(nonatomic) float userRating; // @dynamic userRating;
@property(nonatomic) float volumeAdjustment; // @dynamic volumeAdjustment;
@property(nonatomic) float volumeNormalization; // @dynamic volumeNormalization;
@property(nonatomic) long long year; // @dynamic year;

@end
