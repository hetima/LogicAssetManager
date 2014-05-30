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

@class LAMBackdropView;

@interface LAMUserAssetManager : NSObject <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic,strong) NSMutableArray* userAssets;
@property (nonatomic,strong) IBOutlet NSArrayController* userAssetsCtl;

@property (nonatomic,weak) IBOutlet NSTableView* userAssetsTable;
@property (nonatomic,weak) IBOutlet NSTableView* optionsTable;
@property (nonatomic,weak) IBOutlet LAMBackdropView* backdropView;

@property (nonatomic,strong) NSString* userAssetPath;
@property (nonatomic,strong) NSString* settingFilePath;

- (NSArray*)enabledSubsetPaths;

- (IBAction)reload:(id)sender;
- (IBAction)actUninstallUserAsset:(id)sender;
- (IBAction)actOpenWebSiteUserAsset:(id)sender;

@end
