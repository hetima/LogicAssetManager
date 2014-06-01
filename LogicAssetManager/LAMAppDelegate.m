//
//  LAMAppDelegate.m
//  LogicAssetManager
//
//  Created by hetima on 2014/05/24.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import "LAMAppDelegate.h"
#import "LAMResourcesCoordinator.h"
#import "LAMUserAssetManager.h"
#import "LAMUserAsset.h"
#import "LAMIconManager.h"
#import "LAMUtilites.h"

@implementation LAMAppDelegate{
    NSOperationQueue* _queue;
}


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


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}


- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    self.operationIsRunning=NO;
    _queue=[[NSOperationQueue alloc]init];
    [_queue setMaxConcurrentOperationCount:1];
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
    self.MAResourcesCoordinator.iconManager=self.iconManager;
    [self.tabView selectTabViewItemWithIdentifier:@"Assets"];
    [self.toolbar setSelectedItemIdentifier:@"Assets"];
}


-(void)applicationWillTerminate:(NSNotification *)notification
{
    [_queue waitUntilAllOperationsAreFinished];
}

- (void)sendUserNotificationWithTitle:(NSString*)title informativeText:(NSString*)informativeText
{
    NSUserNotification *userNotification=[[NSUserNotification alloc]init];
    userNotification.title=title;
    userNotification.informativeText=informativeText;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter]deliverNotification:userNotification];
}


- (void)alertWithError:(NSError*)err
{
    if (!err) {
        err=LAMErrorWithDescription(@"Error occured");
    }
    NSAlert* alert=[NSAlert alertWithError:err];
    if ([self.window isVisible]) {
        [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            
        }];
    }else{
        [alert runModal];
    }
    
}

- (void)applyAssets
{
    [self.userAssetManager saveSetting];
    [self.iconManager saveSetting];
    
    NSArray* assets=[self.userAssetManager enabledAssets];
    NSMutableArray* assetNamesArray=[[NSMutableArray alloc]initWithCapacity:[assets count]];
    NSError* err;
    BOOL success=YES;
    
    for (LAMUserAsset* asset in assets) {
        NSString* name=asset.name;
        if (name) {
            [assetNamesArray addObject:name];
        }
    }
    NSString* assetNames;
    if ([assetNamesArray count]) {
        assetNames=[assetNamesArray componentsJoinedByString:@", "];
    }else{
        assetNames=@"";
    }
    
    
    if (![self.MAResourcesCoordinator extractAssets:assets error:&err]) {
        success=NO;
    }
    if (![self.MAResourcesPlugInsSharedCoordinator extractAssets:assets error:&err]) {
        success=NO;
    }
    if (![self.MAResourcesLgCoordinator extractAssets:assets error:&err]) {
        success=NO;
    }
    if (![self.MAResourcesGBCoordinator extractAssets:assets error:&err]) {
        success=NO;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!success) {
            [self alertWithError:err];
        }else{
            [self sendUserNotificationWithTitle:@"Resources applied" informativeText:assetNames];
        }
    });
}


- (void)restoreAssets
{
    NSError* err;
    BOOL success=YES;
    
    if (![self.MAResourcesCoordinator restoreWithError:&err]) {
        success=NO;
    }
    if (![self.MAResourcesPlugInsSharedCoordinator restoreWithError:&err]) {
        success=NO;
    }
    if (![self.MAResourcesLgCoordinator restoreWithError:&err]) {
        success=NO;
    }
    if (![self.MAResourcesGBCoordinator restoreWithError:&err]) {
        success=NO;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!success) {
            [self alertWithError:err];
        }else{
            [self sendUserNotificationWithTitle:@"Restored" informativeText:@""];
        }
    });
}


#pragma mark -


- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    return @[@"Assets", @"Icons", @"Information"];
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


- (IBAction)actFrameworkIconClick:(id)sender
{
    LAMResourcesCoordinator* clickedCdntr=(LAMResourcesCoordinator*)sender;
    [[NSWorkspace sharedWorkspace]openFile:clickedCdntr.originalResourcesPath];
}


- (IBAction)actDestinationIconClick:(id)sender
{
    LAMResourcesCoordinator* clickedCdntr=(LAMResourcesCoordinator*)sender;
    [[NSWorkspace sharedWorkspace]openFile:clickedCdntr.resourcesLinkPath];
}


- (IBAction)actRestore:(id)sender
{
    //NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [_queue addOperationWithBlock:^{
        self.operationIsRunning=YES;
        [self restoreAssets];
        self.operationIsRunning=NO;
    }];
}


- (IBAction)actApply:(id)sender
{
    //NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [_queue addOperationWithBlock:^{
        self.operationIsRunning=YES;
        [self applyAssets];
        self.operationIsRunning=NO;
    }];
    
}

@end
