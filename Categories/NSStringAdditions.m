//
//  NSStringAdditions.m
//  Rampler
//
//  Created by Bertrand Guiheneuf on 7/25/12.
//  Copyright (c) 2012 Fotonauts. All rights reserved.
//

#import "NSStringAdditions.h"

@implementation NSString(NSStringAdditions)

- (NSString *)encodeAsURLParameter
{
    CFStringRef result = CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)self, NULL, (CFStringRef)@" !*'\"();:@&=+$,/?%#[]%", kCFStringEncodingUTF8);
    return CFBridgingRelease(result);
}

@end
