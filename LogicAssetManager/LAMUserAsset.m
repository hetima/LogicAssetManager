//
//  LAMUserAsset.m
//  LogicAssetManager
//
//  Created by hetima on 2014/05/26.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import "LAMUserAsset.h"
#import "LAMUserAssetManager.h"

@implementation LAMUserAsset

- (instancetype)initWithAssetPath:(NSString*)path
{
    self = [super init];
    if (self) {
        _enabled=YES;
        _assetPath=path;
        _name=[[path lastPathComponent]stringByDeletingPathExtension];
        _options=[[NSMutableArray alloc]init];
        [self loadInfo];
    }
    return self;
}


- (void)applySetting:(NSDictionary*)setting
{
    NSArray* options=self.options;
    
    self.enabled=[setting[@"enabled"] boolValue];
    
    for (NSMutableDictionary* option in options) {
        if ([option[@"type"] isEqualToString:@"option"]) {
            NSString* key=[NSString stringWithFormat:@"%@.enabled", option[@"name"]];
            id value=setting[key];
            if (value) {
                option[@"enabled"]=value;
            }
            
        }else if ([option[@"type"] isEqualToString:@"variants"]) {
            NSString* key=[NSString stringWithFormat:@"%@.selectedName", option[@"name"]];
            id value=setting[key];
            if (value) {
                option[@"selectedName"]=value;
            }
        }
    }
}


- (NSDictionary*)setting
{
    NSArray* options=self.options;
    NSMutableDictionary* setting=[[NSMutableDictionary alloc]initWithCapacity:[options count]];
    
    setting[@"enabled"]=@(self.enabled);
    
    for (NSDictionary* option in options) {
        if ([option[@"type"] isEqualToString:@"option"]) {
            NSString* key=[NSString stringWithFormat:@"%@.enabled", option[@"name"]];
            id value=option[@"enabled"];
            if (value) {
                setting[key]=value;
            }
            
        }else if ([option[@"type"] isEqualToString:@"variants"]) {
            NSString* key=[NSString stringWithFormat:@"%@.selectedName", option[@"name"]];
            id value=option[@"selectedName"];
            if (value) {
                setting[key]=value;
            }
        }
    }
    return setting;
}


- (void)loadInfo
{
    NSMutableDictionary* info=[[NSMutableDictionary alloc]initWithContentsOfFile:[_assetPath stringByAppendingPathComponent:LAMUserAssetInfoFile]];
    if (!info) {
        [_options addObject:@{@"type": @"nooption"}];
        return;
    }
    _description=info[@"description"];
    _author=info[@"author"];
    _version=info[@"version"];
    _webSite=info[@"webSite"];
    _assets=info[@"assets"];
    
    for (NSMutableDictionary* asset in _assets) {
        NSString* type=asset[@"type"];
        if ([type isEqualToString:@"variants"]){
            NSMutableArray* variants=asset[@"variants"];
            NSString* selectedName=nil;
            NSMutableArray* variantNames=[[NSMutableArray alloc]initWithCapacity:[variants count]];
            for (NSMutableDictionary* variant in variants) {
                NSString* name=variant[@"name"];
                if (name) {
                    if (!selectedName) {
                        selectedName=name;
                    }
                    [variantNames addObject:name];
                }
            }
            if (selectedName) {
                asset[@"selectedName"]=selectedName;
            }
            asset[@"variantNames"]=variantNames;
        }
        if ([type isEqualToString:@"variants"] || [type isEqualToString:@"option"]) {
            [_options addObject:asset];
        }
    }
    if (![_options count]) {
        [_options addObject:@{@"type": @"nooption"}];
    }
}


#pragma mark -


/*!
 Return full path or nil. Do not check exists.
 */
- (NSString*)pathForAsset:(NSDictionary*)asset
{
    NSString* directory=asset[@"directory"];
    if (![directory length]) {
        return nil;
    }
    return [self.assetPath stringByAppendingPathComponent:directory];
}


- (NSDictionary*)variantWithName:(NSString*)name forAsset:(NSDictionary*)asset
{
    if (![name length]) {
        return nil;
    }
    NSArray* variants=asset[@"variants"];
    for (NSMutableDictionary* variant in variants) {
        
        if ([name isEqualToString:variant[@"name"]]) {
            return variant;
        }
    }
    return nil;
}


/*!
 Return array of full path or nil. Do not check exists.
 */
- (NSArray*)enabledAssetPaths
{
    if (!self.enabled) {
        return nil;
    }
    
    NSArray* assets=self.assets;
    NSMutableArray* result=[[NSMutableArray alloc]initWithCapacity:[assets count]];
    NSDictionary* setting=[self setting];
    
    for (NSDictionary* asset in assets) {
        NSString* directoryName=nil;
        if ([asset[@"type"] isEqualToString:@"option"]) {
            NSString* key=[NSString stringWithFormat:@"%@.enabled", asset[@"name"]];
            BOOL enabled=[setting[key] boolValue];
            if (enabled) {
                directoryName=[self pathForAsset:asset];
            }
        }else if([asset[@"type"] isEqualToString:@"variants"]){
            NSString* key=[NSString stringWithFormat:@"%@.selectedName", asset[@"name"]];
            NSString* selectedName=setting[key];
            NSDictionary* selectedVariant=[self variantWithName:selectedName forAsset:asset];
            if (selectedVariant) {
                directoryName=[self pathForAsset:asset];
            }
        }else{
            directoryName=[self pathForAsset:asset];
        }
        
        if (directoryName) {
            [result addObject:directoryName];
        }
    }
    
    return result;
}


@end
