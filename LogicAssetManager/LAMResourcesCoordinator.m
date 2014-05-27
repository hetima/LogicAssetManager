//
//  LAMResourcesCoordinator.m
//  LogicAssetManager
//
//  Created by hetima on 2014/05/24.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import "LAMResourcesCoordinator.h"
#import "LAMAppDelegate.h"

@implementation LAMResourcesCoordinator

+ (instancetype)MAResourcesCoordinator
{
    static LAMMAResourcesCoordinator* MAResourcesCdntr=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MAResourcesCdntr=[[LAMMAResourcesCoordinator alloc]initWithResourcesName:@"MAResources" mappingFileName:@"MAResourcesMapping.plist"];
    });
    return MAResourcesCdntr;
}


+ (instancetype)MAResourcesPlugInsSharedCoordinator
{
    static LAMResourcesCoordinator* MAResourcesPlugInsSharedCdntr=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MAResourcesPlugInsSharedCdntr=[[LAMResourcesCoordinator alloc]initWithResourcesName:@"MAResourcesPlugInsShared" mappingFileName:@"MAResourcesPlugInsSharedMapping.plist"];
    });
    return MAResourcesPlugInsSharedCdntr;
}


+ (instancetype)MAResourcesLgCoordinator
{
    static LAMResourcesCoordinator* MAResourcesLgCdntr=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MAResourcesLgCdntr=[[LAMResourcesCoordinator alloc]initWithResourcesName:@"MAResourcesLg" mappingFileName:@"MAResourcesLgMapping.plist"];
    });
    return MAResourcesLgCdntr;
}


+ (instancetype)MAResourcesGBCoordinator
{
    static LAMResourcesCoordinator* MAResourcesGBCdntr=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MAResourcesGBCdntr=[[LAMResourcesCoordinator alloc]initWithResourcesName:@"MAResourcesGB" mappingFileName:@"MAResourcesGBMapping.plist"];
    });
    return MAResourcesGBCdntr;
}


+ (NSString*)logicFrameworkPathForName:(NSString*)name
{
    return [NSString stringWithFormat:@"/Applications/Logic Pro X.app/Contents/Frameworks/%@.framework", name];
}


- (NSString*)originalMappingPath
{
    return [_originalResourcesPath stringByAppendingPathComponent:_mappingFileName];
}


- (instancetype)initWithResourcesName:(NSString*)resourcesName mappingFileName:(NSString*)mappingFileName
{
    self = [super init];
    if (self) {
        NSString* frameworkPath=[LAMResourcesCoordinator logicFrameworkPathForName:resourcesName];
        _excludesRetinaImage=NO;
        _mappingFileName=mappingFileName;
        _resourcesName=resourcesName;
        _originalResourcesPath=[frameworkPath stringByAppendingPathComponent:@"Versions/A/Resources"];
        _resourcesLinkPath=[frameworkPath stringByAppendingPathComponent:@"Resources"];
        
        _originalResourcesMapping=[[NSDictionary alloc]initWithContentsOfFile:[self originalMappingPath]];
        _mergedResourcesMapping=[[NSMutableDictionary alloc]initWithContentsOfFile:[self originalMappingPath]];
        _outputDirectory=[LAMAppDelegate mergedResourcesPathForName:_resourcesName];
    }
    return self;
}


- (BOOL)extractFromAssetPaths:(NSArray*)assetPaths
{
    BOOL success=NO;
    if (!self.outputDirectory) {
        return success;
    }
    
    //clean up
    if ([[NSFileManager defaultManager]fileExistsAtPath:self.outputDirectory]) {
        success=[[NSFileManager defaultManager]removeItemAtPath:self.outputDirectory error:nil];
        if (!success) {
            return success;
        }
    }
    success=[[NSFileManager defaultManager]createDirectoryAtPath:self.outputDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    if (!success) {
        return success;
    }
    
    //FIXME: icon 消えちゃう
    self.mergedResourcesMapping=[[NSMutableDictionary alloc]initWithContentsOfFile:[self originalMappingPath]];

    
    //extract original contents
    [self extractFromResourcesPath:self.originalResourcesPath];
    
    //extract each asset
    for (NSString* assetPath in assetPaths) {
        NSString* resourcesPath=[assetPath stringByAppendingPathComponent:self.resourcesName];
        [self extractFromResourcesPath:resourcesPath];
        
        NSString* plistPath=[resourcesPath stringByAppendingPathComponent:self.mappingFileName];
        if ([[NSFileManager defaultManager]fileExistsAtPath:plistPath]) {
            [self mergeMappingFile:plistPath];
        }
    }
    
    //merged MAResourcesMapping.plist
    success=[self.mergedResourcesMapping writeToFile:[self.outputDirectory stringByAppendingPathComponent:self.mappingFileName] atomically:YES];
    
    return success;
}


- (void)extractFromResourcesPath:(NSString*)resourcesPath
{
    BOOL isDir;
    [[NSFileManager defaultManager]fileExistsAtPath:resourcesPath isDirectory:&isDir];
    
    if (!self.outputDirectory || !isDir) {
        return;
    }
    
    
    NSArray* files=[[NSFileManager defaultManager]contentsOfDirectoryAtPath:resourcesPath error:nil];
    
    
    for (NSString* fileName in files) {
        if ([fileName hasPrefix:@"."] || [fileName isEqualToString:self.mappingFileName]) {
            continue;
        }
        if (self.excludesRetinaImage && [[fileName stringByDeletingLastPathComponent]hasSuffix:@"@2x"]) {
            continue;
        }
        
        NSString* destPath=[resourcesPath stringByAppendingPathComponent:fileName];
        NSString* linkPath=[self.outputDirectory stringByAppendingPathComponent:fileName];
        NSError* err;
        
        if ([[NSFileManager defaultManager]fileExistsAtPath:linkPath]) {
            [[NSFileManager defaultManager]removeItemAtPath:linkPath error:nil];
        }
        [[NSFileManager defaultManager]createSymbolicLinkAtPath:linkPath withDestinationPath:destPath error:&err];
        
    }
    
}


- (void)mergeDictionary:(NSMutableDictionary*)dic base:(NSDictionary*)base merged:(NSMutableDictionary*)merged
{
    if (   !dic
        || ![dic isKindOfClass:[NSDictionary class]]
        || ![base isKindOfClass:[NSDictionary class]]
        || ![merged isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    for (NSString* key in base) {
        id dicObj=[dic objectForKey:key];
        if (!dicObj) {
            continue;
        }
        id baseObj=[base objectForKey:key];
        id mergedObj=[merged objectForKey:key];
        
        if ([dicObj isKindOfClass:[NSDictionary class]]) {
            if (![baseObj isKindOfClass:[NSDictionary class]]) continue;

            [self mergeDictionary:dicObj base:baseObj merged:mergedObj];
            
        }else if ([dicObj isKindOfClass:[NSArray class]]) {
            if (![baseObj isKindOfClass:[NSArray class]]) continue;
            
            //gradient
            //TrackHeaderPianoKeyboard.lod_thresholds_key_ebony
            //TrackHeaderPianoKeyboard.lod_thresholds_key_ivory
            //AnimalEditorDrumKitControl.Default.imageMapLayers
            //AnimalEditorDrumKitControl.Default.mouseOverGroups
            //and Instrument icons
            
            NSInteger cnt=[baseObj count];
            if ([dicObj count]!=cnt) {
                if ([key isEqualToString:@"gradient"]) {
                    [merged setObject:dicObj forKey:key];
                }
                continue;
            }else if([mergedObj count]==cnt){ //same count
                NSInteger i;
                for (i=0; i<cnt; i++) {
                    id child=[dicObj objectAtIndex:i];
                    //simply supports only dictionary
                    if ([child isKindOfClass:[NSDictionary class]]) {
                        [self mergeDictionary:child base:[baseObj objectAtIndex:i] merged:[mergedObj objectAtIndex:i]];
                    }
                }
            }
            
        }else if(![dicObj isEqualTo:baseObj]){
            [merged setObject:dicObj forKey:key];
        }
    }
    
}


- (void)mergeMappingDictionary:(NSMutableDictionary*)dict
{
    if ([dict objectForKey:@"AssetSets"]) {
        [self mergeDictionary:dict base:self.originalResourcesMapping merged:self.mergedResourcesMapping];
    }
}


- (void)mergeMappingFile:(NSString*)plistPath
{
    NSMutableDictionary* dict=[[NSMutableDictionary alloc]initWithContentsOfFile:plistPath];
    [self mergeMappingDictionary:dict];
}


@end




@implementation LAMMAResourcesCoordinator


- (void)addInstrumentIcon:(NSString*)name id:(NSInteger)imageId group:(NSString*)group
{
    if (imageId<1000 || imageId>=4096) {
        return;
    }
    if (![group length]) {
        group=@"BasicSetOther";
    }
    
    NSString* iconKey=[NSString stringWithFormat:@"InstrumentIcon_%04ld", imageId];
    NSMutableDictionary* iconInfo=[[NSMutableDictionary alloc]initWithCapacity:3];
    iconInfo[@"description"]=[NSString stringWithFormat:@"NSString:%@", name];
    iconInfo[@"id"]=@(imageId);
    iconInfo[@"image"]=name;
    NSMutableDictionary* allInstrumentIcons=[self allInstrumentIcons];
    allInstrumentIcons[iconKey]=iconInfo;
    
    NSMutableArray* groupArray=[self iconGroupWithName:group];
    NSString* assetRef=[NSString stringWithFormat:@"AssetRef:InstrumentIcons.AllInstrumentIcons.%@", iconKey];
    [groupArray addObject:assetRef];
    
}


- (id)assetSet:(NSString*)set fromFamily:(NSString*)family
{
    return [[[self.mergedResourcesMapping objectForKey:@"AssetSets"]objectForKey:family]objectForKey:set];
}


- (NSMutableArray*)iconGroupWithName:(NSString*)name
{
    NSMutableDictionary* instrumentIconGroups=[self instrumentIconGroups];
    NSMutableArray* group=[instrumentIconGroups objectForKey:name];
    if (!group) {
        group=[[NSMutableArray alloc]init];
        [instrumentIconGroups setObject:group forKey:name];
        
        NSString* iconGroupAssetRef=[NSString stringWithFormat:@"AssetRef:InstrumentIcons.InstrumentIconGroups.%@", name];
        NSString* iconGroupKey=[NSString stringWithFormat:@"NSString:%@", name];
        NSMutableDictionary* iconCategory=[[NSMutableDictionary alloc]initWithCapacity:2];
        iconCategory[@"IconGroup"]=iconGroupAssetRef;
        iconCategory[@"IconGroupKey"]=iconGroupKey;
        
        [[self authoringIconCategories]addObject:iconCategory];
        [[self sortedIconCategories]addObject:iconCategory];
    }
    
    return group;
}

- (NSMutableDictionary*)allInstrumentIcons
{
    return [self assetSet:@"AllInstrumentIcons" fromFamily:@"InstrumentIcons"];
}


- (NSMutableDictionary*)instrumentIconGroups
{
    return [self assetSet:@"InstrumentIconGroups" fromFamily:@"InstrumentIcons"];
}


- (NSMutableArray*)authoringIconCategories
{
    return [[self assetSet:@"InstrumentIconGroups" fromFamily:@"InstrumentIcons"]objectForKey:@"AuthoringIconCategories"];
}


- (NSMutableArray*)sortedIconCategories
{
    return [[self assetSet:@"InstrumentIconGroups" fromFamily:@"InstrumentIcons"]objectForKey:@"SortedIconCategories"];
}


@end
