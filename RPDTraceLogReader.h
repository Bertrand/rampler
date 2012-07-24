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
	
	// xxx - this is a hack
	RPLogLine*	__weak currentLine;
	NSInteger	currentLineNumber;
	BOOL		eof;
}


@property (nonatomic, readwrite, assign) NSInteger	logLineNumber;
@property (nonatomic, readwrite) NSData*	data;
@property (nonatomic, readwrite) NSMutableArray*	lines;
@property (nonatomic, readwrite, assign) BOOL eof;
@property (nonatomic, readwrite, weak) RPLogLine*	currentLine;

- (id) initWithData:(NSData*)data;

- (BOOL) moveNextLine; // return false if eof is met

- (void) readData;
- (RPLogLine*) parseLine:(NSString*)line;


@end
