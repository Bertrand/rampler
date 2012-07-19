//
//  RPApplicationDelegate.m
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
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


//- (IBAction)urlHistoricPopUpButtonAction:(id)sender
//{
//	[_urlTextField setStringValue:[[_urlHistoricPopUp selectedItem] title]];
//}

//- (void)urlLoaderControllerDidFinish:(RPURLLoaderController *)urlLoaderController
//{
//	[[NSWorkspace sharedWorkspace] openFile:urlLoaderController.fileName];
//	[urlLoaderController release];
//}

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
	urlLoader.compressed = NO;
	[urlLoader start];
	[httpURL release];
}


@end
