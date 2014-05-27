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
        [self.userAssetsTable registerForDraggedTypes:@[_userAssetDragType, NSFilenamesPboardType]];
    }
}


- (void)appWillTerminate:(NSNotification*)note
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self saveSetting];
}


- (void)loadSetting
{
    NSDictionary* dic=[[NSDictionary alloc]initWithContentsOfFile:_settingFilePath];
    NSArray* assetDefinition=dic[@"assets"];
    NSMutableArray* instantiatedAssets=[[NSMutableArray alloc]initWithCapacity:[assetDefinition count]];
    for (NSDictionary* dic in assetDefinition) {
        NSString* fileName=[dic[@"name"] stringByAppendingPathExtension:LAMUserAssetExtension];
        NSString* assetPath=[_userAssetPath stringByAppendingPathComponent:fileName];
        if ([[NSFileManager defaultManager]fileExistsAtPath:assetPath]) {
            LAMUserAsset* asset=[[LAMUserAsset alloc]initWithAssetPath:assetPath];
            [asset applySetting:dic[@"setting"]];
            
            [_userAssets addObject:asset];
            [instantiatedAssets addObject:fileName];
        }
    }

    NSArray* files=[[NSFileManager defaultManager]contentsOfDirectoryAtPath:_userAssetPath error:nil];
    
    for (NSString* fileName in files) {
        if ([[fileName pathExtension]isEqualToString:LAMUserAssetExtension]) {
            if ([instantiatedAssets containsObject:fileName]) {
                continue;
            }
            NSString* assetPath=[_userAssetPath stringByAppendingPathComponent:fileName];
            LAMUserAsset* asset=[[LAMUserAsset alloc]initWithAssetPath:assetPath];
            asset.enabled=NO;
            [_userAssets addObject:asset];
        }
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


- (void)importFile:(NSString*)path
{
    BOOL isDir;
    [[NSFileManager defaultManager]fileExistsAtPath:path isDirectory:&isDir];
    if (!isDir) {
        return;
    }
    
    if ([[path pathExtension]isEqualToString:LAMUserAssetExtension]) {
        [self importAsset:path];
    }else{
        [self importFolder:path asResources:@"MAResources"];
    }
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


- (void)importFolder:(NSString*)folderPath asResources:(NSString*)resourcesName
{
    NSString* assetName=[[folderPath lastPathComponent]stringByAppendingPathExtension:LAMUserAssetExtension];
    NSString* fileName=[self uniqueAssetName:assetName];
    if (!fileName) {
        return;
    }
    NSString* assetPath=[self.userAssetPath stringByAppendingPathComponent:fileName];
    NSString* resourcesPath=[assetPath stringByAppendingPathComponent:resourcesName];
    [[NSFileManager defaultManager]createDirectoryAtPath:assetPath withIntermediateDirectories:YES attributes:nil error:nil];
    if([[NSFileManager defaultManager]copyItemAtPath:folderPath toPath:resourcesPath error:nil]){
        LAMUserAsset* asset=[[LAMUserAsset alloc]initWithAssetPath:assetPath];
        [self.userAssetsCtl addObject:asset];
    }
    
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
