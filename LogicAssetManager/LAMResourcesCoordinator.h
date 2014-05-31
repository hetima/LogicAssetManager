//
//  LAMResourcesCoordinator.h
//  LogicAssetManager
//
//  Created by hetima on 2014/05/24.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LAMIconManager;

@interface LAMResourcesCoordinator : NSObject
@property (nonatomic, strong) NSString* outputDirectory;
@property (nonatomic, strong) NSDictionary* originalResourcesMapping;
@property (nonatomic, strong) NSMutableDictionary* mergedResourcesMapping;
@property (nonatomic) BOOL excludesRetinaImage;

@property (nonatomic, strong) NSString* resourcesName;
@property (nonatomic, strong) NSString* mappingFileName;
@property (nonatomic, strong) NSString* originalResourcesPath;
@property (nonatomic, strong) NSString* resourcesLinkPath;
@property (nonatomic, strong) NSString* resourcesLinkDestination;

@property (nonatomic) BOOL extracted;

+ (instancetype)MAResourcesCoordinator;
+ (instancetype)MAResourcesPlugInsSharedCoordinator;
+ (instancetype)MAResourcesLgCoordinator;
+ (instancetype)MAResourcesGBCoordinator;

- (BOOL)extractAssets:(NSArray*)assets error:(NSError**)err;
- (void)mergeMappingFile:(NSString*)plistPath;

@end



@interface LAMMAResourcesCoordinator : LAMResourcesCoordinator

@property (nonatomic, weak) LAMIconManager* iconManager;

@end
