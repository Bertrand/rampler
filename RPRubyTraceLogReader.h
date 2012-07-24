//
//  RPRubyTraceLogReader.h
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RPLogLine.h"

@interface RPRubyTraceLogReader : NSObject<RPLogReader> {
	NSInteger	logLineNumber;
	NSData*		data;
	NSMutableArray* stacks;
    NSMutableString* beginningInfoDescription;
	NSMutableString* endingInfoDescription;
	NSString*	version;
	double interval;
	NSURL* url;
	NSDate* startDate;
	double duration;
	NSUInteger sampleCount;
	
	// xxx - this is a hack
	RPLogLine*	__weak currentLine;
	NSInteger	currentLineNumber;
	BOOL		eof;
}

@property (nonatomic, readwrite, assign) NSInteger	logLineNumber;
@property (nonatomic, readwrite) NSData*	data;
@property (nonatomic, readwrite, assign) BOOL eof;
@property (nonatomic, readwrite, weak) RPLogLine*	currentLine;
@property (nonatomic, readonly) NSString *beginningInfoDescription;
@property (nonatomic, readonly) NSString *endingInfoDescription;
@property (nonatomic, readonly, assign) double interval;
@property (nonatomic, readonly) NSURL* url;
@property (nonatomic, readonly) NSDate* startDate;
@property (nonatomic, readonly, assign) double duration;
@property (nonatomic, readonly, assign) NSUInteger sampleCount;

- (id) initWithData:(NSData*)data;

- (void) readData;
- (RPLogLine*) parseLine:(NSString*)line;

@end
