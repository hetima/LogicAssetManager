//
//  LAMUserAssetManager.m
//  LogicAssetManager
//
//  Created by hetima on 2014/05/26.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import "LAMUserAssetManager.h"
#import "LAMAppDelegate.h"
#import "LAMUserAsset.h"
#import "LAMBackdropView.h"
#import "LAMUtilites.h"
#import "LAMRenamer.h"

NSString* const LAMUserAssetExtension=@"logicasset";
NSString* const LAMUserAssetInfoFile=@"UserAssetInfo.plist";

@implementation LAMUserAssetManager{
    NSString* _userAssetDragType;
    BOOL _awaken;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _userAssetDragType=[NSString stringWithFormat:@"LAMUserAssetManagerUserAsset_%p_pbType", self];

        _settingFilePath=[[LAMAppDelegate applicationSupportPath]stringByAppendingPathComponent:@"Assets.plist"];
        _userAssets=[[NSMutableArray alloc]init];
        _userAssetPath=[LAMAppDelegate applicationSupportSubDirectry:@"Assets"];
        [self loadSetting];
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
    }
    return self;
}


-(void)awakeFromNib
{
    if (!_awaken) {
        _awaken=YES;
        [self.userAssetsTable setDelegate:self];
        [self.userAssetsTable setDataSource:self];
        [self.userAssetsTable registerForDraggedTypes:@[_userAssetDragType]];
        if ([self.userAssets count]) {
            [self.userAssetsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        }
        
        __weak LAMUserAssetManager* wself=self;
        [self.backdropView registerForFileExtensions:@[LAMUserAssetExtension] acceptsFolder:YES completion:^BOOL(NSArray *files)
        {
            return [wself importFiles:files];
        }];
    }
}


- (void)appWillTerminate:(NSNotification*)note
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self saveSetting];
}


- (IBAction)reload:(id)sender
{
    [self willChangeValueForKey:@"userAssets"];
    [self saveSetting];
    [_userAssets removeAllObjects];
    [self loadSetting];
    [self didChangeValueForKey:@"userAssets"];
}


- (void)loadSetting
{
    NSDictionary* dic=[[NSDictionary alloc]initWithContentsOfFile:_settingFilePath];
    NSArray* assetDefinition=dic[@"assets"];
    NSMutableArray* instantiatedAssets=[[NSMutableArray alloc]initWithCapacity:[assetDefinition count]];
    for (NSDictionary* dic in assetDefinition) {
        NSString* fileName=[dic[@"name"] stringByAppendingPathExtension:LAMUserAssetExtension];
        NSString* assetPath=[_userAssetPath stringByAppendingPathComponent:fileName];
        if ([instantiatedAssets containsObject:fileName]) {
            continue;
        }
        if ([[NSFileManager defaultManager]fileExistsAtPath:assetPath]) {
            LAMUserAsset* asset=[[LAMUserAsset alloc]initWithAssetPath:assetPath];
            [asset applySetting:dic[@"setting"]];
            
            [_userAssets addObject:asset];
            [instantiatedAssets addObject:fileName];
        }
    }

    NSArray* files=[[NSFileManager defaultManager]contentsOfDirectoryAtPath:_userAssetPath error:nil];
    files=[files pathsMatchingExtensions:@[LAMUserAssetExtension]];
    
    for (NSString* fileName in files) {
        if ([instantiatedAssets containsObject:fileName]) {
            continue;
        }
        NSString* assetPath=[_userAssetPath stringByAppendingPathComponent:fileName];
        LAMUserAsset* asset=[[LAMUserAsset alloc]initWithAssetPath:assetPath];
        asset.enabled=NO;
        [_userAssets addObject:asset];
    }
}


- (void)saveSetting
{
    NSMutableArray* assetDefinition=[[NSMutableArray alloc]initWithCapacity:[self.userAssets count]];
    NSArray* assets=self.userAssets;
    for (LAMUserAsset* asset in assets) {
        NSDictionary* dic=@{@"name": asset.name, @"setting":[asset setting]};
        [assetDefinition addObject:dic];
    }
    NSDictionary* dic=@{@"assets": assetDefinition};
    [dic writeToFile:self.settingFilePath atomically:YES];
    
}


- (NSArray*)enabledAssets
{
    NSArray* result=[self.userAssets filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"enabled==%@", @(YES)]];
    return result;
}


- (NSArray*)enabledSubsetPaths
{
    NSArray* userAssets=self.userAssets;
    NSMutableArray* result=[[NSMutableArray alloc]initWithCapacity:[userAssets count]];
    for (LAMUserAsset* userAsset in userAssets) {
        NSArray* enabledSubsetPaths=[userAsset enabledSubsetPaths];
        if ([enabledSubsetPaths count]) {
            [result addObjectsFromArray:enabledSubsetPaths];
        }
    }
    
    return result;
}


#pragma mark - import


- (NSString*)uniqueAssetName:(NSString*)name
{
    NSString* fileName=[name lastPathComponent];
    NSString* ext=[fileName pathExtension];
    NSString* base=[fileName stringByDeletingPathExtension];
    NSString* candidateName=fileName;
    NSInteger i=0;
    do {
        NSString* candidatePath=[self.userAssetPath stringByAppendingPathComponent:candidateName];
        if (![[NSFileManager defaultManager]fileExistsAtPath:candidatePath]) {
            return candidateName;
        }
        if (i>9999) {
            return nil;
        }
        candidateName=[NSString stringWithFormat:@"%@-%ld.%@", base, ++i, ext];
    } while (1);
    
    return nil;
}


- (NSString*)expectResourceType:(NSString*)directoryPath
{
    NSArray* candidates=@[@"MAResources", @"MAResourcesPlugInsShared", @"MAResourcesLg", @"MAResourcesGB"];
    
    for (NSString* name in candidates) {
        NSString* plistPath=[directoryPath stringByAppendingPathComponent:[name stringByAppendingString:@"Mapping.plist"]];
        if ([[NSFileManager defaultManager]fileExistsAtPath:plistPath]) {
            return name;
        }
    }
    
    if ([[directoryPath pathExtension]length]) {
        return nil;
    }
    
    //とりあえず
    return @"MAResources";
}

- (BOOL)importFiles:(NSArray*)paths
{
    BOOL anyFileImported=NO;
    for (NSString* file in paths) {
        if([self importFile:file]){
            anyFileImported=YES;
        }

    }
    
    return anyFileImported;
}

- (BOOL)importFile:(NSString*)path
{
    BOOL isDir;
    [[NSFileManager defaultManager]fileExistsAtPath:path isDirectory:&isDir];
    if (!isDir) {
        return NO;
    }
    
    if ([[path pathExtension]isEqualToString:LAMUserAssetExtension]) {
        [self importAsset:path];
    }else{
        NSString* name=[path lastPathComponent];
        path=LAMDigIfDirectoryHasOneSubDirectoryOnly(path);
        NSString* resourceType=[self expectResourceType:path];
        if (!resourceType) {
            return NO;
        }
        [self importFolder:path name:name asResources:resourceType];
    }
    return YES;
}


- (void)importAsset:(NSString*)folderPath
{
    NSString* fileName=[self uniqueAssetName:folderPath];
    if (!fileName) {
        return;
    }
    NSString* assetPath=[self.userAssetPath stringByAppendingPathComponent:fileName];
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:self.userAssetPath]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:self.userAssetPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if([[NSFileManager defaultManager]copyItemAtPath:folderPath toPath:assetPath error:nil]){
        LAMUserAsset* asset=[[LAMUserAsset alloc]initWithAssetPath:assetPath];
        [self.userAssetsCtl addObject:asset];
    }
    
}


- (void)importFolder:(NSString*)folderPath name:(NSString*)name asResources:(NSString*)resourcesName
{
    NSString* assetName=[name stringByAppendingPathExtension:LAMUserAssetExtension];
    NSString* fileName=[self uniqueAssetName:assetName];
    if (!fileName) {
        return;
    }
    
    NSString* subsetName=@"base";
    
    // /assetname.logicasset
    NSString* assetPath=[self.userAssetPath stringByAppendingPathComponent:fileName];
    
    // /assetname.logicasset/subsetName
    NSString* subsetPath=[assetPath stringByAppendingPathComponent:subsetName];
    
    // /assetname.logicasset/subsetName/resourcesName
    NSString* resourcesPath=[subsetPath stringByAppendingPathComponent:resourcesName];
    
    // /assetname.logicasset/UserAssetInfo.plist
    NSString* infoPath=[assetPath stringByAppendingPathComponent:LAMUserAssetInfoFile];
    NSDictionary* info=@{@"name": [folderPath lastPathComponent],
                         @"subsets":@[@{@"directory":subsetName, @"name":subsetName, @"type":@"default"}]};
    
    [[NSFileManager defaultManager]createDirectoryAtPath:subsetPath withIntermediateDirectories:YES attributes:nil error:nil];
    if([[NSFileManager defaultManager]copyItemAtPath:folderPath toPath:resourcesPath error:nil]){
        [info writeToFile:infoPath atomically:YES];
        LAMUserAsset* asset=[[LAMUserAsset alloc]initWithAssetPath:assetPath];
        [self.userAssetsCtl addObject:asset];
    }
    
}


- (void)removeUserAsset:(LAMUserAsset*)asset
{
    if ([[NSFileManager defaultManager]fileExistsAtPath:asset.assetPath]) {
        NSURL* url=[NSURL fileURLWithPath:asset.assetPath];
        [[NSFileManager defaultManager]trashItemAtURL:url resultingItemURL:nil error:nil];
    }
    
    [self.userAssetsCtl removeObject:asset];
}


- (IBAction)actUninstallUserAsset:(LAMUserAsset*)sender
{
    if ([sender isKindOfClass:[LAMUserAsset class]]) {
        NSString* messageText=[NSString stringWithFormat:@"Uninstall \"%@\"", sender.name];
        NSString* informativeText=[NSString stringWithFormat:@"\"%@\" is moved to trash. Be sure to update after uninstall.", [sender.assetPath lastPathComponent]];

        NSAlert* alert=[[NSAlert alloc]init];
        [alert setMessageText:messageText];
        [alert setInformativeText:informativeText];
        [alert addButtonWithTitle:@"Uninstall"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert beginSheetModalForWindow:[[NSApp delegate]window] completionHandler:^(NSModalResponse returnCode) {
            if (returnCode==NSAlertFirstButtonReturn) {
                [self removeUserAsset:sender];
            }
        }];
    }
}


- (IBAction)actOpenWebSiteUserAsset:(LAMUserAsset*)sender;
{
    if ([sender isKindOfClass:[LAMUserAsset class]]) {
        NSString* urlString=sender.webSite;
        NSURL* url=[NSURL URLWithString:urlString];
        if (url) {
            [[NSWorkspace sharedWorkspace]openURL:url];
        }
    }
}


- (IBAction)actRenameUserAsset:(id)sender
{
    LAMUserAsset* selectedUserAsset=[[self.userAssetsCtl selectedObjects]firstObject];

    NSString* currentName=selectedUserAsset.name;
    
    [self.renamer renameWithOldName:currentName sheetParentWindow:[sender window] completion:^(NSString *newName) {
        if (![newName length]) {
            NSBeep();
            return;
        }
        
        NSString* fileName=[self uniqueAssetName:[newName stringByAppendingPathExtension:LAMUserAssetExtension]];
        NSString* uniqueName=[fileName stringByDeletingPathExtension];
        if (!fileName || ![uniqueName isEqualToString:newName]) {
            NSBeep();
            return;
        }
        
        NSString* newPath=[[selectedUserAsset.assetPath stringByDeletingLastPathComponent]stringByAppendingPathComponent:fileName];

        if([[NSFileManager defaultManager]moveItemAtPath:selectedUserAsset.assetPath toPath:newPath error:nil]){
            selectedUserAsset.assetPath=newPath;
            selectedUserAsset.name=newName;
        }
    }];
    
}

#pragma mark - delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView==self.optionsTable) {
        LAMUserAsset* asset=[[self.userAssetsCtl selectedObjects]firstObject];
        NSDictionary* option=[asset.options objectAtIndex:row];
        return [tableView makeViewWithIdentifier:option[@"type"] owner:nil];
    }

    return [tableView makeViewWithIdentifier:@"default" owner:nil];
}



- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)draggingInfo proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation;
{
    if (tableView != self.userAssetsTable) {
        return NSDragOperationNone;
    }
    NSPasteboard *pb = [draggingInfo draggingPasteboard];
    
    if ([pb availableTypeFromArray:@[_userAssetDragType]]) {
        NSInteger draggedRow = [[pb stringForType:_userAssetDragType]integerValue];
        
        if (operation == NSTableViewDropOn || row == draggedRow || row == draggedRow + 1)return NSDragOperationNone;
        return NSDragOperationMove;
        
    }else if ([pb availableTypeFromArray:@[NSFilenamesPboardType]]) {
        if (operation == NSTableViewDropOn) {
            return NSDragOperationNone;
        }
    }
    
    return NSDragOperationNone;
}


- (BOOL)tableView:(NSTableView*)tableView acceptDrop:(id <NSDraggingInfo>)draggingInfo row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    if (tableView != self.userAssetsTable) {
        return NO;
    }
    NSPasteboard *pb = [draggingInfo draggingPasteboard];
    
    if ([pb availableTypeFromArray:@[_userAssetDragType]]) {
        NSInteger droppedIndex=-1;
        NSInteger draggedIndex = [[pb stringForType:_userAssetDragType]integerValue];
        if(draggedIndex==row) return NO;
        
        NSMutableArray* ary=[self mutableArrayValueForKey:@"userAssets"];
        id target=[ary objectAtIndex:draggedIndex];
        if (row < draggedIndex){
            droppedIndex=row;
        }else{
            droppedIndex=row-1;
        }
        
        NSInteger selectedRow=[tableView selectedRow];
        if (selectedRow==draggedIndex) {
            selectedRow=droppedIndex;
        }else{
            NSInteger shift=0;
            if (selectedRow>draggedIndex){
                shift--;
            }
            if (selectedRow>droppedIndex) {
                shift++;
            }
            selectedRow+=shift;
        }

        [ary removeObjectAtIndex:draggedIndex];
        [ary insertObject:target atIndex:droppedIndex];
        
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
        return YES;
 
    }else if ([pb availableTypeFromArray:@[NSFilenamesPboardType]]){
        return NO;
    }
    return NO;
    
}


- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    if (tableView != self.userAssetsTable) {
        return NO;
    }
    if([rowIndexes count]>1)    return NO;
    NSInteger idx=[rowIndexes firstIndex];
    
    [pboard setString:[NSString stringWithFormat: @"%ld", idx] forType:_userAssetDragType];
    return YES;
    
}


@end
