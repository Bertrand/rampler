//
//  RPApplicationDelegate.h
//  Rampler
//
//  Created by Jérôme Lebel on 04/11/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RPURLLoaderController;
@class RPWebViewController;

@interface RPApplicationDelegate : NSObject
{
	IBOutlet NSWindow *_openURLDialog;
	IBOutlet NSTextField *_urlTextField;
	IBOutlet NSTextField *_intervalTextField;
	
	NSModalSession _urlOpenerSession;
	RPWebViewController *webViewController;
}

- (BOOL)openURL:(NSURL *)url withInterval:(double)interval;

- (IBAction)openURLAction:(id)sender;
- (IBAction)closeURLOpenerAction:(id)sender;
- (IBAction)validURLOpenerAction:(id)sender;
- (IBAction)openWebView:(id)sender;

- (void)urlLoaderControllerDidFinish:(RPURLLoaderController *)urlLoaderController;
- (void)urlLoaderController:(RPURLLoaderController *)urlLoaderController didFailWithError:error;

@end
