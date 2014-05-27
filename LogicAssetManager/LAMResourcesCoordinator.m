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


+ (NSString*)logicResourcesPath
{
    return @"/Applications/Logic Pro X.app/Contents/Frameworks/MAResources.framework/Versions/A/Resources";
}


+ (NSString*)logicMAResourcesMappingPath
{
    return [[self logicResourcesPath]stringByAppendingPathComponent:@"MAResourcesMapping.plist"];
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        _excludesRetinaImage=NO;
        _originalResourcesMapping=[[NSDictionary alloc]initWithContentsOfFile:[LAMResourcesCoordinator logicMAResourcesMappingPath]];
        _mergedResourcesMapping=[[NSMutableDictionary alloc]initWithContentsOfFile:[LAMResourcesCoordinator logicMAResourcesMappingPath]];
        _outputDirectory=[LAMAppDelegate mergedMAResourcesPath];
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
    
    self.mergedResourcesMapping=[[NSMutableDictionary alloc]initWithContentsOfFile:[LAMResourcesCoordinator logicMAResourcesMappingPath]];

    
    //extract original contents
    [self extractFromResourcesPath:[LAMResourcesCoordinator logicResourcesPath]];
    
    //extract each asset
    for (NSString* assetPath in assetPaths) {
        NSString* resourcesPath=[assetPath stringByAppendingPathComponent:@"MAResources"];
        [self extractFromResourcesPath:resourcesPath];
        
        NSString* plistPath=[resourcesPath stringByAppendingPathComponent:@"MAResourcesMapping.plist"];
        if ([[NSFileManager defaultManager]fileExistsAtPath:plistPath]) {
            [self mergeMappingFile:plistPath];
        }
    }
    
    //merged MAResourcesMapping.plist
    success=[self.mergedResourcesMapping writeToFile:[self.outputDirectory stringByAppendingPathComponent:@"MAResourcesMapping.plist"] atomically:YES];
    
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
        if ([fileName hasPrefix:@"."] || [fileName isEqualToString:@"MAResourcesMapping.plist"]) {
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
