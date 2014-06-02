//
//  LAMBackdropView.h
//  LogicAssetManager
//
//  Created by hetima on 2014/05/29.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef BOOL (^LAMBackdropViewFileDropped)(NSArray* files);

@interface LAMBackdropView : NSView

@property (nonatomic, strong) id transientLounge;

- (void)registerForFileExtensions:(NSArray*)extensions acceptsFolder:(BOOL)acceptsFolder completion:(LAMBackdropViewFileDropped)blk;

@end
