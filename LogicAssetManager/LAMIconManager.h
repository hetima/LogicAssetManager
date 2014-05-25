//
//  LAMIconManager.h
//  LogicAssetManager
//
//  Created by hetima on 2014/05/25.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LAMIconManager : NSObject

@property (nonatomic,strong) NSMutableArray* allIcons;
@property (nonatomic,strong) NSMutableArray* iconGroups;

@property (nonatomic,strong) NSString* imageFolderPath;
@property (nonatomic,strong) NSString* settingFilePath;

@property (nonatomic,weak) IBOutlet NSTableView* groupsTableView;

+ (NSArray*)defaultIconGroups;

- (void)loadSetting;
- (void)saveSetting;

@end
