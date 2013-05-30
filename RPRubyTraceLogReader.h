//
//  RPRubyTraceLogReader.h
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RPLogLine.h"
#import "RPLogReader.h"


@interface RPRubyTraceLogReader : NSObject<RPLogReader> {
    // declare those vars so they can be mutable internally
    NSMutableString *beginningInfoDescription; 
    NSMutableString *endingInfoDescription; 
    
	// xxx - this is a hack
	RPLogLine*	__weak currentLine;
    
    NSInteger _currentPosition;
}

@property (nonatomic, readwrite, assign) NSInteger	logLineNumber;
@property (nonatomic, readwrite) NSData*	data;
@property (nonatomic, readwrite, weak) RPLogLine*	currentLine;
@property (nonatomic, readonly) NSString *beginningInfoDescription;
@property (nonatomic, readonly) NSString *endingInfoDescription;
@property (nonatomic, readonly, assign) double interval;
@property (nonatomic, readonly) NSURL* url;
@property (nonatomic, readonly) NSDate* startDate;
@property (nonatomic, readonly, assign) double duration;
@property (nonatomic, readonly, assign) NSUInteger sampleCount;

@property (nonatomic) NSError* parseError;

- (id) initWithData:(NSData*)data;

- (BOOL) readData;
- (RPLogLine*) parseLine:(NSString*)line;

@end
