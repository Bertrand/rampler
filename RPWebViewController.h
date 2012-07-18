//
//  RPWebViewController.h
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface RPWebViewController : NSObject
{
	IBOutlet NSWindow *window;
	IBOutlet NSButton *backButton;
    IBOutlet NSButton *forwardButton;
    IBOutlet NSTextField *addressTextField;
    IBOutlet WebView *webView;
	IBOutlet NSTextField *statusBar;
	
	NSString *statusBarValue;
}

@property (nonatomic, retain, readonly) NSString *statusBarValue;

- (IBAction)backButtonAction:(id)sender;
- (IBAction)forwardButtonAction:(id)sender;
- (IBAction)addressTextFieldAction:(id)sender;

- (void)open;

@end
