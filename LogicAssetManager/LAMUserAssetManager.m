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
        _userAssets=[[NSMutableArray alloc]init];
        _userAssetPath=[LAMAppDelegate applicationSupportSubDirectry:@"Assets"];
        [self loadSetting];
    }
    return self;
}

- (void)loadSetting
{
    NSArray* files=[[NSFileManager defaultManager]contentsOfDirectoryAtPath:_userAssetPath error:nil];
    
    for (NSString* fileName in files) {
        if ([[fileName pathExtension]isEqualToString:LAMUserAssetExtension]) {
            NSString* assetPath=[_userAssetPath stringByAppendingPathComponent:fileName];
            LAMUserAsset* asset=[[LAMUserAsset alloc]initWithAssetPath:assetPath];
            [_userAssets addObject:asset];
        }
    }
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
