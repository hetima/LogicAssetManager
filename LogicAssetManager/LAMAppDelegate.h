//
//  LAMAppDelegate.h
//  LogicAssetManager
//
//  Created by hetima on 2014/05/24.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LAMResourcesCoordinator, LAMUserAssetManager, LAMIconManager, LAMMAResourcesCoordinator;

@interface LAMAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, weak) IBOutlet NSToolbar* toolbar;
@property (nonatomic, weak) IBOutlet NSTabView* tabView;

@property (nonatomic, strong) IBOutlet LAMUserAssetManager* userAssetManager;
@property (nonatomic, strong) IBOutlet LAMIconManager* iconManager;

@property (nonatomic, strong) LAMMAResourcesCoordinator* MAResourcesCoordinator;
@property (nonatomic, strong) LAMResourcesCoordinator* MAResourcesPlugInsSharedCoordinator;
@property (nonatomic, strong) LAMResourcesCoordinator* MAResourcesLgCoordinator;
@property (nonatomic, strong) LAMResourcesCoordinator* MAResourcesGBCoordinator;

@property (nonatomic) BOOL operationIsRunning;

+ (NSString*)applicationSupportPath;
+ (NSString*)applicationSupportSubDirectry:(NSString*)name;

+ (NSString*)mergedResourcesPathForName:(NSString*)name;

- (IBAction)actOpenUserAssetsDirectory:(id)sender;
- (IBAction)actOpenUserIconsDirectory:(id)sender;
- (IBAction)actOpenApplicationSupportDirectory:(id)sender;
- (IBAction)actFrameworkIconClick:(id)sender;
- (IBAction)actDestinationIconClick:(id)sender;

- (IBAction)actRestore:(id)sender;
- (IBAction)actApply:(id)sender;

@end
