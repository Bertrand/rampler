//
//  RPURLLoaderController.h
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
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
	BOOL compressed;
	NSURLConnection *_connection;
	NSString *_fileName;
	NSFileHandle *_fileHandle;
}

+ (NSURL *)addParameters:(NSURL *)url interval:(double)interval;

@property(nonatomic, retain) NSURL *url;
@property(nonatomic, retain) NSString *urlString;
@property(nonatomic, assign) BOOL compressed;
@property(nonatomic, readonly) NSString *fileName;


- (IBAction)openDialogActionButtonClicked:(id)sender;

- (BOOL)start;

@end
