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
	NSString*	__weak type;
	NSString*	__weak ns;
	NSString*	__weak function;
	NSString*	__weak symbol;
	NSString*	__weak symbolId;
	NSUInteger	tickCount;
	double		duration;
	
	NSInteger	logLineNumber; 
	NSString*	logLine;

}


@property (nonatomic, readwrite, assign) NSInteger	threadId;
@property (nonatomic, readwrite, assign) SInt64		time;
@property (nonatomic, readwrite, weak) NSString*	type;
@property (nonatomic, readwrite, weak) NSString*	ns;
@property (nonatomic, readwrite, weak) NSString*	function;
@property (nonatomic, readwrite) NSString*	file; // file + line
@property (nonatomic, readwrite) NSString*	fileName;
@property (nonatomic, readwrite, assign) UInt32		fileLine;
@property (nonatomic, readwrite, assign) NSInteger	stackDepth;
@property (nonatomic, readwrite, assign) NSUInteger	tickCount;
@property (nonatomic, readwrite, assign) double		duration;

@property (nonatomic, readwrite, weak) NSString*	symbol;
@property (nonatomic, readwrite, weak) NSString*	symbolId;

@property (nonatomic, readwrite) NSString*	logLine;
@property (nonatomic, readwrite, assign) NSInteger	logLineNumber;

- (BOOL) isFunctionBegin;

@end
