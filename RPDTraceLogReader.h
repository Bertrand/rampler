//
//  RPDTraceLogReader.h
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RPLogLine.h"

@protocol RPLogReader;

@interface RPDTraceLogReader : NSObject<RPLogReader> {
	NSInteger	logLineNumber; 
	NSData*		data;
	NSMutableArray* lines;
	
	// xxx - this is a hack
	RPLogLine*	currentLine;
	NSInteger	currentLineNumber;
	BOOL		eof;
}


@property (nonatomic, readwrite, assign) NSInteger	logLineNumber;
@property (nonatomic, readwrite, retain) NSData*	data;
@property (nonatomic, readwrite, assign) NSMutableArray*	lines;
@property (nonatomic, readwrite, assign) BOOL eof;
@property (nonatomic, readwrite, assign) RPLogLine*	currentLine;

- (id) initWithData:(NSData*)data;

- (BOOL) moveNextLine; // return false if eof is met

- (void) readData;
- (RPLogLine*) parseLine:(NSString*)line;


@end
