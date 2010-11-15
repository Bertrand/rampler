//
//  RPLogLine.h
//  Rampler
//
//  Created by Guiheneuf Bertrand on 10/4/10.
//  Copyright 2010 Fotonauts. All rights reserved.
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
	
	NSInteger	logLineNumber; 
	NSString*	logLine;

}


@property (readwrite,assign) NSInteger	threadId;
@property (readwrite,assign) SInt64		time;
@property (readwrite,assign) NSString*	type;
@property (readwrite,assign) NSString*	ns;
@property (readwrite,assign) NSString*	function;
@property (readwrite,retain) NSString*	file; // file + line
@property (readwrite,retain) NSString*	fileName;
@property (readwrite,assign) UInt32		fileLine;
@property (readwrite,assign) NSInteger	stackDepth;

@property (readwrite,assign) NSString*	symbol;
@property (readwrite,assign) NSString*	symbolId;

@property (readwrite,retain) NSString*	logLine;
@property (readwrite,assign) NSInteger	logLineNumber;

- (BOOL) isFunctionBegin;

@end
