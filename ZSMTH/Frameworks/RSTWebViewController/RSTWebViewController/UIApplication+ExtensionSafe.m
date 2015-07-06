//
//  UIApplication+ExtensionSafe.m
//  RSTWebViewController
//
//  Created by Riley Testut on 12/26/14.
//  Copyright (c) 2014 Riley Testut. All rights reserved.
//

#import "UIApplication+ExtensionSafe.h"

@implementation UIApplication (ExtensionSafe)

+ (instancetype)rst_sharedApplication
{
    BOOL isApplicationExtension = ([[[NSBundle mainBundle] executablePath] containsString:@".appex/"]);
    
    if (isApplicationExtension)
    {
        return nil;
    }
    
    UIApplication *application = [UIApplication performSelector:@selector(sharedApplication)];
    return application;
}

- (BOOL)rst_openURL:(NSURL *)URL
{
    if ([self performSelector:@selector(openURL:) withObject:URL])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

@end
