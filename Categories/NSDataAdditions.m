//
//  NSDataAdditions.m
//  Rampler
//
//  Copyright 2012 Fotonauts. All rights reserved.
//

#import "NSDataAdditions.h"

@implementation NSData (NSDataAdditions)

+ (NSData*)dataFromHexString:(NSString*)hexString
{
    NSMutableData *stringData = [[NSMutableData alloc] initWithCapacity:[hexString length]/2];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [hexString length] / 2; i++) {
        byte_chars[0] = [hexString characterAtIndex:i*2];
        byte_chars[1] = [hexString characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [stringData appendBytes:&whole_byte length:1]; 
    }
    return stringData;
}

- (NSString*)hexString
{
    const unsigned char *dataBuffer = (const unsigned char *)[self bytes];
    if (!dataBuffer) return nil;
    
    NSUInteger          dataLength  = [self length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02X", (unsigned long)dataBuffer[i]]];
    
    return hexString;
}

@end
