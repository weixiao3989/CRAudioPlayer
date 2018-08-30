//
//  UIDevice+Version.m
//
//  Created by Darktt on 13/4/23.
//  Copyright (c) 2013 Darktt Personal Company. All rights reserved.
//

#import "UIDevice+Version.h"

@implementation UIDevice (Version)

- (BOOL)systemVersionIsEqualVersion:(NSString *)version
{
    NSString *currentVersion = [[UIDevice currentDevice] systemVersion];
    
    if ([currentVersion compare:version options:NSNumericSearch] == NSOrderedSame) {
        return YES;
    }
    
    return NO;
}

- (BOOL)systemVersionIsGreaterThanVersion:(NSString *)version
{
    NSString *currentVersion = [[UIDevice currentDevice] systemVersion];
    
    if ([currentVersion compare:version options:NSNumericSearch] == NSOrderedDescending) {
        return YES;
    }
    
    return NO;
}

- (BOOL)systemVersionIsLessThanVersion:(NSString *)version
{
    NSString *currentVersion = [[UIDevice currentDevice] systemVersion];
    
    if ([currentVersion compare:version options:NSNumericSearch] == NSOrderedAscending) {
        return YES;
    }
    
    return NO;
}

- (BOOL)systemVersionIsGreateThanOrEqualVersion:(NSString *)version
{
    NSString *currentVersion = [[UIDevice currentDevice] systemVersion];
    
    if ([currentVersion compare:version options:NSNumericSearch] != NSOrderedAscending) {
        return YES;
    }
    
    return NO;
}

- (BOOL)systemVersionIsLessThanOrEqualVersion:(NSString *)version
{
    NSString *currentVersion = [[UIDevice currentDevice] systemVersion];
    
    if ([currentVersion compare:version options:NSNumericSearch] != NSOrderedDescending) {
        return YES;
    }
    
    return NO;
}

@end
