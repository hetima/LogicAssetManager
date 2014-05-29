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
@property (nonatomic, strong)NSMutableArray* subsets;
@property (nonatomic, strong)NSMutableArray* options;
@property (nonatomic) BOOL enabled;

@property (nonatomic, strong)NSString* description;
@property (nonatomic, strong)NSString* author;
@property (nonatomic, strong)NSString* version;
@property (nonatomic, strong)NSString* webSite;

- (instancetype)initWithAssetPath:(NSString*)path;

- (void)applySetting:(NSDictionary*)setting;
- (NSDictionary*)setting;

- (NSArray*)enabledSubsetPaths;

@end
