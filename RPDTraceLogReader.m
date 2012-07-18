//
//  RPDTraceLogReader.m
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import "RPDTraceLogReader.h"
#import "RPLogLine.h"

#import "RPCallTree.h"

@implementation RPDTraceLogReader

@synthesize logLineNumber;
@synthesize eof;
@synthesize currentLine;
@synthesize data;
@synthesize lines;

- (id) initWithData:(NSData*)d
{
	self = [super init]; 
	self.data = d;

	self.lines = [NSMutableArray new];
	[self readData];
	
	return self;
}

- (void) readData
{
	NSInteger currentPos = 0;
	NSInteger eolPos = currentPos;

	do {
		eolPos = currentPos;
		const UInt8* bytes = [data bytes];
		while ((eolPos < [data length]) && (bytes[eolPos] != '\n')) ++eolPos;

		logLineNumber++; 
		
		NSString* line = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(currentPos, eolPos - currentPos)] encoding:NSUTF8StringEncoding];
		//NSLog(@"%@", line);
		RPLogLine* parsedLine  = [self parseLine:line]; 
		if (!parsedLine) NSLog(@"Unable to parse log line %ld. Ignoring it. (\"%@\")", logLineNumber, line);
		if (parsedLine) [lines addObject:parsedLine];
		[line release];
		
		currentPos = eolPos + 1;
		
	} while (eolPos < [data length]);
	
	// now sort the lines so that they have increasing time
	[lines sortUsingComparator: (NSComparator)^(RPLogLine* line1, RPLogLine* line2) { 
		 if (line1.time > line2.time) {
			  return (NSComparisonResult)NSOrderedDescending;
		 }
		 if (line1.time < line2.time) {
			  return (NSComparisonResult)NSOrderedAscending;
		 }
		 return (NSComparisonResult)NSOrderedSame;
	}];
	
}


- (RPLogLine*) parseLine:(NSString*)line
{
	if (line == nil || [line length] < 5) return NULL;
	
	NSArray* components = [line componentsSeparatedByString:@"\t"];
	if ([components count] != 7) return NULL; 
	
	RPLogLine* parsedLine = [[RPLogLine alloc] init];
	
	parsedLine.logLineNumber = logLineNumber;
	parsedLine.logLine = line;
	parsedLine.threadId = [[components objectAtIndex:0] integerValue];
	parsedLine.time = [[components objectAtIndex:1] integerValue];
	//NSLog(@"time : %ld", parsedLine.time);
	parsedLine.file = [components objectAtIndex:2];
	parsedLine.stackDepth = [[components objectAtIndex:3] integerValue];
	parsedLine.type = [components objectAtIndex:4];
	parsedLine.ns = [components objectAtIndex:5];
	parsedLine.function = [components objectAtIndex:6];
	parsedLine.symbol = [NSString stringWithFormat:@"%@::%@", parsedLine.ns, parsedLine.function];
	parsedLine.symbolId = [NSString stringWithFormat:@"%@::%@", parsedLine.ns, parsedLine.function];
	
	return [parsedLine autorelease];
}

- (BOOL) moveNextLine
{
	if (self.eof) return NO;
	currentLine = [lines objectAtIndex:currentLineNumber];
	currentLineNumber++;
	return YES;
}

- (BOOL) eof
{
	return (currentLineNumber >= [lines count]);
}

- (void) feedCallTree:(RPCallTree*)callTree
{
	
	SInt64 startTime = self.currentLine.time;
	// NSLog(@"start time : %ld", startTime);
	callTree.thread = self.currentLine.threadId;
	callTree.stackDepth = self.currentLine.stackDepth;
	callTree.startLine = self.currentLine.logLineNumber;
	callTree.symbol = self.currentLine.symbol;
	callTree.sampleCount++;
	
	[self moveNextLine];

	BOOL shouldEatCurrentLine;

	do {
		shouldEatCurrentLine = YES;
		
		if (self.eof) {
			break;
			// [NSException raise:@"InvalidLogFile" format:@"the logFile ended too early"];
		}
		
		if ([self.currentLine isFunctionBegin]) {
			[self feedCallTree:[callTree subTreeForSymbolId:self.currentLine.symbolId]];
			
			continue;	
		} 
		
		if (NO == [self.currentLine.symbol isEqual:callTree.symbol]) {
			NSLog(@"oops, returning out of current symbol (%@) with symbol %@ (out line %ld, begin line:%ld)", callTree.symbol, self.currentLine.symbol, self.currentLine.logLineNumber, callTree.startLine);
			shouldEatCurrentLine = NO;
		}
		
		if (callTree.parent) break; // found a function output, end processing at this level.

		
		// No parent, we're at root level. We're going to ignore the line, but let's whine a little bit. 
		NSLog(@"found a function-out log at root level, ignoring it (line %ld: \"%@\")", self.currentLine.logLineNumber, self.currentLine.logLine);
		[self moveNextLine];
		
	} while(!self.eof);
	
	// processing ended at this level. Compute total time
	SInt64 endTime = self.currentLine.time; 
	callTree.totalTime += endTime - startTime;
	// NSLog(@"start time : %ld, end time : %ld, delta : %ld, totalTime : %ld", startTime, endTime, endTime - startTime, callTree.totalTime);
	
	// before moving up, eat current line. 
	if (shouldEatCurrentLine) [self moveNextLine];	
}

- (RPCallTree*)callTree
{
	RPCallTree *root;
	root = [[RPCallTree alloc] init];
	[self feedCallTree:root];
	[root freeze];
	return [root autorelease];
}

- (NSString *)version
{
	NSAssert(NO, @"not implemented");
	return nil;
}

- (double)interval
{
	NSAssert(NO, @"not implemented");
	return 0;
}

- (NSURL *)url
{
	NSAssert(NO, @"not implemented");
	return nil;
}

- (NSDate *)startDate
{
	NSAssert(NO, @"not implemented");
	return nil;
}

- (double)duration
{
	NSAssert(NO, @"not implemented");
	return 0;
}

@end
