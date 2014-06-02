//
//  LAMIconManager.h
//  LogicAssetManager
//
//  Created by hetima on 2014/05/25.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LAMBackdropView, LAMRenamer;

@interface LAMIconManager : NSObject <NSCollectionViewDelegate, NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic,strong) NSMutableArray* allIcons;
@property (nonatomic,strong) IBOutlet NSArrayController* allIconsCtl;
@property (nonatomic,strong) NSMutableArray* iconGroups;
@property (nonatomic,strong) IBOutlet NSArrayController* iconGroupsCtl;

@property (nonatomic,strong) NSString* imageFolderPath;
@property (nonatomic,strong) NSString* settingFilePath;

@property (nonatomic,weak) IBOutlet NSTableView* groupsTableView;
@property (nonatomic,weak) IBOutlet NSCollectionView* iconsView;

@property (nonatomic,strong) IBOutlet NSWindow* removeGroupConfirmSheet;
@property (nonatomic,weak) IBOutlet NSTextField* removeGroupConfirmField;
@property (nonatomic,weak) IBOutlet NSPopUpButton* removeGroupConfirmPopUp;

@property (nonatomic,strong) IBOutlet NSWindow* replaceIconSheet;
@property (nonatomic,weak) IBOutlet LAMBackdropView* replaceIconSheetBackdropView;
@property (nonatomic,weak) IBOutlet NSImageView* replaceIconCurrentImageView;
@property (nonatomic,weak) IBOutlet NSImageView* replaceIconNewImageView;

@property (nonatomic,weak) IBOutlet LAMBackdropView* backdropView;
@property (nonatomic,strong) IBOutlet LAMRenamer* renamer;

+ (NSArray*)defaultIconGroups;

- (void)loadSetting;
- (void)saveSetting;

- (IBAction)actRenameGroup:(id)sender;
- (IBAction)actAddGroup:(id)sender;
- (IBAction)actRemoveGroup:(id)sender;
- (IBAction)actRemoveIcon:(id)sender;


@end
