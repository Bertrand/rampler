//
//  RPWebViewController.m
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import "RPWebViewController.h"
#import "RPURLLoaderController.h"


@interface RPWebViewController()

@property (nonatomic) NSString *statusBarValue;

@end


@implementation RPWebViewController

@synthesize statusBarValue;
@synthesize webView;


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
    [webView goBack:sender];
}

- (IBAction)forwardButtonAction:(id)sender
{
    [webView goForward:sender];
}

- (IBAction)leftRightClicked:(id)sender
{
    NSSegmentedControl* control = sender; 
    if ([control selectedSegment] == 0) {
        [self backButtonAction:sender];
    } else {
        [self forwardButtonAction:sender];
    }
}

- (IBAction)refresh:(id)sender
{
    [[webView mainFrame] reload];
}

- (NSString*)currentURLString
{
    WebFrame* frame = [webView mainFrame];
    WebDataSource* currentDataSource;
    (currentDataSource = [frame provisionalDataSource]) || (currentDataSource = [frame dataSource]);
    NSURL* currentURL = [[currentDataSource request] URL];
    return [currentURL absoluteString];
}

- (IBAction)sampleCurrentURL:(id)sender
{
    if ([self currentURLString]) {
        RPURLLoaderController* urlLoader = [RPURLLoaderController sharedURLLoaderController];
        urlLoader.urlString = [self currentURLString];
        [urlLoader openOpenURLDialog:sender];
    }
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
    if (frame == [webView mainFrame])
        [window setTitle:title];
}

@end

@implementation RPWebViewController(WebFrameLoadDelegate)

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    [addressTextField setStringValue:[self currentURLString]];
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