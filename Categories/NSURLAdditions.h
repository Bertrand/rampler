//
//  NSURL_DooLittle.h
//  DooLittle
//
//  Created by Guiheneuf Bertrand on 9/20/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSURL (Rampler)

+ (NSString*)queryStringForParameters:(NSDictionary*)parameters;

- (NSDictionary*)rp_queryDictionary;
- (NSURL*) rp_URLByAppendingQuery: (NSDictionary*)query;

@end