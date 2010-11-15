//
//  RPRubyTraceLogReader.h
//  Rampler
//
//  Created by Jérôme Lebel on 20/10/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RPLogLine.h"

@interface RPRubyTraceLogReader : NSObject<RPLogReader> {
	NSInteger	logLineNumber;
	NSData*		data;
	NSMutableArray* stacks;
    NSMutableString* infoDescription;
	NSString*	version;
	double interval;
	NSURL* url;
	
	// xxx - this is a hack
	RPLogLine*	currentLine;
	NSInteger	currentLineNumber;
	BOOL		eof;
}

@property (nonatomic, readwrite, assign) NSInteger	logLineNumber;
@property (nonatomic, readwrite, retain) NSData*	data;
@property (nonatomic, readwrite, assign) BOOL eof;
@property (nonatomic, readwrite, assign) RPLogLine*	currentLine;
@property (nonatomic, readwrite, retain) NSMutableString *infoDescription;
@property (nonatomic, readonly, assign) double interval;
@property (nonatomic, readonly, retain) NSURL* url;

- (id) initWithData:(NSData*)data;

- (void) readData;
- (RPLogLine*) parseLine:(NSString*)line;

@end
