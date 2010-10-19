//
//  RPLogLine.h
//  Rampler
//
//  Created by Guiheneuf Bertrand on 10/4/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RPLogLine : NSObject {
	NSInteger	threadId;
	SInt64		time;
	NSString*	file;
	NSInteger	stackDepth;
	NSString*	type;
	NSString*	ns;
	NSString*	function;
	NSString*	symbol;
	
	NSInteger	logLineNumber; 
	NSString*	logLine;

}


@property (readwrite,assign) NSInteger	threadId;
@property (readwrite,assign) SInt64		time;
@property (readwrite,assign) NSString*	type;
@property (readwrite,assign) NSString*	ns;
@property (readwrite,assign) NSString*	function;
@property (readwrite,retain) NSString*	file;
@property (readwrite,assign) NSInteger	stackDepth;

@property (readwrite,assign) NSString*	symbol;

@property (readwrite,retain) NSString*	logLine;
@property (readwrite,assign) NSInteger	logLineNumber;

- (BOOL) isFunctionBegin;

@end
