//
//  LAMUserAsset.h
//  LogicAssetManager
//
//  Created by hetima on 2014/05/26.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LAMUserAsset : NSObject

@property (nonatomic, strong)NSString* name;
@property (nonatomic, strong)NSString* assetPath;

- (instancetype)initWithAssetPath:(NSString*)path;

@end
