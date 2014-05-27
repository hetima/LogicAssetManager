//
//  LAMUserAssetManager.m
//  LogicAssetManager
//
//  Created by hetima on 2014/05/26.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import "LAMUserAssetManager.h"
#import "LAMAppDelegate.h"
#import "LAMUserAsset.h"

NSString* const LAMUserAssetExtension=@"logicasset";
NSString* const LAMUserAssetInfoFile=@"UserAssetInfo.plist";

@implementation LAMUserAssetManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _settingFilePath=[[LAMAppDelegate applicationSupportPath]stringByAppendingPathComponent:@"Assets.plist"];
        _userAssets=[[NSMutableArray alloc]init];
        _userAssetPath=[LAMAppDelegate applicationSupportSubDirectry:@"Assets"];
        [self loadSetting];
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
    }
    return self;
}

- (void)appWillTerminate:(NSNotification*)note
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self saveSetting];
}

- (void)loadSetting
{
    NSDictionary* dic=[[NSDictionary alloc]initWithContentsOfFile:_settingFilePath];
    NSArray* assetDefinition=dic[@"assets"];
    NSMutableArray* instantiatedAssets=[[NSMutableArray alloc]initWithCapacity:[assetDefinition count]];
    for (NSDictionary* dic in assetDefinition) {
        NSString* fileName=[dic[@"name"] stringByAppendingPathExtension:LAMUserAssetExtension];
        NSString* assetPath=[_userAssetPath stringByAppendingPathComponent:fileName];
        if ([[NSFileManager defaultManager]fileExistsAtPath:assetPath]) {
            LAMUserAsset* asset=[[LAMUserAsset alloc]initWithAssetPath:assetPath];
            asset.enabled=[dic[@"enabled"] boolValue];
            [_userAssets addObject:asset];
            [instantiatedAssets addObject:fileName];
        }
    }

    NSArray* files=[[NSFileManager defaultManager]contentsOfDirectoryAtPath:_userAssetPath error:nil];
    
    for (NSString* fileName in files) {
        if ([[fileName pathExtension]isEqualToString:LAMUserAssetExtension]) {
            if ([instantiatedAssets containsObject:fileName]) {
                continue;
            }
            NSString* assetPath=[_userAssetPath stringByAppendingPathComponent:fileName];
            LAMUserAsset* asset=[[LAMUserAsset alloc]initWithAssetPath:assetPath];
            asset.enabled=NO;
            [_userAssets addObject:asset];
        }
    }
}

- (void)saveSetting
{
    NSMutableArray* assetDefinition=[[NSMutableArray alloc]initWithCapacity:[self.userAssets count]];
    NSArray* assets=self.userAssets;
    for (LAMUserAsset* asset in assets) {
        NSDictionary* dic=@{@"name": asset.name, @"enabled":@(asset.enabled)};
        [assetDefinition addObject:dic];
    }
    NSDictionary* dic=@{@"assets": assetDefinition};
    [dic writeToFile:self.settingFilePath atomically:YES];
    
}


- (NSString*)uniqueAssetName:(NSString*)name
{
    NSString* fileName=[name lastPathComponent];
    NSString* ext=[fileName pathExtension];
    NSString* base=[fileName stringByDeletingPathExtension];
    NSString* candidateName=fileName;
    NSInteger i=0;
    do {
        NSString* candidatePath=[self.userAssetPath stringByAppendingPathComponent:candidateName];
        if (![[NSFileManager defaultManager]fileExistsAtPath:candidatePath]) {
            return candidateName;
        }
        if (i>9999) {
            return nil;
        }
        candidateName=[NSString stringWithFormat:@"%@-%ld.%@", base, ++i, ext];
    } while (1);
    
    return nil;
}

- (void)importFile:(NSString*)path
{
    BOOL isDir;
    [[NSFileManager defaultManager]fileExistsAtPath:path isDirectory:&isDir];
    if (!isDir) {
        return;
    }
    
    if ([[path pathExtension]isEqualToString:LAMUserAssetExtension]) {
        [self importAsset:path];
    }else{
        [self importFolder:path asResources:@"MAResources"];
    }
}


- (void)importAsset:(NSString*)folderPath
{
    NSString* fileName=[self uniqueAssetName:folderPath];
    if (!fileName) {
        return;
    }
    NSString* assetPath=[self.userAssetPath stringByAppendingPathComponent:fileName];
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:self.userAssetPath]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:self.userAssetPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if([[NSFileManager defaultManager]copyItemAtPath:folderPath toPath:assetPath error:nil]){
        LAMUserAsset* asset=[[LAMUserAsset alloc]initWithAssetPath:assetPath];
        [self.userAssetsCtl addObject:asset];
    }
    
}



- (void)importFolder:(NSString*)folderPath asResources:(NSString*)resourcesName
{
    NSString* assetName=[[folderPath lastPathComponent]stringByAppendingPathExtension:LAMUserAssetExtension];
    NSString* fileName=[self uniqueAssetName:assetName];
    if (!fileName) {
        return;
    }
    NSString* assetPath=[self.userAssetPath stringByAppendingPathComponent:fileName];
    NSString* resourcesPath=[assetPath stringByAppendingPathComponent:resourcesName];
    [[NSFileManager defaultManager]createDirectoryAtPath:assetPath withIntermediateDirectories:YES attributes:nil error:nil];
    if([[NSFileManager defaultManager]copyItemAtPath:folderPath toPath:resourcesPath error:nil]){
        LAMUserAsset* asset=[[LAMUserAsset alloc]initWithAssetPath:assetPath];
        [self.userAssetsCtl addObject:asset];
    }
    
}


@end
