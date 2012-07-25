//
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import "RPKeychainWrapper.h"

@interface RPKeychainWrapper()
+ (void)_findItemAndPassword:(NSString*)serviceName accountName:(NSString*)accountName password:(NSString* __autoreleasing *)password keychainItem:(SecKeychainItemRef*) item;
@end

@implementation RPKeychainWrapper


+ (void)_findItemAndPassword:(NSString*)serviceName accountName:(NSString*)accountName password:(NSString* __autoreleasing *)password keychainItem:(SecKeychainItemRef*) item
{
    
    OSStatus status;
    NSData* utf8ServiceName = [serviceName dataUsingEncoding:NSUTF8StringEncoding];
    NSData* utf8AccountName = [accountName dataUsingEncoding:NSUTF8StringEncoding];
    
    void* passwordBytes = NULL;
    UInt32 passwordBytesLength = 0;
    
    status = SecKeychainFindGenericPassword(
                                              NULL, // default keychain
                                              [utf8ServiceName length],
                                              (const char*)[utf8ServiceName bytes],
                                              [utf8AccountName length],
                                              (const char*)[utf8AccountName bytes],
                                              password ? &passwordBytesLength : NULL,
                                              password ? &passwordBytes : NULL,
                                              item
                                              );
    
    
	if (status == 0 && password != NULL) {
		NSData* passwordData = [NSData dataWithBytes:passwordBytes length:passwordBytesLength];
        *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
	}
	
	if (passwordBytes) SecKeychainItemFreeContent(NULL, passwordBytes);
}

+ (void) setInternetPassword:(NSString*)password forServiceName:(NSString*)serviceName accountName:(NSString*)accountName
{
    OSStatus status;

    
    NSData* utf8ServiceName = [serviceName dataUsingEncoding:NSUTF8StringEncoding];
    NSData* utf8AccountName = [accountName dataUsingEncoding:NSUTF8StringEncoding];
    NSData* utf8Password = [password dataUsingEncoding:NSUTF8StringEncoding];
    
	SecKeychainItemRef item = NULL;
    [self _findItemAndPassword:serviceName accountName:accountName password:NULL keychainItem:&item];
    
	if (item == NULL) {
		status = SecKeychainAddGenericPassword (
                                                NULL,
                                                [utf8ServiceName length],
                                                (const char*)[utf8ServiceName bytes],
                                                [utf8AccountName length],
                                                (const char*)[utf8AccountName bytes],
                                                [utf8Password length],
                                                (const char*)[utf8Password bytes],
                                                NULL
                                                );
		NSAssert1(status == 0, @"Unable to modify generic password in keychain (result code : %d)", status);
	} else {
		status = SecKeychainItemModifyAttributesAndData (
                                                         item,         
                                                         NULL, // no change to attributes
                                                         [utf8Password length],
                                                         (const char*)[utf8Password bytes]
                                                         );
		NSAssert1(status == 0, @"Unable to modify generic password in keychain (result code : %d)", status);
	}
    
	if (item) CFRelease(item);
}

+ (NSString*)internetPasswordForServiceName:(NSString*)serviceName accountName:(NSString*)accountName
{
	NSString* password = NULL; 
    [self _findItemAndPassword:serviceName accountName:accountName password:&password keychainItem:NULL];
	return password;
}

+ (void)removeInternetPasswordForServiceName:(NSString*)serviceName accountName:(NSString*)accountName
{
	SecKeychainItemRef item = NULL;
    [self _findItemAndPassword:serviceName accountName:accountName password:NULL keychainItem:&item];
	
	if (item) {
		SecKeychainItemDelete(item);
		CFRelease(item);
	}
}

@end