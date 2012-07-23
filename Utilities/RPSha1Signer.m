//
//  RPSha1Signer.m
//  Rampler
//
//  Copyright 2012 Fotonauts. All rights reserved.
//

#import "RPSha1Signer.h"
#import "NSDataAdditions.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation RPSha1Signer

@synthesize data;
@synthesize key; 

@dynamic dataString;
@dynamic keyHexString;
@dynamic signature;
@dynamic signatureHexString;


+ (NSData*)sha1SignatureOfData:(NSData*)data withKey:(NSData*)key
{
    if (nil == data || nil == key) return nil; 
    void* buffer = malloc(CC_SHA1_DIGEST_LENGTH);
    CCHmac(kCCHmacAlgSHA1, [key bytes], [key length], [data bytes], [data length], buffer);
    return [NSData dataWithBytesNoCopy:buffer length:CC_SHA1_DIGEST_LENGTH freeWhenDone:YES];    
}

- (NSString*) dataString
{
    return [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
}

- (void) setDataString:(NSString*)dataString
{
    self.data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*) keyHexString
{
    return [self.data hexString];
}

- (void) setKeyHexString:(NSString*)keyHexString
{
    self.key = [NSData dataFromHexString:keyHexString];
}

- (NSData*) signature
{
    return [[self class] sha1SignatureOfData:self.data withKey:self.key]; 
}

- (NSString*) signatureHexString
{
    return [self.signature hexString];
}

@end
