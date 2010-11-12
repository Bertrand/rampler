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
@property(nonatomic, retain)NSMutableArray *stacks;
@end


@implementation RPRubyTraceLogReader

@synthesize logLineNumber;
@synthesize eof;
@synthesize currentLine;
@synthesize data;
@synthesize stacks;
@synthesize infoDescription;

- (id) initWithData:(NSData*)d
{
	self = [super init]; 
	self.data = d;

	self.stacks = [[[NSMutableArray alloc] init] autorelease];
    self.infoDescription = [[[NSMutableString alloc] init]	autorelease];
	[self readData];
	
	return self;
}

- (void) readData
{
	NSInteger currentPos = 0;
	NSInteger eolPos = currentPos;
	NSMutableArray *lines;
    BOOL stillInfo = YES;
	
	lines = [[NSMutableArray alloc] init];
	do {
		eolPos = currentPos;
		const UInt8* bytes = [data bytes];
		
		while ((eolPos < [data length]) && (bytes[eolPos] != '\n')) ++eolPos;

		logLineNumber++; 
		
		NSString* line = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(currentPos, eolPos - currentPos)] encoding:NSUTF8StringEncoding];
        if (stillInfo) {
        	if ([[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@"--"]) {
            	stillInfo = NO;
            } else {
            	[infoDescription appendString:line];
            }
        } else {
            //NSLog(@"%@", line);
            RPLogLine* parsedLine  = [self parseLine:line]; 
            if (parsedLine) {
                parsedLine.time = 1;
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
	[lines release];
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
		
		current = callTree;
		for (line in lines) {
			current = [current subTreeForSymbolId:line.symbolId];
			if (current.symbol !=  nil && ![current.symbol isEqualToString:line.symbol]) {
				NSLog(@"++ %@ ++ %@ ++ %@", current.symbol, line.symbol, line.symbolId);
			}
			current.callCount++;
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
