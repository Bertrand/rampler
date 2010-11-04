//
//  RTApplicationDelegate.h
//  Rampler
//
//  Created by Jérôme Lebel on 04/11/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RTApplicationDelegate : NSObject
{
	IBOutlet NSWindow *_openURLDialog;
	IBOutlet NSTextField *_urlTextField;
	IBOutlet NSTextField *_intervalTextField;
	
	IBOutlet NSWindow *_loadingWindow;
	IBOutlet NSProgressIndicator *_loadingIndicator;
	
	NSModalSession _urlOpenerSession;
}

- (BOOL)openURL:(NSURL *)url;

- (IBAction)openURLAction:(id)sender;
- (IBAction)closeURLOpenerAction:(id)sender;
- (IBAction)validURLOpenerAction:(id)sender;

@end
