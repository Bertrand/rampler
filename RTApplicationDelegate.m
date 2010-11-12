//
//  RTApplicationDelegate.m
//  Rampler
//
//  Created by Jérôme Lebel on 04/11/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import "RTApplicationDelegate.h"
#import "RPURLLoaderController.h"

@implementation RTApplicationDelegate

- (BOOL)openURL:(NSURL *)url
{
	RPURLLoaderController *urlLoader;
	
	urlLoader = [[RPURLLoaderController alloc] init];
	urlLoader.url = url;
	urlLoader.interval = [[_intervalTextField stringValue] intValue];
	[urlLoader start];
	return YES;
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
	[[NSApplication sharedApplication] endModalSession:_urlOpenerSession];
	[_openURLDialog orderOut:nil];
	
	[self openURL:[NSURL URLWithString:[_urlTextField stringValue]]];
}

- (void)urlLoaderControllerDidFinish:(RPURLLoaderController *)urlLoaderController
{
	[[NSWorkspace sharedWorkspace] openFile:urlLoaderController.fileName];
	[urlLoaderController release];
}

- (void)urlLoaderController:(RPURLLoaderController *)urlLoaderController didFailWithError:error
{
	NSLog(@"error %@ %@", urlLoaderController.url, error);
	[urlLoaderController release];
}

@end
