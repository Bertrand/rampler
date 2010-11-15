//
//  RPWebViewController.m
//  Rampler
//
//  Created by Jérôme Lebel on 14/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RPWebViewController.h"

@interface RPWebViewController()

@property (nonatomic, retain) NSString *statusBarValue;

@end


@implementation RPWebViewController

@synthesize statusBarValue;

- (void)dealloc
{
	self.statusBarValue = nil;
	[super dealloc];
}

- (void)open
{
	if (!window) {
    	[NSBundle loadNibNamed:@"WebViewController" owner:self];
        [webView setUIDelegate:self];
        [webView setFrameLoadDelegate:self];
    }
    [window makeKeyAndOrderFront:nil];
}

- (IBAction)backButtonAction:(id)sender
{
}

- (IBAction)forwardButtonAction:(id)sender
{
}

- (IBAction)addressTextFieldAction:(id)sender
{
	NSURL *url;
	
	url = [NSURL URLWithString:[addressTextField stringValue]];
	if (![url scheme] || [[url scheme] isEqualToString:@""]) {
		url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", [addressTextField stringValue]]];
	}
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
	[window setTitle:title];
}

@end

@implementation RPWebViewController(WebFrameLoadDelegate)

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
	[statusBar setStringValue:@"Loading…"];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	[statusBar setStringValue:self.statusBarValue];
}

@end


@implementation RPWebViewController(UIDelegate)

- (void)webView:(WebView *)sender setStatusText:(NSString *)text
{
	if (![webView isLoading]) {
		[statusBar setStringValue:text];
	}
	self.statusBarValue = text;
}

- (NSString *)webViewStatusText:(WebView *)sender
{
	return self.statusBarValue;
}

@end