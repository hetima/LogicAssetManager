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

+ (NSString*)applicationSupportPath;
+ (NSString*)applicationSupportSubDirectry:(NSString*)name;

+ (NSString*)mergedResourcesPathForName:(NSString*)name;
+ (NSString*)mergedMAResourcesPath;

@end
