//
//  RPURLLoaderController.h
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MINI_INTERVAL 0.00001

@interface RPURLLoaderController : NSController
{
	IBOutlet NSWindow *_window;

	BOOL compressed;
	NSURLConnection *_connection;
	NSString *_fileName;
	NSFileHandle *_fileHandle;
    NSString* _secretKey; 
    
    BOOL _openURLNibLoaded;
	NSModalSession _urlOpenerSession;
}


@property(nonatomic, retain) NSString *urlString;
@property(nonatomic, retain) NSString *secretKey;
@property(nonatomic, readwrite, retain) NSNumber* samplingInterval;
@property(nonatomic, assign) BOOL compressed;
@property(nonatomic, readonly) NSString *fileName;
@property(nonatomic, readonly, assign) BOOL isLoadingURL;

@property(nonatomic, readwrite, copy) NSArray *recentURLStrings;
@property(nonatomic, readwrite, assign) NSNumber* defaultSamplingInterval;

@property(nonatomic, retain) IBOutlet NSWindow *openURLWindow;
@property(nonatomic, retain) IBOutlet NSWindow *progressWindow;

- (IBAction)openOpenURLDialog:(id)sender;
- (IBAction)openDialogActionButtonClicked:(id)sender;
- (IBAction)openDialogCloseButtonClicked:(id)sender;

- (BOOL)start;

@end
