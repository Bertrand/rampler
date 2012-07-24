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
	[urlLoader start];
	[httpURL release];
}


@end
