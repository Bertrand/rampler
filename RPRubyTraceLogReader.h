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
	
	// xxx - this is a hack
	RPLogLine*	currentLine;
	NSInteger	currentLineNumber;
	BOOL		eof;
}

@property (readwrite,assign) NSInteger	logLineNumber;
@property (readwrite,retain) NSData*	data;
@property (readwrite,assign) BOOL eof;
@property (readwrite,assign) RPLogLine*	currentLine;
@property (readwrite, retain) NSMutableString *infoDescription;

- (id) initWithData:(NSData*)data;

- (void) readData;
- (RPLogLine*) parseLine:(NSString*)line;

@end
