//
//  LAMResourcesCoordinator.h
//  LogicAssetManager
//
//  Created by hetima on 2014/05/24.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LAMResourcesCoordinator : NSObject
@property (nonatomic) NSString* outputDirectory;
@property (nonatomic) NSDictionary* originalResourcesMapping;
@property (nonatomic) NSMutableDictionary* mergedResourcesMapping;
@property (nonatomic) BOOL excludesRetinaImage;


- (BOOL)extractFromAssetPaths:(NSArray*)assetPaths;
- (void)mergeMappingFile:(NSString*)plistPath;
- (void)addInstrumentIcon:(NSString*)name id:(NSInteger)imageId group:(NSString*)group;

@end
