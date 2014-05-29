//
//  LAMBackdropView.m
//  LogicAssetManager
//
//  Created by hetima on 2014/05/29.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import "LAMBackdropView.h"

@implementation LAMBackdropView{
    LAMBackdropViewFileDropped _droppedBlk;
    BOOL _acceptsFolder;
    NSArray* _fileExtensions;
    
    NSInteger _currentSession;
    BOOL _cachedResult;
}


- (void)registerForFileExtensions:(NSArray*)extensions acceptsFolder:(BOOL)acceptsFolder completion:(LAMBackdropViewFileDropped)blk
{
    _currentSession=0;
    _droppedBlk=blk;
    _acceptsFolder=acceptsFolder;
    _fileExtensions=extensions;
    [self registerForDraggedTypes:@[NSFilenamesPboardType]];
}


- (NSArray*)filesFromPasteboard:(NSPasteboard*)pb
{
    id files= [pb propertyListForType:NSFilenamesPboardType];
    NSMutableArray* allowedFiles=[[NSMutableArray alloc]init];

    for (NSString* path in files) {
        if ([_fileExtensions containsObject:[path pathExtension]]) {
            [allowedFiles addObject:path];
        }else if(_acceptsFolder){
            BOOL isDir;
            [[NSFileManager defaultManager]fileExistsAtPath:path isDirectory:&isDir];
            if (isDir) {
                [allowedFiles addObject:path];
            }
        }
    }
    return allowedFiles;
}


- (BOOL)canAcceptDrop:(NSPasteboard *)pb
{
    NSArray * files= [pb propertyListForType:NSFilenamesPboardType];
    
    for (NSString* path in files) {
        if ([_fileExtensions containsObject:[path pathExtension]]) {
            return YES;
        }else if(_acceptsFolder){
            BOOL isDir;
            [[NSFileManager defaultManager]fileExistsAtPath:path isDirectory:&isDir];
            if (isDir) {
                return YES;
            }
        }
    }
    return NO;
}


#pragma mark -


- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    if ([sender draggingSequenceNumber]==_currentSession) {
        return _cachedResult ? NSDragOperationCopy:NSDragOperationNone;
    }
    _currentSession=[sender draggingSequenceNumber];
    _cachedResult=[self canAcceptDrop:[sender draggingPasteboard]];
    return _cachedResult ? NSDragOperationCopy:NSDragOperationNone;
}


- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if ([sender draggingSequenceNumber]==_currentSession) {
        return _cachedResult ? NSDragOperationCopy:NSDragOperationNone;
    }
    
    _currentSession=[sender draggingSequenceNumber];
    _cachedResult=[self canAcceptDrop:[sender draggingPasteboard]];
    return _cachedResult ? NSDragOperationCopy:NSDragOperationNone;
}


- (void)draggingExited:(id <NSDraggingInfo>)sender
{

}


- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    if ([sender draggingSequenceNumber]==_currentSession) {
        return _cachedResult;
    }
    if ([self canAcceptDrop:[sender draggingPasteboard]]) {
        //[self setBackgroundColor:[NSColor controlBackgroundColor]];
        return YES;
    } else {
        return NO;
    }
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    _currentSession=0;
    BOOL handled=NO;
    
    NSArray *files = [self filesFromPasteboard:[sender draggingPasteboard]];
    if ([files count]) {
        handled=_droppedBlk(files);
    }
    
    return handled;
}


@end
