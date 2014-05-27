//
//  LAMUserAssetManager.h
//  LogicAssetManager
//
//  Created by hetima on 2014/05/26.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const LAMUserAssetExtension;
extern NSString * const LAMUserAssetInfoFile;

@interface LAMUserAssetManager : NSObject

@property (nonatomic,strong) NSMutableArray* userAssets;
@property (nonatomic,strong) IBOutlet NSArrayController* userAssetsCtl;

@property (nonatomic,weak) IBOutlet NSTableView* optionsTable;

@property (nonatomic,strong) NSString* userAssetPath;
@property (nonatomic,strong) NSString* settingFilePath;

@end
