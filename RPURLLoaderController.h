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

	NSURLConnection *_connection;
	NSString *_fileName;
	NSFileHandle *_fileHandle;
    NSString* _secretKey; 
    
    NSInteger _httpStatusCode; 
    
    BOOL _openURLNibLoaded;
	NSModalSession _urlOpenerSession;
}


@property(nonatomic) NSString *urlString;
@property(nonatomic) NSString *secretKey;
@property(nonatomic, readwrite) NSNumber* samplingInterval;
@property(nonatomic, readwrite) NSNumber* samplingTimeout;
@property(nonatomic, readonly) NSString *fileName;
@property(nonatomic, readonly, assign) BOOL isLoadingURL;

@property(nonatomic, readwrite, copy) NSArray *recentURLStrings;
@property(nonatomic, readwrite, weak) NSNumber* defaultSamplingInterval;

@property(nonatomic) IBOutlet NSWindow *openURLWindow;
@property(nonatomic) IBOutlet NSWindow *progressWindow;

+ (RPURLLoaderController*)sharedURLLoaderController; 

- (IBAction)openOpenURLDialog:(id)sender;
- (IBAction)openDialogActionButtonClicked:(id)sender;
- (IBAction)openDialogCloseButtonClicked:(id)sender;

- (BOOL)start;

@end
