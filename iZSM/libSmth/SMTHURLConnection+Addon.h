//
//  NewSmth
//
//  Created by Naitong Yu on 14/10/7.
//  Copyright (c) 2014 Naitong Yu. All rights reserved.
//

#import "SMTHURLConnection.h"

@interface SMTHURLConnection (Addon)

@property (nonatomic, readonly) int net_error;

@property (nonatomic, readonly) NSString *net_error_desc;

-(NSString *)apiGetUserdata_attpost_path:(NSString *)fileName;

@end