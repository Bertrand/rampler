//
//  NSDataAdditions.h
//  Rampler
//
//  Copyright 2012 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (NSDataAdditions)

+ (NSData*)dataFromHexString:(NSString*)hexString;
- (NSString*)hexString;

@end
