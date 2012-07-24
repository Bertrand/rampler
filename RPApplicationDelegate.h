//
//  RPApplicationDelegate.h
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RPWebViewController;

@interface RPApplicationDelegate : NSObject
{

    
	RPWebViewController *webViewController;
}

- (IBAction)openWebView:(id)sender;

@end
