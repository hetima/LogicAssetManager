//
//  LAMRenamer.m
//  LogicAssetManager
//
//  Created by hetima on 2014/06/01.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import "LAMRenamer.h"

@implementation LAMRenamer


- (void)renameWithOldName:(NSString*)oldName sheetParentWindow:(NSWindow*)window completion:(LAMRenamerRenameHandler)blk
{
    
    NSString* note=[NSString stringWithFormat:@"Enter new name for \"%@\"", oldName];
    [self.noteField setStringValue:note];
    [self.nameField setStringValue:oldName];
    [self.nameField selectText:nil];
    [window beginSheet:self.sheet completionHandler:^(NSModalResponse returnCode) {
        if (returnCode==NSAlertFirstButtonReturn) {
            NSString* newName=[self.nameField stringValue];
            newName=[newName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            newName=[[newName componentsSeparatedByString:@"\n"]firstObject];
            
            if ([newName length] && ![newName isEqualToString:oldName]) {
                blk(newName);
            }
        }
    }];
    
}

- (IBAction)actEndSheet:(id)sender
{
    NSWindow *parentWindow=[[sender window]sheetParent];
    [parentWindow endSheet:[sender window] returnCode:[sender tag]];
}

@end
