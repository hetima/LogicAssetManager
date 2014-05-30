//
//  LAMAppDelegate.h
//  LogicAssetManager
//
//  Created by hetima on 2014/05/24.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LAMAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, weak) IBOutlet NSToolbar* toolbar;
@property (nonatomic, weak) IBOutlet NSTabView* tabView;

+ (NSString*)applicationSupportPath;
+ (NSString*)applicationSupportSubDirectry:(NSString*)name;

+ (NSString*)mergedResourcesPathForName:(NSString*)name;

- (IBAction)actOpenUserAssetsDirectory:(id)sender;
- (IBAction)actOpenUserIconsDirectory:(id)sender;
- (IBAction)actOpenApplicationSupportDirectory:(id)sender;

@end
