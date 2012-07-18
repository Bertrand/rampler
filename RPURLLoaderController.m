//
//  RPURLLoaderController.m
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import "RPURLLoaderController.h"
#import "RPApplicationDelegate.h"
#import "RPApplication.h"


@implementation RPURLLoaderController

@synthesize url = _url, compressed = _compressed, fileName = _fileName;
@dynamic urlString; 


+ (NSURL *)addParameters:(NSURL *)url interval:(double)interval
{
	NSURL *result = url;
	NSArray *parts;
	NSString *query = nil;
	NSRange range = { NSNotFound, 0 };
	NSInteger intervalInMicrosecond;
	
	if (interval < MINI_INTERVAL) {
		interval = MINI_INTERVAL;
	}
	// the time is received in ms, but the server receives it in micro seconds
	intervalInMicrosecond = interval * 1000000;
	parts = [[url absoluteString] componentsSeparatedByString:@"?"];
	if ([parts count] > 1) {
		query = [parts objectAtIndex:1];
		range = [query rangeOfString:@"ruby_sanspleur=true"];
	}
	
	if (range.location == NSNotFound) {
		NSString *parameters = [NSString stringWithFormat:@"ruby_sanspleur=true&interval=%d", intervalInMicrosecond];
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

- (void)dealloc
{
	[_fileHandle release];
	[_connection release];
	[_fileName release];
	[super dealloc];
}

- (NSString*)urlString
{
    return [self.url absoluteString];
}

- (void)setUrlString:(NSString*)urlString
{
    self.url = [NSURL URLWithString:urlString];
}

- (BOOL)start
{
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef string = CFUUIDCreateString(NULL, theUUID);
	NSString *realFilename;
	NSAssert(_connection == nil, @"Should have no connection");
		
	_fileName = [[@"/tmp/" stringByAppendingPathComponent:[(NSString *)string stringByAppendingPathExtension:@"rubytrace"]] retain];
	if (_compressed) {
		realFilename = [_fileName stringByAppendingPathExtension:@"gz"];
	} else {
		realFilename = _fileName;
	}
	_fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:open([realFilename UTF8String], O_CREAT | O_WRONLY, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH) closeOnDealloc:YES];
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:_url];
	
	NSDictionary* httpHeaders = [(RPApplication*)[RPApplication sharedApplication] additionalHTTPHeaders];
	for (NSString* key in httpHeaders) {
		[request addValue:[httpHeaders objectForKey:key] forHTTPHeaderField:key];
	}
	_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
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

- (void)_downloadFailed
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:@"No data"];
	[alert setInformativeText:[_url absoluteString]];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)_downloadSucceed
{
	[[NSApp delegate] urlLoaderControllerDidFinish:self];
	[self _close];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (_compressed) {
		if ([[[[NSFileManager defaultManager] attributesOfItemAtPath:[_fileName stringByAppendingPathExtension:@"gz"] error:nil] objectForKey:NSFileSize] longLongValue] < 100) {
			[self _downloadFailed];
		} else {
			system([[NSString stringWithFormat:@"gunzip %@", [_fileName stringByAppendingPathExtension:@"gz"]] UTF8String]);
			[self _downloadSucceed];
		}
	} else {
		if ([[[[NSFileManager defaultManager] attributesOfItemAtPath:_fileName error:nil] objectForKey:NSFileSize] longLongValue] < 100) {
			[self _downloadFailed];
		} else {
			[self _downloadSucceed];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:@"Error while loading the stack trace"];
	[alert setInformativeText:[NSString stringWithFormat:@"%@ %@", error, [error userInfo]]];
	[alert setAlertStyle:NSWarningAlertStyle];
	[error retain];
	[alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:error];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)error
{
	[self _close];
	[[NSApp delegate] urlLoaderController:self didFailWithError:error];
	[(id)error release];
}


- (IBAction)openDialogActionButtonClicked:(id)sender
{
    
}


@end
