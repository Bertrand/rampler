//
//  RPApplicationDelegate.h
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RPURLLoaderController;
@class RPWebViewController;

@interface RPApplicationDelegate : NSObject
{
	IBOutlet NSWindow *_openURLDialog;
	IBOutlet NSTextField *_urlTextField;
	IBOutlet NSTextField *_secretKeyField;
	IBOutlet NSTextField *_intervalTextField;
	IBOutlet NSPopUpButton *_urlHistoricPopUp;
	
	
	NSModalSession _urlOpenerSession;
	NSMutableArray *_urlHistoric;
    
	RPWebViewController *webViewController;
}


//- (BOOL)openURL:(NSURL *)url withInterval:(double)interval;
//
//- (IBAction)openURLAction:(id)sender;
//- (IBAction)closeURLOpenerAction:(id)sender;
//- (IBAction)validURLOpenerAction:(id)sender;
- (IBAction)openWebView:(id)sender;
//- (IBAction)urlHistoricPopUpButtonAction:(id)sender;

//- (void)urlLoaderControllerDidFinish:(RPURLLoaderController *)urlLoaderController;
//- (void)urlLoaderController:(RPURLLoaderController *)urlLoaderController didFailWithError:error;

@end
