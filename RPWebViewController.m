//
//  RPWebViewController.m
//  Rampler
//
//  Created by Jérôme Lebel on 14/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RPWebViewController.h"


@implementation RPWebViewController

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
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[addressTextField stringValue]]]];
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
	[window setTitle:title];
}

@end
