//
//  RPRubyTraceLogReader.h
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RPStackFrame.h"
#import "RPLogReader.h"

@class RPSampleSession;

@interface RPRubyTraceLogReader : NSObject<RPLogReader> {
    // declare those vars so they can be mutable internally
    NSMutableString *beginningInfoDescription; 
    NSMutableString *endingInfoDescription; 
    
    NSInteger _currentPosition;
}

@property (nonatomic, readwrite, assign) NSInteger	logLineNumber;
@property (nonatomic, readwrite) NSData*	data;
@property (nonatomic, readwrite, weak) RPStackFrame*	currentLine;
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
- (RPStackFrame*) parseLine:(NSString*)line;

- (RPSampleSession*)sampleSession;

@end
