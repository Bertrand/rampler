//
//  RPSha1Signer.m
//  Rampler
//
//  Copyright 2012 Fotonauts. All rights reserved.
//

#import "RPSha1Signer.h"

 
@implementation RPSha1Signer

@synthesize data;
@synthesize key; 

@dynamic dataString;
@dynamic keyHexString;
@dynamic signature;
@dynamic signatureHexString;


+ (NSData*)sha1SignatureOfData:(NSData*)data withKey:(NSData*)key
{
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
    
}

- (void) setKeyHexString:(NSString*)keyHexString
{
    
}

- (NSData*) signature; 
- (NSString)* signatureHexString; 
@end
