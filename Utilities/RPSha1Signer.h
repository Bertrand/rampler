//
//  RPSha1Signer.h
//  Rampler
//
//  Copyright 2012 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RPSha1Signer : NSObject

@property(nonatomic, readwrite, retain) NSData* data; 
@property(nonatomic, readwrite, retain) NSData* key; 

@property(nonatomic, readwrite, copy) NSString* dataString; 
@property(nonatomic, readwrite, copy) NSString* keyHexString; 

@property(nonatomic, readonly, copy) NSData* signature; 
@property(nonatomic, readonly, copy) NSString* signatureHexString; 


+ (NSData*)sha1SignatureOfData:(NSData*)data withKey:(NSData*)key;


@end
