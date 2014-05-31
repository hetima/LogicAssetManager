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
    NSString* path=[self applicationSupportSubDirectry:@"Merged"];
    path=[path stringByAppendingPathComponent:name];
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
#define instantiateResourcesCoordinator(rc) \
    self.rc=[LAMResourcesCoordinator rc]; \
    self.rc.outputDirectory=[LAMAppDelegate mergedResourcesPathForName:self.rc.resourcesName]

    instantiateResourcesCoordinator(MAResourcesCoordinator);
    instantiateResourcesCoordinator(MAResourcesPlugInsSharedCoordinator);
    instantiateResourcesCoordinator(MAResourcesLgCoordinator);
    instantiateResourcesCoordinator(MAResourcesGBCoordinator);
    
#undef instantiateResourcesCoordinator
    
    [self.tabView selectTabViewItemWithIdentifier:@"Assets"];
    [self.toolbar setSelectedItemIdentifier:@"Assets"];
}


#pragma mark -


- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    return @[@"Assets", @"Icons"];
}


- (IBAction)actToolbarClick:(id)sender
{
    NSString* idn=[sender itemIdentifier];

    [self.tabView selectTabViewItemWithIdentifier:idn];
    [self.toolbar setSelectedItemIdentifier:idn];
}


- (IBAction)actOpenUserAssetsDirectory:(id)sender
{
    NSString* path=[LAMAppDelegate applicationSupportSubDirectry:@"Assets"];
    [[NSWorkspace sharedWorkspace]openFile:path];
}


- (IBAction)actOpenUserIconsDirectory:(id)sender
{
    NSString* path=[LAMAppDelegate applicationSupportSubDirectry:@"Icons"];
    [[NSWorkspace sharedWorkspace]openFile:path];
}


- (IBAction)actOpenApplicationSupportDirectory:(id)sender
{
    NSString* path=[LAMAppDelegate applicationSupportPath];
    [[NSWorkspace sharedWorkspace]openFile:path];
}


@end
