//
//  RPApplicationDelegate.m
//  Rampler
//
//  Created by Jérôme Lebel on 04/11/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import "RPApplicationDelegate.h"
#import "RPURLLoaderController.h"
#import "RPWebViewController.h"

@implementation RPApplicationDelegate

- (NSURL *)defaultURLValue
{
	NSURL *result;
    
	result = [[NSUserDefaults standardUserDefaults] URLForKey:@"urlopen"];
    if (!result) {
    	result = [NSURL URLWithString:@"http://www.testing.ftnz.net/"];
    }
    return result;
}

- (void)setDefaultURLValue:(NSURL *)url
{
	[[NSUserDefaults standardUserDefaults] setURL:url forKey:@"urlopen"];
}

- (double)defaultIntervalValue
{
	double result;
	
    result = [[NSUserDefaults standardUserDefaults] doubleForKey:@"interval"];
    if (result < MINI_INTERVAL) {
    	result = MINI_INTERVAL;
    }
    return result;
}

- (void)setDefaultIntervalValue:(double)interval
{
	[[NSUserDefaults standardUserDefaults] setDouble:interval forKey:@"interval"];
}

- (BOOL)openURL:(NSURL *)url withInterval:(double)interval
{
	RPURLLoaderController *urlLoader;
	
	urlLoader = [[RPURLLoaderController alloc] init];
	urlLoader.url = url;
	urlLoader.interval = interval;
	[urlLoader start];
	return YES;
}

- (IBAction)openURLAction:(id)sender
{
    [_urlTextField setStringValue:[[self defaultURLValue] absoluteString]];
    [_intervalTextField setStringValue:[NSString stringWithFormat:@"%.2f", [self defaultIntervalValue] * 1000]];
	[_openURLDialog makeFirstResponder:_urlTextField];
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
	NSURL *url;
    double interval;
    
	[[NSApplication sharedApplication] endModalSession:_urlOpenerSession];
	[_openURLDialog orderOut:nil];
	
    url = [NSURL URLWithString:[_urlTextField stringValue]];
    interval = [[_intervalTextField stringValue] doubleValue] / 1000.0;
	[self openURL:url withInterval:interval];
    [self setDefaultURLValue:url];
    [self setDefaultIntervalValue:interval];
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

- (IBAction)openWebView:(id)sender
{
	if (!webViewController) {
	    webViewController = [[RPWebViewController alloc] init];
    }
    [webViewController open];
}

@end
