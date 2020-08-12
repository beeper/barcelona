#import <Foundation/Foundation.h>
#import <IMCore/IMCore.h>
#import <LinkPresentation/LinkPresentation.h>

/*****************************************************************/

@protocol LPLinkViewDelegate<NSObject>

@optional
- (void)linkViewNeedsResize:(id)v1;
- (void)linkView:(id)v1 didFetchMetadata:(id)v2;
- (void)_linkViewMetadataDidBecomeComplete:(id)v1;
@end


/*****************************************************************/

@protocol LPLinkMetadataStatusTransformerDelegate<NSObject>
- (void)statusTransformerDidUpdate:(id)v1;
@end

/*****************************************************************/

@protocol LPLinkHTMLGeneratorDelegate<NSObject>

@optional
- (id)linkHTMLGenerator:(id)v1 URLForResource:(id)v2 withMIMEType:(id)v3;
- (void)linkHTMLGenerator:(id)v1 didFetchMetadata:(id)v2;
@end


/*****************************************************************/

@protocol RichLinkPluginDataSourceClient<NSObject>
- (id)rendererForRichLinkPluginDataSource:(id)v1;
- (void)richLinkPluginDataSource:(id)v1 didReceiveMetadata:(id)v2;
@end


/*****************************************************************/

@protocol IMTranscriptBalloonPlugInController<NSObject>
@property (readonly,copy) NSURL * balloonMediaFile;
@property (readonly,nonatomic) char shouldSuppressDrawingBalloon;
- (id)initWithDataSource:(id)v1 isFromMe:(char)v2;
- (id)documentFragmentForDocument:(id)v1;

@optional
- (id)balloonMediaFile;
- (char)shouldSuppressDrawingBalloon;
@end

@interface LPLinkMetadataStatusTransformer: NSObject
@end

@interface LPImage
@end

@interface LPVideo
@end

@interface LPLinkHTMLGenerator
@end


/*****************************************************************/

@interface RichLink : NSObject<NSSecureCoding> {
    char _placeholder;
    char _needsSubresourceFetch;
    char _needsCompleteFetch;
    LPLinkMetadata * _metadata;
}
@property (copy,nonatomic) LPLinkMetadata * metadata;
@property (nonatomic,getter=isPlaceholder) char placeholder;
@property (nonatomic) char needsSubresourceFetch;
@property (nonatomic) char needsCompleteFetch;
+ (char)supportsSecureCoding;
+ (id)linkWithDataRepresentation:(id)v1 attachments:(id)v2;
- (id)initWithCoder:(id)v1;
- (void)encodeWithCoder:(id)v1;
- (id)dataRepresentationWithOutOfLineAttachments:(id *)v1;
- (char)_needsWorkaroundForAppStoreTransformerCrash;
@end

/*****************************************************************/

@interface RichLinkPluginDataSource : IMBalloonPluginDataSource<LPLinkViewDelegate,LPLinkMetadataStatusTransformerDelegate> {
    LPMetadataProvider * _pendingMetadataProvider;
    NSHashTable * _clients;
    NSURL * _originalURL;
    LPLinkMetadataStatusTransformer * _statusTransformer;
    char _didSendPayload;
    char _didTapToLoad;
    char _shouldFetchWhenSent;
    char _hasDeferredResize;
    char _hasReceivedAnyPayload;
    char _didStartUpdateWatchdog;
    char _updateWatchdogDidFire;
    RichLink * _richLink;
    NSMutableDictionary * _resources;
}
@property (retain,nonatomic) RichLink * richLink;
@property (retain,nonatomic) NSMutableDictionary * resources;
@property (readonly,nonatomic) char hasPendingFetch;
@property (readonly,nonatomic) char metadataIsLikelyFinal;
@property (readonly,nonatomic) char isFromMe;
@property (readonly,copy,nonatomic) NSURL * originalURL;
@property (readonly,copy,nonatomic) NSString * storeIdentifier;
@property (readonly) unsigned long long hash;
@property (readonly) Class superclass;
@property (readonly,copy) NSString * description;
@property (readonly,copy) NSString * debugDescription;
+ (char)supportsURL:(id)v1;
+ (char)supportsIndividualPreviewSummaries;
+ (id)individualPreviewSummaryForPluginPayload:(id)v1;
- (char)_shouldAlwaysFetchEmptyLinksImmediately;
- (id)initWithPluginPayload:(id)v1;
- (id)richLinkMetadata;
- (void)addClient:(id)v1;
- (void)dispatchMetadataUpdateToAllClients;
- (void)startUpdateWatchdogIfNeeded;
- (void)dispatchDidReceiveMetadataToAllClients;
- (void)_startFetchingMetadata;
- (void)payloadWillEnterShelf;
- (id)createEmptyMetadataWithOriginalURL;
- (void)updateRichLinkWithFetchedMetadata:(id)v1;
- (void)payloadWillSendFromShelf;
- (void)_didFetchMetadata:(id)v1 error:(id)v2;
- (void)pluginPayloadDidChange:(unsigned long long)v1;
- (void)linkViewNeedsResize:(id)v1;
- (void)linkView:(id)v1 didFetchMetadata:(id)v2;
- (void)tapToLoadDidFetchMetadata:(id)v1;
- (id)individualPreviewSummary;
- (id)statusTransformer;
- (char)wantsStatusItem;
- (id)statusAttributedString;
- (void)didTapStatusItem;
- (void)statusTransformerDidUpdate:(id)v1;
@end


/*****************************************************************/

@interface RichLinkImageAttachmentSubstitute : LPImage<NSSecureCoding> {
    long long _index;
}
@property (nonatomic) long long index;
+ (char)supportsSecureCoding;
- (id)initWithImage:(id)v1;
- (id)initWithCoder:(id)v1;
- (void)encodeWithCoder:(id)v1;
- (char)_shouldEncodeData;
@end


/*****************************************************************/

@interface RichLinkVideoAttachmentSubstitute : LPVideo<NSSecureCoding> {
    long long _index;
}
@property (nonatomic) long long index;
+ (char)supportsSecureCoding;
- (id)initWithVideo:(id)v1;
- (id)initWithCoder:(id)v1;
- (void)encodeWithCoder:(id)v1;
- (char)_shouldEncodeData;
@end


/*****************************************************************/

@interface RichLinkAttachmentSubstituter : NSObject<NSKeyedArchiverDelegate,NSKeyedUnarchiverDelegate> {
    char _shouldSubstituteAttachments;
    char _shouldIgnoreAppStoreMetadata;
    NSMutableArray * _archivedAttachments;
    NSArray * _attachmentsForUnarchiving;
}
@property (readonly,copy,nonatomic) NSMutableArray * archivedAttachments;
@property (copy,nonatomic) NSArray * attachmentsForUnarchiving;
@property (nonatomic) char shouldSubstituteAttachments;
@property (nonatomic) char shouldIgnoreAppStoreMetadata;
@property (readonly) unsigned long long hash;
@property (readonly) Class superclass;
@property (readonly,copy) NSString * description;
@property (readonly,copy) NSString * debugDescription;
- (id)init;
- (id)archiver:(id)v1 willEncodeObject:(id)v2;
- (id)unarchiver:(id)v1 didDecodeObject:(id)v2;
@end


/*****************************************************************/

@interface RichLinkResource : NSObject {
    NSData * _data;
    NSString * _MIMEType;
}
@property (retain,nonatomic) NSData * data;
@property (retain,nonatomic) NSString * MIMEType;
@end


/*****************************************************************/

@interface RichLinkResourceProtocol : NSURLProtocol
+ (void)install;
+ (char)canInitWithRequest:(id)v1;
+ (id)canonicalRequestForRequest:(id)v1;
- (void)startLoading;
- (void)stopLoading;
@end



/*****************************************************************/

@interface RichLinkPluginController : NSObject<LPLinkHTMLGeneratorDelegate,RichLinkPluginDataSourceClient,IMTranscriptBalloonPlugInController> {
    RichLinkPluginDataSource * _dataSource;
    LPLinkHTMLGenerator * _generator;
}
@property (readonly) unsigned long long hash;
@property (readonly) Class superclass;
@property (readonly,copy) NSString * description;
@property (readonly,copy) NSString * debugDescription;
@property (readonly,copy) NSURL * balloonMediaFile;
@property (readonly,nonatomic) char shouldSuppressDrawingBalloon;
- (id)initWithDataSource:(id)v1 isFromMe:(char)v2;
- (id)documentFragmentForDocument:(id)v1;
- (char)shouldKeepPluginControllerAliveIndefinitely;
- (id)linkHTMLGenerator:(id)v1 URLForResource:(id)v2 withMIMEType:(id)v3;
- (id)rendererForRichLinkPluginDataSource:(id)v1;
- (void)richLinkPluginDataSource:(id)v1 didReceiveMetadata:(id)v2;
- (void)linkHTMLGenerator:(id)v1 didFetchMetadata:(id)v2;
- (char)isInteractive;
- (char)wantsTranscriptGroupMonograms;
- (char)wantsEdgeToEdgeLayout;
- (char)wantsBalloonGradient;
@end

/*****************************************************************/

@interface RichLinkPluginControllerKeepaliveEntry : NSObject {
    RichLinkPluginController * _pluginController;
    NSDate * _expirationTime;
}
@property (retain,nonatomic) RichLinkPluginController * pluginController;
@property (retain,nonatomic) NSDate * expirationTime;
@end
