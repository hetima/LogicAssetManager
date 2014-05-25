//
//  LAMIconManager.m
//  LogicAssetManager
//
//  Created by hetima on 2014/05/25.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import "LAMIconManager.h"
#import "LAMAppDelegate.h"

#define kImageIdMin 1000
#define kImageIdMax 4000

@implementation LAMIconManager{
    NSInteger _immutableGroupsCount;
    NSString* _iconDragType;
    NSString* _groupDragType;
    BOOL _awaken;
    NSInteger _lastImageId;
    NSMutableIndexSet* _imageIdIndexSet;

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
        _lastImageId=kImageIdMin;
        _imageIdIndexSet=[[NSMutableIndexSet alloc]init];
        _iconDragType=[NSString stringWithFormat:@"LAMIconManagerIcon_%p_pbType", self];
        _groupDragType=[NSString stringWithFormat:@"LAMIconManagerGroup_%p_pbType", self];
        
        _allIcons=[[NSMutableArray alloc]init];
        _iconGroups=[[LAMIconManager defaultIconGroups]mutableCopy];//[[NSMutableArray alloc]init];
        [_iconGroups insertObject:@{@"name":@"", @"label":@"All", @"canDelete":@(NO)} atIndex:0];
        _immutableGroupsCount=[_iconGroups count];
        
        _imageFolderPath=[LAMAppDelegate applicationSupportSubDirectry:@"Icons"];
        _settingFilePath=[[LAMAppDelegate applicationSupportPath]stringByAppendingPathComponent:@"Icons.plist"];
        [self loadSetting];
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];


        //test
        [_iconGroups addObject:@{@"name":@"tes", @"label":@"tes", @"canDelete":@(YES)} ];
        [_iconGroups addObject:@{@"name":@"tes1", @"label":@"tes1", @"canDelete":@(YES)} ];
        [_iconGroups addObject:@{@"name":@"tes2", @"label":@"tes2", @"canDelete":@(YES)} ];
        [_iconGroups addObject:@{@"name":@"tes3", @"label":@"tes3", @"canDelete":@(YES)} ];
    }
    return self;
}

- (void)appWillTerminate:(NSNotification*)note
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self saveSetting];
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

        NSString* iconName=dic[@"name"];
        NSString* groupName=dic[@"group"];
        NSString* iconPath=[self iconNameWithFileName:iconName];

        NSInteger imageId=[dic[@"id"] integerValue];
        if (imageId>_lastImageId) {
            _lastImageId=imageId;
        }
        if(!iconPath || imageId<kImageIdMin) continue;
        
        iconPath=[self.imageFolderPath stringByAppendingPathComponent:iconPath];
        
        NSImage* image=[[NSImage alloc]initWithContentsOfFile:iconPath];
        if(!image) continue;
        
        NSMutableDictionary* icon=[[NSMutableDictionary alloc]initWithCapacity:5];
        icon[@"name"]=iconName;
        icon[@"path"]=iconPath;
        icon[@"image"]=image;
        icon[@"group"]=groupName;
        icon[@"id"]=@(imageId);
        [self.allIcons addObject:icon];
        
        [_imageIdIndexSet addIndex:imageId];
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
        NSDictionary* copy=@{@"name": dic[@"name"], @"group": dic[@"group"], @"id": dic[@"id"]};
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

/*!
 使われていない imageId を探す
 */
- (NSInteger)vacantImageId
{
    NSInteger i;
    for (i=kImageIdMin; i<=kImageIdMax; i++) {
        if (![_imageIdIndexSet containsIndex:i]) {
            return i;
        }
    }
    
    return 0;
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
    
    if (!iconPath||!image) {
        return;
    }
    
    //imageid
    NSInteger imageId;
    if (_lastImageId<=kImageIdMax) {
        _lastImageId++;
        imageId=_lastImageId;
    }else{
        imageId=[self vacantImageId];
    }
    if (imageId<kImageIdMin) {
        //
        return;
    }
    icon[@"name"]=iconName;
    icon[@"path"]=iconPath;
    icon[@"image"]=image;
    icon[@"group"]=groupName;
    icon[@"id"]=@(imageId);
    NSMutableArray* ary=[self mutableArrayValueForKey:@"allIcons"];
    [ary addObject:icon];
    [_imageIdIndexSet addIndex:imageId];

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

- (NSString*)appIconPathInApplication:(NSString*)appPath
{
    NSString* infoPath=[appPath stringByAppendingPathComponent:@"Contents/Info.plist"];
    if (![[NSFileManager defaultManager]fileExistsAtPath:infoPath]) {
        return nil;
    }
    NSDictionary* appInfo=[[NSDictionary alloc]initWithContentsOfFile:infoPath];
    NSString* iconName=appInfo[@"CFBundleIconFile"];
    if ([iconName length]==0) {
        return nil;
    }
    if (![iconName hasSuffix:@".icns"]) {
        iconName=[iconName stringByAppendingString:@".icns"];
    }
    NSString* iconPath=[NSString stringWithFormat:@"Contents/Resources/%@", iconName];
    iconPath=[appPath stringByAppendingPathComponent:iconPath];
    if ([[NSFileManager defaultManager]fileExistsAtPath:iconPath]) {
        return iconPath;
    }

    return nil;
}

- (BOOL)canAcceptFileDrop:(NSPasteboard *)pb
{
    id files= [pb propertyListForType:NSFilenamesPboardType];
    NSArray* alloedExt=[LAMIconManager imageExtensions];
    for (NSString* path in files) {
        if ([alloedExt containsObject:[path pathExtension]]) {
            return YES;
        }else if([[path pathExtension]isEqualToString:@"app"]){
            return YES;
        }
    }
    return NO;
}

- (NSArray*)imageFilesInDrop:(NSPasteboard *)pb
{
    id files= [pb propertyListForType:NSFilenamesPboardType];
    NSMutableArray* allowedFiles=[[NSMutableArray alloc]init];
    NSArray* alloedExt=[LAMIconManager imageExtensions];
    for (NSString* path in files) {
        if ([alloedExt containsObject:[path pathExtension]]) {
            [allowedFiles addObject:path];
        }else if([[path pathExtension]isEqualToString:@"app"]){
            NSString* appIconPath=[self appIconPathInApplication:path];
            if (appIconPath) {
                [allowedFiles addObject:appIconPath];
            }
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
        
    }else if ([pb availableTypeFromArray:@[_iconDragType]]) {
        if (operation == NSTableViewDropOn)return NSDragOperationCopy;
    }else if ([pb availableTypeFromArray:@[NSFilenamesPboardType]]) {
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
