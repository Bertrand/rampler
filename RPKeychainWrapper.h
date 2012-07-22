//
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RPKeychainWrapper : NSObject

+ (void) setInternetPassword:(NSString*)password forServiceName:(NSString*)serviceName accountName:(NSString*)accountName;
+ (NSString*) internetPasswordForServiceName:(NSString*)serviceName accountName:(NSString*)accountName;
+ (void) removeInternetPasswordForServiceName:(NSString*)serviceName accountName:(NSString*) accountName;

@end