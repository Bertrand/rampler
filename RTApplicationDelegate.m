//
//  RTApplicationDelegate.m
//  Rampler
//
//  Created by Jérôme Lebel on 04/11/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import "RTApplicationDelegate.h"

NSURL *addParameter(NSURL *url, int interval)
{
	NSURL *result = url;
	NSArray *parts;
	NSString *query = nil;
	NSRange range = { NSNotFound, 0 };
	
	if (interval < 1) {
		interval = 1;
	}
	// the time is received in ms, but the server receives it in micro seconds
	interval = interval * 1000;
	parts = [[url absoluteString] componentsSeparatedByString:@"?"];
	if ([parts count] > 1) {
		query = [parts objectAtIndex:1];
		range = [query rangeOfString:@"ruby_sanspleur=true"];
	}
	
	if (range.location == NSNotFound) {
		NSString *parameters = [NSString stringWithFormat:@"ruby_sanspleur=true&interval=%d", interval];
		NSString *urlString;
		
		if (query) {
			query = [query stringByAppendingFormat:@"&%@", parameters];
		} else {
			query = parameters;
		}
		urlString = [NSString stringWithFormat:@"%@?%@", [parts objectAtIndex:0], query];
		if (![url scheme] || [[url scheme] isEqualToString:@""]) {
			urlString = [@"http://" stringByAppendingString:urlString];
		}
		result = [NSURL URLWithString:urlString];
	}
	return result;
}

@implementation RTApplicationDelegate

- (BOOL)openURL:(NSURL *)url
{
	NSData *data;
	BOOL result = NO;
	
	data = [NSData dataWithContentsOfURL:addParameter(url, [[_intervalTextField stringValue] intValue])];
	if (data) {
		CFUUIDRef theUUID = CFUUIDCreate(NULL);
		CFStringRef string = CFUUIDCreateString(NULL, theUUID);
		NSString *filename;
		
		filename = [@"/tmp/" stringByAppendingPathComponent:[(NSString *)string stringByAppendingPathExtension:@"rubytrace"]];
		[data writeToFile:[filename stringByAppendingPathExtension:@"gz"] atomically:NO];
		system([[NSString stringWithFormat:@"gunzip %@", [filename stringByAppendingPathExtension:@"gz"]] UTF8String]);
		result = [[NSWorkspace sharedWorkspace] openFile:filename];
	}
	return result;
}

- (IBAction)openURLAction:(id)sender
{
	_urlOpenerSession = [[NSApplication sharedApplication] beginModalSessionForWindow:_openURLDialog];
	[[NSApplication sharedApplication] runModalSession:_urlOpenerSession];
}

- (IBAction)closeURLOpenerAction:(id)sender
{
	[[NSApplication sharedApplication] endModalSession:_urlOpenerSession];
	[_openURLDialog orderOut:nil];
}

- (IBAction)validURLOpenerAction:(id)sender
{
	NSModalSession session;
	
	[[NSApplication sharedApplication] endModalSession:_urlOpenerSession];
	[_openURLDialog orderOut:nil];
	
	session = [[NSApplication sharedApplication] beginModalSessionForWindow:_loadingWindow];
	[_loadingIndicator startAnimation:nil];
	[self openURL:[NSURL URLWithString:[_urlTextField stringValue]]];
	[[NSApplication sharedApplication] endModalSession:session];
	[_loadingIndicator stopAnimation:nil];
	[_loadingWindow orderOut:nil];
}

@end
