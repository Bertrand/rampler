//
//  RPDTraceLogReader.h
//  Rampler
//
//  Created by Guiheneuf Bertrand on 9/29/10.
//  Copyright 2010 Fotonauts. All rights reserved.
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


@property (readwrite,assign) NSInteger	logLineNumber;
@property (readwrite,retain) NSData*	data;
@property (readwrite,assign) NSMutableArray*	lines;
@property (readwrite,assign) BOOL eof;
@property (readwrite,assign) RPLogLine*	currentLine;

- (id) initWithData:(NSData*)data;

- (BOOL) moveNextLine; // return false if eof is met

- (void) readData;
- (RPLogLine*) parseLine:(NSString*)line;


@end
