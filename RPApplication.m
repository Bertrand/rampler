//
//  RPApplication.m
//  Rampler
//
//  Created by Guiheneuf Bertrand on 08/04/11.
//  Copyright 2011 Fotonauts. All rights reserved.
//

#import "RPApplication.h"


@implementation RPApplication

@synthesize additionalHTTPHeaders = _additionalHTTPHeaders;

- (NSDictionary*) additionalHTTPHeaders
{
	return (NSDictionary*)[[NSUserDefaults standardUserDefaults] objectForKey:@"additionalHTTPHeaders"];
}

- (void) setAdditionalHTTPHeaders:(NSMutableDictionary *)additionalHTTPHeaders
{
	[[NSUserDefaults standardUserDefaults] setObject:additionalHTTPHeaders forKey:@"additionalHTTPHeaders"];
}

@end
