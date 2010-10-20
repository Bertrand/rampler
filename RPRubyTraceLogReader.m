//
//  RPRubyTraceLogReader.m
//  Rampler
//
//  Created by Jérôme Lebel on 20/10/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import "RPRubyTraceLogReader.h"


@implementation RPRubyTraceLogReader

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
		if (!parsedLine) NSLog(@"Unable to parse log line %d. Ignoring it. (\"%@\")", logLineNumber, line);
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
	parsedLine.symbol = nil; // computed lazily
	
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

@end
