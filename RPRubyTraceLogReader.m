//
//  RPRubyTraceLogReader.m
//  Rampler
//
//  Created by Jérôme Lebel on 20/10/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import "RPRubyTraceLogReader.h"
#import "RPCallTree.h"

@interface RPRubyTraceLogReader ()
@property(nonatomic, retain)NSMutableArray* stacks;
@property(nonatomic, retain)NSString* version;
@property(nonatomic, retain)NSURL* url;
@property(nonatomic, assign)double interval;
@end


@implementation RPRubyTraceLogReader

@synthesize logLineNumber;
@synthesize eof;
@synthesize currentLine;
@synthesize data;
@synthesize stacks;
@synthesize infoDescription;
@synthesize version;
@synthesize interval;
@synthesize url;

- (id) initWithData:(NSData*)d
{
	self = [super init]; 
	self.data = d;

	self.stacks = [[[NSMutableArray alloc] init] autorelease];
    self.infoDescription = [[[NSMutableString alloc] init]	autorelease];
	[self readData];
	
	return self;
}

- (void)dealloc
{
	self.stacks = nil;
    self.infoDescription = nil;
	self.version = nil;
	self.url = nil;
	[super dealloc];
}

- (void) readData
{
	NSInteger currentPos = 0;
	NSInteger eolPos = currentPos;
	NSMutableArray *lines;
    BOOL stillInfo = YES;
	NSInteger infoLineCount = 0;
	NSInteger stackLineCount = 0;
	
	lines = [[NSMutableArray alloc] init];
	do {
		eolPos = currentPos;
		const UInt8* bytes = [data bytes];
		
		while ((eolPos < [data length]) && (bytes[eolPos] != '\n')) ++eolPos;

		logLineNumber++; 
		
		NSString* line = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(currentPos, eolPos - currentPos)] encoding:NSUTF8StringEncoding];
        if (stillInfo) {
			infoLineCount++;
			if (logLineNumber == 1) {
				self.version = line;
			} else if (logLineNumber == 2) {
				self.url = [NSURL URLWithString:line];
			} else if (logLineNumber == 3) {
				self.interval = [line doubleValue] / 1000000.0;
			} else if ([[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@"--"]) {
            	stillInfo = NO;
            } else {
            	[infoDescription appendString:line];
            }
        } else {
            RPLogLine* parsedLine  = [self parseLine:line];
			
			stackLineCount++;
            if (parsedLine) {
                parsedLine.stackDepth = [lines count];
                [lines addObject:parsedLine];
            } else if ([lines count] > 0) {
                [self.stacks addObject:lines];
                [lines release];
                lines = [[NSMutableArray alloc] init];
            }
        }
		[line release];
		
		currentPos = eolPos + 1;
		
	} while (eolPos < [data length]);
	NSLog(@"total %d info %d lines %d", logLineNumber, infoLineCount, stackLineCount);
	NSLog(@"stacks %d", [self.stacks count]);
	[lines release];
}


- (RPLogLine*) parseLine:(NSString*)line
{
	if (line == nil || [line length] < 5) return NULL;
	
	NSArray* components = [line componentsSeparatedByString:@"\t"];
	if ([components count] < 7) {
		if ([components count] > 0) {
			NSLog(@"problem with lines %@", line);
		}
		return NULL;
	}
	
	RPLogLine* parsedLine = [[RPLogLine alloc] init];
	
	parsedLine.logLineNumber = logLineNumber;
	parsedLine.logLine = line;
	parsedLine.threadId = [[components objectAtIndex:0] integerValue];
	parsedLine.time = [[components objectAtIndex:1] integerValue];
	parsedLine.fileName = [components objectAtIndex:2];
	parsedLine.fileLine = [[components objectAtIndex:3] integerValue];
	parsedLine.file = [NSString stringWithFormat:@"%@:%d", parsedLine.fileName, parsedLine.fileLine];
	parsedLine.type = [components objectAtIndex:4];
	parsedLine.ns = @"";
	parsedLine.function = [components objectAtIndex:6];
	parsedLine.symbol = [NSString stringWithFormat:@"%@(%@)", parsedLine.function, [components objectAtIndex:5]];
	if ([components objectAtIndex:5]) {
		parsedLine.symbolId = [components objectAtIndex:5];
	} else {
		parsedLine.symbolId = [NSString stringWithFormat:@"%@:%d", parsedLine.fileName, parsedLine.fileLine];
	}
	
	return [parsedLine autorelease];
}

- (RPCallTree*)callTree
{
	RPCallTree* callTree;
	
	callTree = [[RPCallTree alloc] init];
	callTree.thread = self.currentLine.threadId;
	for (NSArray *lines in stacks) {
		RPCallTree *current;
		RPLogLine *line;
		NSInteger sampleCount;
		
		sampleCount = [[lines objectAtIndex:0] time] / self.interval / 1000000.0;
		callTree.sampleCount += sampleCount;
		current = callTree;
		for (line in lines) {
			current = [current subTreeForSymbolId:line.symbolId];
			if (current.symbol !=  nil && ![current.symbol isEqualToString:line.symbol]) {
				NSLog(@"++ %@ ++ %@ ++ %@", current.symbol, line.symbol, line.symbolId);
			}
			current.sampleCount += sampleCount;
			current.thread = line.threadId;
			current.stackDepth = line.stackDepth;
			current.startLine = line.logLineNumber;
			current.symbolId = line.symbolId;
			current.symbol = line.symbol;
			current.file = line.file;
			current.totalTime += line.time;
			[current addCallDetailsForFile:line.file time:line.time];
		}
	}
	[callTree freeze];
	return callTree;
}

@end
