//
//  LAMRenamer.h
//  LogicAssetManager
//
//  Created by hetima on 2014/06/01.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^LAMRenamerRenameHandler)(NSString* newName);

@interface LAMRenamer : NSObject

@property (nonatomic, strong) IBOutlet NSWindow* sheet;
@property (nonatomic, weak) IBOutlet NSTextField* nameField;
@property (nonatomic, weak) IBOutlet NSTextField* noteField;

- (void)renameWithOldName:(NSString*)oldName sheetParentWindow:(NSWindow*)window completion:(LAMRenamerRenameHandler)blk;


@end
