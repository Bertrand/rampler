//
//  RPURLLoaderController.h
//  Rampler
//
//  Created by Jérôme Lebel on 10/11/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MINI_INTERVAL 0.00001

@interface RPURLLoaderController : NSObject
{
	IBOutlet NSWindow *_window;
	IBOutlet NSTextField *_textField;
	IBOutlet NSProgressIndicator *_progressIndicator;
	IBOutlet NSButton *_button;
	
	NSURL *_url;
	double _interval;
	NSURLConnection *_connection;
	NSString *_fileName;
	NSFileHandle *_fileHandle;
}

@property(nonatomic, retain) NSURL *url;
@property(nonatomic, assign) double interval;
@property(nonatomic, readonly) NSString *fileName;

- (BOOL)start;

@end
