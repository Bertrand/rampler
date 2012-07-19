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
    
    BOOL _openURLNibLoaded;
	NSModalSession _urlOpenerSession;
}

+ (NSURL *)addParameters:(NSURL *)url interval:(double)interval;

@property(nonatomic, retain) NSString *urlString;
@property(nonatomic, retain) NSString *secretKey;
@property(nonatomic, readwrite, assign) UInt32 samplingInterval;
@property(nonatomic, assign) BOOL compressed;
@property(nonatomic, readonly) NSString *fileName;

@property(nonatomic, readwrite, copy) NSString *defaultURLString;
@property(nonatomic, readwrite, copy) NSArray *recentURLStrings;
@property(nonatomic, readwrite, assign) double defaultSamplingInterval;


@property(nonatomic, retain) IBOutlet NSWindow *openURLWindow;

- (IBAction)openOpenURLDialog:(id)sender;
- (IBAction)openDialogActionButtonClicked:(id)sender;
- (IBAction)openDialogCloseButtonClicked:(id)sender;

- (BOOL)start;

@end
