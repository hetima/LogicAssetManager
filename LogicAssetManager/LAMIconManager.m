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
    if (dic[@"iconGroups"]) {
        [self.iconGroups addObjectsFromArray:dic[@"iconGroups"]];
    }
    
}


- (void)saveSetting
{
    NSArray* result=[self.iconGroups filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"canDelete==%@", @(YES)]];
    NSDictionary* dic=@{@"iconGroups": result};
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
        LOG(@"%@", _iconDragType);
    }
}

#pragma mark -

- (void)addIconWithFile:(NSString*)filePath group:(NSString*)groupName
{
    
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
    NSArray* alloedExt=@[@"png", @"tif", @"tiff", @"icns"];
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
    [pasteboard setString:[NSString stringWithFormat: @"%ld",[indexes firstIndex]] forType:_iconDragType];
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
        if (![groupName length]) {
            groupName=[LAMIconManager defaultIconGroupName];
        }
        NSArray* draggedImages=[self imageFilesInDrop:pb];
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
