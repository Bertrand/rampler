//
//  RPURLLoaderController.m
//  Rampler
//
//  Created by Jérôme Lebel on 10/11/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import "RPURLLoaderController.h"
#import "RPApplicationDelegate.h"

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

@implementation RPURLLoaderController

@synthesize url = _url, interval = _interval, fileName = _fileName;

- (void)dealloc
{
	[_fileHandle release];
	[_connection release];
	[_fileName release];
	[super dealloc];
}

- (BOOL)start
{
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef string = CFUUIDCreateString(NULL, theUUID);
	NSAssert(_connection == nil, @"Should have no connection");
		
	_fileName = [[@"/tmp/" stringByAppendingPathComponent:[(NSString *)string stringByAppendingPathExtension:@"rubytrace"]] retain];
	_fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:open([[_fileName stringByAppendingPathExtension:@"gz"] UTF8String], O_CREAT | O_WRONLY, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH) closeOnDealloc:YES];
	_connection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:addParameter(_url, _interval)] delegate:self startImmediately:YES];
	[NSBundle loadNibNamed:@"RPURLLoaderController" owner:self];
	[_progressIndicator startAnimation:nil];
	[_textField setStringValue:[_url absoluteString]];
	[_window makeKeyAndOrderFront:nil];
	
	CFRelease(string);
	CFRelease(theUUID);
	return YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_fileHandle writeData:data];
}

- (void)_close
{
	[_fileHandle closeFile];
	[_fileHandle release];
	_fileHandle = nil;
	[_fileHandle closeFile];
	[_fileHandle release];
	_fileHandle = nil;
	[_window close];
	[_window release];
	_window = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSLog(@"%@", _fileName);
	[self _close];
	system([[NSString stringWithFormat:@"gunzip %@", [_fileName stringByAppendingPathExtension:@"gz"]] UTF8String]);
	[[NSApp delegate] urlLoaderControllerDidFinish:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self _close];
	[[NSApp delegate] urlLoaderController:self didFailWithError:error];
}

@end
