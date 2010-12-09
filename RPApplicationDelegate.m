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

- (NSArray *)urlHistoricValue
{
	NSArray *array;
	NSMutableArray *result;
	
	array = [[NSUserDefaults standardUserDefaults] arrayForKey:@"urlhistoric"];
	if (!array) {
		result = [NSArray arrayWithObject:[self defaultURLValue]];
	} else {
		result = [NSMutableArray array];
		for (NSString *string in array) {
			[result addObject:[NSURL URLWithString:string]];
		}
	}
	return result;
}

- (void)setURLHistoricValue:(NSArray *)historic
{
	NSMutableArray *values;
	
	values = [[NSMutableArray alloc] init];
	for (NSURL *url in historic) {
		[values addObject:[url absoluteString]];
	}
	[[NSUserDefaults standardUserDefaults] setObject:values forKey:@"urlhistoric"];
	[values release];
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

- (void)updateURLHistoricPopUp
{
	[_urlHistoricPopUp removeAllItems];
	for (NSURL *url in _urlHistoric) {
		[_urlHistoricPopUp addItemWithTitle:[url absoluteString]];
	}
}

- (void)awakeFromNib
{
	_urlHistoric = [[self urlHistoricValue] mutableCopy];
	[self updateURLHistoricPopUp];
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (BOOL)openURL:(NSURL *)url withInterval:(double)interval
{
	RPURLLoaderController *urlLoader;
	
	urlLoader = [[RPURLLoaderController alloc] init];
	urlLoader.url = [RPURLLoaderController addParameters:url interval:interval];
	urlLoader.compressed = YES;
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
	[_urlHistoric removeObject:url];
	[_urlHistoric insertObject:url atIndex:0];
	[self setURLHistoricValue:_urlHistoric];
	[self updateURLHistoricPopUp];
}

- (IBAction)urlHistoricPopUpButtonAction:(id)sender
{
	[_urlTextField setStringValue:[[_urlHistoricPopUp selectedItem] title]];
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

- (void)handleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSURL *url;
	NSURL *httpURL;
	RPURLLoaderController *urlLoader;
	
	url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
	httpURL = [[NSURL alloc] initWithScheme:@"http" host:[url host] path:[url path]];
	
	urlLoader = [[RPURLLoaderController alloc] init];
	urlLoader.url = httpURL;
	urlLoader.compressed = NO;
	[urlLoader start];
	[httpURL release];
}


@end
