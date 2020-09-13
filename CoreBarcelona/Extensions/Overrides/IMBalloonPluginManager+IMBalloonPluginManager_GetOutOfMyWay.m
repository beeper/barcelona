//
//  IMBalloonPluginManager+IMBalloonPluginManager_GetOutOfMyWay.m
//  imcore-rest
//
//  Created by Eric Rabil on 8/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

#import <IMCore/IMCore.h>
#import <objc/runtime.h>

Method originalMethod;

/**
 IMBallonPluginManager checks if I'm allowed to load balloon plugins... in the process... dumbest security ever.
 */
@implementation IMBalloonPluginManager (IMBalloonPluginManager_GetOutOfMyWay)
/**
 Mimic the behavior of the original init class (based on what I could ascertain from disassemblers) but without the security check
 */
-(id) init {
    self = [super init];
    
    if (self.pluginsMap == nil) {
        self.pluginsMap = [[NSMutableDictionary alloc] init];
    }
    
    [self _loadAllDataSources];
    
    [self setValue:NSClassFromString(@"RichLinkPluginDataSource") forKey:@"_richLinksDataSourceClass"];
    
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSURL *url = [defaultManager URLForDirectory:0x5 inDomain:0x1 appropriateForURL:0x0 create:0x1 error:0x0];
    NSURL *url2 = [url URLByAppendingPathComponent:@"Messages" isDirectory:0x1];
    NSString *path = [url2 path];
    
    self.pluginMetaDataFolder = path;
    
    if (self.pluginIDToMetadataCache != nil) {
        [self.pluginIDToMetadataCache removeAllObjects];
    }
    
    self.pluginIDToMetadataCache = [[NSMutableDictionary alloc] init];
    
    NSLog(@"🎶 Used to be bi but now im just het-ro 🎵");
    
    return self;
}
@end
