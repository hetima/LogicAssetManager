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
    _subsets=info[@"subsets"];
    
    for (NSMutableDictionary* asset in _subsets) {
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
- (NSString*)pathForSubset:(NSDictionary*)asset
{
    NSString* directory=asset[@"directory"];
    if (![directory length]) {
        return nil;
    }
    return [self.assetPath stringByAppendingPathComponent:directory];
}


- (NSDictionary*)variantWithName:(NSString*)name forSubset:(NSDictionary*)subset
{
    if (![name length]) {
        return nil;
    }
    NSArray* variants=subset[@"variants"];
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
- (NSArray*)enabledSubsetPaths
{
    if (!self.enabled) {
        return nil;
    }
    
    NSArray* subsets=self.subsets;
    NSMutableArray* result=[[NSMutableArray alloc]initWithCapacity:[subsets count]];
    NSDictionary* setting=[self setting];
    
    for (NSDictionary* subset in subsets) {
        NSString* directoryName=nil;
        if ([subset[@"type"] isEqualToString:@"option"]) {
            NSString* key=[NSString stringWithFormat:@"%@.enabled", subset[@"name"]];
            BOOL enabled=[setting[key] boolValue];
            if (enabled) {
                directoryName=[self pathForSubset:subset];
            }
        }else if([subset[@"type"] isEqualToString:@"variants"]){
            NSString* key=[NSString stringWithFormat:@"%@.selectedName", subset[@"name"]];
            NSString* selectedName=setting[key];
            NSDictionary* selectedVariant=[self variantWithName:selectedName forSubset:subset];
            if (selectedVariant) {
                directoryName=[self pathForSubset:subset];
            }
        }else{
            directoryName=[self pathForSubset:subset];
        }
        
        if (directoryName) {
            [result addObject:directoryName];
        }
    }
    
    return result;
}


@end
