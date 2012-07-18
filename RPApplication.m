//
//  RPApplication.m
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
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
