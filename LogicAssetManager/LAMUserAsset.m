//
//  LAMUserAsset.m
//  LogicAssetManager
//
//  Created by hetima on 2014/05/26.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import "LAMUserAsset.h"

@implementation LAMUserAsset

- (instancetype)initWithAssetPath:(NSString*)path
{
    self = [super init];
    if (self) {
        _assetPath=path;
        _name=[[path lastPathComponent]stringByDeletingPathExtension];
    }
    return self;
}

@end
