//
//  RPLogLine.h
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RPCallTree;
@class RPStackFrame;



@interface RPStackFrame : NSObject {

}

@property (nonatomic, readwrite, assign) UInt32		fileLine;
@property (nonatomic, readwrite, assign) NSInteger	stackDepth;
@property (nonatomic, readwrite, assign) NSUInteger	tickCount;
@property (nonatomic, readwrite, assign) double		duration;
@property (nonatomic, readwrite, assign) NSInteger	classId;
@property (nonatomic, readwrite, assign) NSInteger	functionId;
@property (nonatomic, readwrite, assign) NSInteger	fileId;

//

@property (nonatomic, readwrite, assign) NSInteger	threadId;
@property (nonatomic, readwrite, assign) SInt64		time;
@property (nonatomic, readwrite) NSString*	type;
@property (nonatomic, readwrite) NSString*	ns;
@property (nonatomic, readwrite) NSString*	function;
@property (nonatomic, readwrite) NSString*	file; // file + line
@property (nonatomic, readwrite) NSString*	fileName;

@property (nonatomic, readwrite) NSString*	symbol;
@property (nonatomic, readwrite) NSString*	symbolId;

@property (nonatomic, readwrite) NSString*	logLine;
@property (nonatomic, readwrite, assign) NSInteger	logLineNumber;

- (BOOL) isFunctionBegin;

@end
