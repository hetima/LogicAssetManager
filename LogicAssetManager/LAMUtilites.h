//
//  LAMUtilites.h
//  LogicAssetManager
//
//  Created by hetima on 2014/05/31.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import <Foundation/Foundation.h>

NSError* LAMErrorWithDescription(NSString* text);
BOOL LAMSymlink(NSString* fromPath, NSString* linkPath, NSError **error);

NSString* LAMDigIfDirectoryHasOneSubDirectoryOnly(NSString* path);
