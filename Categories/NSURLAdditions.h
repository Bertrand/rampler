//
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSURL (Rampler)

+ (NSString*)queryStringForParameters:(NSDictionary*)parameters;

- (NSDictionary*)rp_queryDictionary;
- (NSURL*)rp_URLByAppendingQuery:(NSDictionary*)query;
- (NSURL*)rp_URLByAppendingQueryValue:(NSString*)value forKey:(NSString*)queryKey;

- (NSURL*)rp_urlBySortingQueryParameters;

@end
