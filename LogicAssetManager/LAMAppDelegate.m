//
//  LAMAppDelegate.m
//  LogicAssetManager
//
//  Created by hetima on 2014/05/24.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import "LAMAppDelegate.h"
#import "LAMResourcesCoordinator.h"

@implementation LAMAppDelegate


+ (NSString*)applicationSupportPath
{
    NSString* path=[@"~/Library/Application Support/LogicAssetManager" stringByStandardizingPath];
    if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }

    return path;
}


+ (NSString*)applicationSupportSubDirectry:(NSString*)name
{
    NSString* path=[[self applicationSupportPath]stringByAppendingPathComponent:name];
    if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return path;
}


+ (NSString*)mergedResourcesPathForName:(NSString*)name
{
    NSString* path=[self applicationSupportSubDirectry:name];
    path=[path stringByAppendingPathComponent:@"Resources"];
    if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

#pragma mark -


-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application

}

@end
