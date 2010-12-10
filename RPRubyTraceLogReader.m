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
@property (nonatomic, retain) NSString *beginningInfoDescription;
@property (nonatomic, retain) NSString *endingInfoDescription;
@property (nonatomic, retain) NSDate* startDate;
@property (nonatomic, assign) double duration;
@property (nonatomic, assign) NSUInteger sampleCount;
@end


@implementation RPRubyTraceLogReader

@synthesize logLineNumber;
@synthesize eof;
@synthesize currentLine;
@synthesize data;
@synthesize stacks;
@synthesize beginningInfoDescription;
@synthesize endingInfoDescription;
@synthesize version;
@synthesize interval;
@synthesize url;
@synthesize startDate;
@synthesize duration;
@synthesize sampleCount;

- (id) initWithData:(NSData*)d
{
	self = [super init]; 
	self.data = d;

	self.stacks = [[[NSMutableArray alloc] init] autorelease];
    self.beginningInfoDescription = [[[NSMutableString alloc] init]	autorelease];
	self.endingInfoDescription = [[[NSMutableString alloc] init] autorelease];
	[self readData];
	
	return self;
}

- (void)dealloc
{
	self.stacks = nil;
    self.beginningInfoDescription = nil;
	self.endingInfoDescription = nil;
	self.version = nil;
	self.url = nil;
	[super dealloc];
}

- (void) readData
{
	NSInteger currentPos = 0;
	NSInteger eolPos = currentPos;
	NSMutableArray *lines;
    BOOL beginningInfo = YES;
	BOOL endingInfo = NO;
	NSInteger endingInfoCount = 0;
	NSInteger infoLineCount = 0;
	NSInteger stackLineCount = 0;
	
	lines = [[NSMutableArray alloc] init];
	do {
		eolPos = currentPos;
		const UInt8* bytes = [data bytes];
		
		while ((eolPos < [data length]) && (bytes[eolPos] != '\n')) ++eolPos;

		logLineNumber++; 
		
		NSString* line = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(currentPos, eolPos - currentPos)] encoding:NSUTF8StringEncoding];
        if (beginningInfo) {
			infoLineCount++;
			switch (logLineNumber) {
				case 1:
					self.version = line;
					break;
				case 2:
					self.url = [NSURL URLWithString:line];
				case 3:
					self.interval = [line doubleValue] / 1000000.0;
					break;
				case 4:
					self.startDate = [NSDate dateWithString:line];
				default:
					if ([[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@"--"]) {
		            	beginningInfo = NO;
        		    } else {
            			[beginningInfoDescription appendString:line];
		            }
					break;
			}
		} else if ([[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@"--"] || endingInfo) {
			endingInfo = YES;
			
			switch (endingInfoCount) {
				case 1:
					self.duration = [line doubleValue];
					break;
				case 3:
					self.sampleCount = [line integerValue];
					break;
				default:
					[endingInfoDescription appendString:line];
					break;
			}
			endingInfoCount++;
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
	parsedLine.tickCount = [[components objectAtIndex:1] integerValue];
	parsedLine.fileName = [components objectAtIndex:2];
	parsedLine.fileLine = [[components objectAtIndex:3] integerValue];
	parsedLine.file = [NSString stringWithFormat:@"%@:%d", parsedLine.fileName, parsedLine.fileLine];
	parsedLine.type = [components objectAtIndex:4];
	parsedLine.function = [components objectAtIndex:6];
	parsedLine.symbol = [NSString stringWithFormat:@"%@(%@)", parsedLine.function, [components objectAtIndex:5]];
	parsedLine.duration = [[components objectAtIndex:8] doubleValue];
	if ([components objectAtIndex:5]) {
		parsedLine.symbolId = [components objectAtIndex:5];
	} else {
		parsedLine.symbolId = [NSString stringWithFormat:@"%@:%d", parsedLine.fileName, parsedLine.fileLine];
	}
	if ([components count] > 9) {
		parsedLine.ns = [components objectAtIndex:9];
	}
	
	return [parsedLine autorelease];
}

- (RPCallTree*)callTree
{
	RPCallTree* callTree;
	int count = 0;
	
	callTree = [[RPCallTree alloc] init];
	callTree.thread = self.currentLine.threadId;
	for (NSArray *lines in stacks) {
		RPCallTree *current;
		RPLogLine *line;
		NSInteger lineSampleCount;
		
		lineSampleCount = [[lines objectAtIndex:0] tickCount];
		count += lineSampleCount;
		callTree.sampleCount += lineSampleCount;
		current = callTree;
		for (line in lines) {
			current = [current subTreeForSymbolId:line.symbolId];
			if (current.symbol !=  nil && ![current.symbol isEqualToString:line.symbol]) {
				NSLog(@"++ %@ ++ %@ ++ %@", current.symbol, line.symbol, line.symbolId);
			}
			current.sampleCount += lineSampleCount;
			current.thread = line.threadId;
			current.stackDepth = line.stackDepth;
			current.startLine = line.logLineNumber;
			current.symbolId = line.symbolId;
			current.symbol = line.symbol;
			current.file = line.file;
			current.ns = line.ns;
			current.totalTime += self.duration * lineSampleCount / self.sampleCount;
			if (current.maxTickPerStack < lineSampleCount) {
				current.maxTickPerStack = lineSampleCount;
			}
			[current addCallDetailsForFile:line.file time:line.duration];
		}
	}
	[callTree freeze];
	NSLog(@"count %d", count);
	return callTree;
}

@end
