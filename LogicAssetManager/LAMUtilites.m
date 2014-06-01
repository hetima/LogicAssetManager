//
//  LAMUtilites.m
//  LogicAssetManager
//
//  Created by hetima on 2014/05/31.
//  Copyright (c) 2014 hetima. All rights reserved.
//

#import "LAMUtilites.h"
#import <sys/stat.h>

NSError* LAMErrorWithDescription(NSString* text)
{
    NSDictionary* userInfo=@{NSLocalizedDescriptionKey: text};
    NSError* error=[NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:userInfo];
    return error;
}


BOOL LAMSymlink(NSString* fromPath, NSString* linkPath, NSError **error)
{
    const char* from=[fromPath fileSystemRepresentation];
    const char* to=[linkPath fileSystemRepresentation];
    
    NSString* errDescription=nil;
    //check exists
    struct stat st;
    int result=lstat(to, &st);
    if (result==0) {
        if (S_ISLNK(st.st_mode)) {
            result=unlink(to);
            if (result!=0) {
                errDescription=[NSString stringWithFormat:@"can't remove existing symbolic link (%@)", [linkPath lastPathComponent]];
            }
        }else{
            errDescription=[NSString stringWithFormat:@"file exists at symbolic link location (%@)", [linkPath lastPathComponent]];
        }
    }
    
    if (!errDescription) {
        result=symlink(from, to);
        if (result!=0) {
            errDescription=[NSString stringWithFormat:@"can't create symbolic link (%@)", [linkPath lastPathComponent]];
        }
    }
    
    if (errDescription) {
        if (error) {
            NSError* error_=LAMErrorWithDescription(errDescription);
            *error=error_;
        }
        return NO;
    }
    
    return YES;
}


NSString* LAMDigIfDirectoryHasOneSubDirectoryOnly(NSString* path)
{
    NSArray* files=[[NSFileManager defaultManager]contentsOfDirectoryAtPath:path error:nil];
    if (![files count]) {
        return path;
    }
    
    NSString* subDirectory=nil;
    NSArray* ignoredExtensions=@[@"txt", @"rtf", @"rtfd", @"md", @"app"];
    for (NSString* name in files) {
        //ignore some file types
        if ([name hasPrefix:@"."] || [ignoredExtensions containsObject:[name pathExtension]]) {
            continue;
        }
        
        if (subDirectory) {
            subDirectory=nil;
            break;
        }
        
        BOOL isDir;
        NSString* fullPath=[path stringByAppendingPathComponent:name];
        [[NSFileManager defaultManager]fileExistsAtPath:fullPath isDirectory:&isDir];
        if (isDir) {
            subDirectory=fullPath;
        }else{
            subDirectory=nil;
            break;
        }
    }
    
    if (subDirectory) {
        return subDirectory;
    }
    
    return path;

}
