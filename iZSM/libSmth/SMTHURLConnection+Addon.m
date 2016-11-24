//
//  NewSmth
//
//  Created by Naitong Yu on 14/10/7.
//  Copyright (c) 2014 Naitong Yu. All rights reserved.
//

#import "SMTHURLConnection+Addon.h"

@implementation SMTHURLConnection (Addon)

-(int)net_error
{
    return net_error;
}

-(NSString *)net_error_desc
{
    return net_error_desc;
}

-(NSString *)apiGetUserdata_attpost_path:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString * diskCachePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"PostAtt"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:diskCachePath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
    }
    return [diskCachePath stringByAppendingPathComponent:fileName];
}

@end