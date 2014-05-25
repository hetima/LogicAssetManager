//
//  LAMIconManager.m
//  LogicAssetManager
//
//  Created by hetima on 2014/05/25.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import "LAMIconManager.h"
#import "LAMAppDelegate.h"

@implementation LAMIconManager{
    NSInteger _immutableGroupsCount;
    NSString* _iconDragType;
    NSString* _groupDragType;
    BOOL _awaken;
}


+ (NSArray*)imageExtensions
{
    return @[@"png", @"tif", @"tiff", @"icns"];

}

+ (NSString*)defaultIconGroupName
{
    return @"BasicSetOther";
}


+ (NSArray*)defaultIconGroups
{
    return @[@{@"name":@"BasicSetDrums", @"label":@"Drums", @"canDelete":@(NO)},
             @{@"name":@"BasicSetPercussion", @"label":@"Percussion", @"canDelete":@(NO)},
             @{@"name":@"BasicSetBass", @"label":@"Bass", @"canDelete":@(NO)},
             @{@"name":@"BasicSetGuitar", @"label":@"Guitar", @"canDelete":@(NO)},
             @{@"name":@"BasicSetKeyboards", @"label":@"Keyboards", @"canDelete":@(NO)},
             @{@"name":@"BasicSetStrings", @"label":@"Strings", @"canDelete":@(NO)},
             @{@"name":@"BasicSetWind", @"label":@"Wind", @"canDelete":@(NO)},
             @{@"name":@"BasicSetFX", @"label":@"FX", @"canDelete":@(NO)},
             @{@"name":@"BasicSetOther", @"label":@"Other", @"canDelete":@(NO)}
            ];
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        _awaken=NO;
        _iconDragType=[NSString stringWithFormat:@"LAMIconManagerIcon_%p_pbType", self];
        _groupDragType=[NSString stringWithFormat:@"LAMIconManagerGroup_%p_pbType", self];
        
        _allIcons=[[NSMutableArray alloc]init];
        _iconGroups=[[LAMIconManager defaultIconGroups]mutableCopy];//[[NSMutableArray alloc]init];
        [_iconGroups insertObject:@{@"name":@"", @"label":@"All", @"canDelete":@(NO)} atIndex:0];
        _immutableGroupsCount=[_iconGroups count];
        
        _imageFolderPath=[LAMAppDelegate applicationSupportSubDirectry:@"Icons"];
        _settingFilePath=[[LAMAppDelegate applicationSupportPath]stringByAppendingPathComponent:@"Icons.plist"];
        [self loadSetting];

        //test
        [_iconGroups addObject:@{@"name":@"tes", @"label":@"tes", @"canDelete":@(YES)} ];
        [_iconGroups addObject:@{@"name":@"tes1", @"label":@"tes1", @"canDelete":@(YES)} ];
        [_iconGroups addObject:@{@"name":@"tes2", @"label":@"tes2", @"canDelete":@(YES)} ];
        [_iconGroups addObject:@{@"name":@"tes3", @"label":@"tes3", @"canDelete":@(YES)} ];
    }
    return self;
}


- (void)loadSetting
{
    NSMutableDictionary* dic=[[NSMutableDictionary alloc]initWithContentsOfFile:self.settingFilePath];
    
    //group
    if (dic[@"iconGroups"]) {
        [self.iconGroups addObjectsFromArray:dic[@"iconGroups"]];
    }
    
    //icon
    NSArray* icons=dic[@"icons"];
    for (NSDictionary* dic in icons) {

        NSString* name=dic[@"name"];
    }
    
}


- (void)saveSetting
{
    //group
    NSArray* result=[self.iconGroups filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"canDelete==%@", @(YES)]];
    
    //icon
    NSArray* allIcons=self.allIcons;
    NSMutableArray* icons=[[NSMutableArray alloc]initWithCapacity:[allIcons count]];
    for (NSDictionary* dic in allIcons) {
        NSDictionary* copy=@{@"name": dic[@"name"],@"group": dic[@"group"]};
        //imageid
        [icons addObject:copy];
    }
    
    NSDictionary* dic=@{@"iconGroups": result, @"icons": icons};
    [dic writeToFile:self.settingFilePath atomically:YES];
}

-(void)awakeFromNib
{
    if (!_awaken) {
        
        _awaken=YES;
        [self.iconsView setDelegate:self];
        [self.groupsTableView setDelegate:self];
        [self.groupsTableView setDataSource:self];
        [self.iconsView registerForDraggedTypes:@[_iconDragType, NSFilenamesPboardType]];
        [self.groupsTableView registerForDraggedTypes:@[_groupDragType, _iconDragType, NSFilenamesPboardType]];
    }
}

#pragma mark -

/*!
 ファイル名を渡すと、icon フォルダから同名のものを探して見つかれば返す。見つからなければ nil。拡張子は無視する。
 例：image.tiff を渡して image.png があると image.png を返す。
*/
- (NSString*)iconNameWithFileName:(NSString*)name
{
    name=[name stringByDeletingPathExtension];
    NSArray* alloedExt=[LAMIconManager imageExtensions];
    
    for (NSString* ext in alloedExt) {
        NSString* candidateName=[name stringByAppendingPathExtension:ext];
        NSString* candidatePath=[self.imageFolderPath stringByAppendingPathComponent:candidateName];
        if ([[NSFileManager defaultManager]fileExistsAtPath:candidatePath]) {
            return candidateName;
        }
    }
    return nil;
}

- (NSString*)uniqueIconName:(NSString*)name
{
    NSString* fileName=[name lastPathComponent];
    NSString* ext=[fileName pathExtension];
    NSString* base=[fileName stringByDeletingPathExtension];
    NSString* candidateName=fileName;
    NSInteger i=0;
    do {
        NSString* result=[self iconNameWithFileName:candidateName];
        if (!result) {
            return candidateName;
        }
        candidateName=[NSString stringWithFormat:@"%@-%ld.%@", base, ++i, ext];
    } while (1);
    
    return nil;
}

- (void)addIconWithFile:(NSString*)filePath group:(NSString*)groupName
{
    if (![groupName length]) {
        groupName=[LAMIconManager defaultIconGroupName];
    }
    
    NSString* iconName=[self uniqueIconName:filePath];
    NSString* iconPath=[self.imageFolderPath stringByAppendingPathComponent:iconName];
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:self.imageFolderPath]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:self.imageFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    [[NSFileManager defaultManager]copyItemAtPath:filePath toPath:iconPath error:nil];
    
    NSMutableDictionary* icon=[[NSMutableDictionary alloc]init];
    NSImage* image=[[NSImage alloc]initWithContentsOfFile:iconPath];
    
    if (iconPath||!image) {
        return;
    }
    //imageid
    
    icon[@"name"]=iconName;
    icon[@"path"]=iconPath;
    icon[@"image"]=image;
    icon[@"group"]=groupName;
    NSMutableArray* ary=[self mutableArrayValueForKey:@"allIcons"];
    [ary addObject:icon];
    
}

- (NSDictionary*)groupWithName:(NSString*)name
{
    NSArray* result=[self.iconGroups filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name==%@", name]];
    return [result firstObject];
}


- (void)addGroupWithName:(NSString*)name
{
    if ([self groupWithName:name]) {
        return;
    }
    NSMutableDictionary* dic=[[NSMutableDictionary alloc]init];
    dic[@"name"]=name;
    dic[@"label"]=name;
    dic[@"canDelete"]=@(YES);
    
    [[self mutableArrayValueForKey:@"iconGroups"]addObject:dic];
}


#pragma mark - drag and drop

- (BOOL)canAcceptFileDrop:(NSPasteboard *)pb
{
    NSArray* allowedFiles=[self imageFilesInDrop:pb];
    if ([allowedFiles count]) {
        return YES;
    }
    return NO;
}

- (NSArray*)imageFilesInDrop:(NSPasteboard *)pb
{
    id files= [pb propertyListForType:NSFilenamesPboardType];
    NSMutableArray* allowedFiles=[NSMutableArray arrayWithCapacity:1];
    NSArray* alloedExt=[LAMIconManager imageExtensions];
    for (NSString* path in files) {
        if ([alloedExt containsObject:[path pathExtension]]) {
            [allowedFiles addObject:path];
        }
    }
    return allowedFiles;
}


- (BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event
{
    return YES;
}


- (BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
{
    if([indexes count]>1)    return NO;
    [pasteboard setString:[NSString stringWithFormat: @"%ld", [indexes firstIndex]] forType:_iconDragType];
    return YES;
}


- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id <NSDraggingInfo>)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation
{

    NSPasteboard *pb = [draggingInfo draggingPasteboard];

    if ([pb availableTypeFromArray:@[_iconDragType]]) {
        NSInteger draggedRow = [[pb stringForType:_iconDragType]integerValue];
        
        if (proposedDropOperation == NSTableViewDropOn || *proposedDropIndex == draggedRow || *proposedDropIndex == draggedRow + 1)
            return NSDragOperationNone;
        return NSDragOperationMove;
        
    }else if ([pb availableTypeFromArray:@[NSFilenamesPboardType]]) {
        if ([self canAcceptFileDrop:pb]) {
            return NSDragOperationCopy;
        };
    }
    
    return NSDragOperationNone;
}


- (BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id < NSDraggingInfo >)draggingInfo index:(NSInteger)index dropOperation:(NSCollectionViewDropOperation)dropOperation
{
    NSPasteboard *pb = [draggingInfo draggingPasteboard];
    
    if ([pb availableTypeFromArray:@[_iconDragType]]){
        
    }else if ([pb availableTypeFromArray:@[NSFilenamesPboardType]]){
        
    }
    
    return NO;
    
}

#pragma mark -


- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)draggingInfo proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation;
{
    
    NSPasteboard *pb = [draggingInfo draggingPasteboard];

    if ([pb availableTypeFromArray:@[_groupDragType]]) {
        if (row < _immutableGroupsCount) {
            return NSDragOperationNone;
        }
        NSInteger draggedRow = [[pb stringForType:_groupDragType]integerValue];
        
        if (operation == NSTableViewDropOn || row == draggedRow || row == draggedRow + 1)return NSDragOperationNone;
        return NSDragOperationMove;
        
    }else if ([pb availableTypeFromArray:@[_iconDragType]]){
        if (operation == NSTableViewDropOn)return NSDragOperationCopy;
    }else if ([pb availableTypeFromArray:@[NSFilenamesPboardType]]){
        if (operation == NSTableViewDropOn && [self canAcceptFileDrop:pb]) {
            return NSDragOperationCopy;
        };
        
    }
    
    return NSDragOperationNone;
}


- (BOOL)tableView:(NSTableView*)tableView acceptDrop:(id <NSDraggingInfo>)draggingInfo row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard *pb = [draggingInfo draggingPasteboard];
    
    if ([pb availableTypeFromArray:@[_groupDragType]]) {
        NSInteger droppedIndex=-1;
        NSInteger draggedIndex = [[pb stringForType: _groupDragType]integerValue];
        if(draggedIndex==row) return NO;
        
        NSMutableArray* ary=[self mutableArrayValueForKey:@"iconGroups"];
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
        
        //[self.iconGroupsCtl removeObjectAtArrangedObjectIndex:draggedIndex];
        //[self.iconGroupsCtl insertObject:target atArrangedObjectIndex:droppedIndex];
        
        [ary removeObjectAtIndex:draggedIndex];
        [ary insertObject:target atIndex:droppedIndex];
        
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
        return YES;

    }else if ([pb availableTypeFromArray:@[_iconDragType]]){
        
    }else if ([pb availableTypeFromArray:@[NSFilenamesPboardType]]){
        NSDictionary* group=[self.iconGroups objectAtIndex:row];
        NSString* groupName=group[@"name"];
        NSArray* draggedImages=[self imageFilesInDrop:pb];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (NSString* filePath in draggedImages) {
                [self addIconWithFile:filePath group:groupName];
            }
        });
        return YES;
    }
    return NO;

}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    if([rowIndexes count]>1)    return NO;
    NSInteger idx=[rowIndexes firstIndex];
    if (idx < _immutableGroupsCount) {
        return NO;
    }
    
    [pboard setString:[NSString stringWithFormat: @"%ld", idx] forType:_groupDragType];
    return YES;
    
}

@end
