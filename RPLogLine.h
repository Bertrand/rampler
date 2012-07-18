//
//  RPLogLine.h
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RPCallTree;
@class RPLogLine;

@protocol RPLogReader <NSObject>

- (double)interval;
- (NSString *)version;
- (NSURL *)url;
- (NSInteger)logLineNumber;
- (void)setLogLineNumber:(NSInteger)logLineNumber;
- (NSData*)data;
- (void)setData:(NSData*)data;
- (BOOL)eof;
- (void)setEof:(BOOL)eof;
- (NSDate *)startDate;
- (double)duration;

- (RPCallTree*)callTree;
@end

@interface RPLogLine : NSObject {
	NSInteger	threadId;
	SInt64		time;
	NSString*	file;
	NSString*	fileName;
	UInt32		fileLine;
	NSInteger	stackDepth;
	NSString*	type;
	NSString*	ns;
	NSString*	function;
	NSString*	symbol;
	NSString*	symbolId;
	NSUInteger	tickCount;
	double		duration;
	
	NSInteger	logLineNumber; 
	NSString*	logLine;

}


@property (nonatomic, readwrite, assign) NSInteger	threadId;
@property (nonatomic, readwrite, assign) SInt64		time;
@property (nonatomic, readwrite, assign) NSString*	type;
@property (nonatomic, readwrite, assign) NSString*	ns;
@property (nonatomic, readwrite, assign) NSString*	function;
@property (nonatomic, readwrite, retain) NSString*	file; // file + line
@property (nonatomic, readwrite, retain) NSString*	fileName;
@property (nonatomic, readwrite, assign) UInt32		fileLine;
@property (nonatomic, readwrite, assign) NSInteger	stackDepth;
@property (nonatomic, readwrite, assign) NSUInteger	tickCount;
@property (nonatomic, readwrite, assign) double		duration;

@property (nonatomic, readwrite, assign) NSString*	symbol;
@property (nonatomic, readwrite, assign) NSString*	symbolId;

@property (nonatomic, readwrite, retain) NSString*	logLine;
@property (nonatomic, readwrite, assign) NSInteger	logLineNumber;

- (BOOL) isFunctionBegin;

@end
