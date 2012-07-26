//
//  RPRubyTraceLogReader.m
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import "RPRubyTraceLogReader.h"
#import "RPCallTree.h"

@interface RPRubyTraceLogReader ()
@property(nonatomic) NSMutableArray* stacks;
@property(nonatomic) NSString* version;
@property(nonatomic) NSURL* url;
@property(nonatomic, assign)double interval;
@property (nonatomic) NSString *beginningInfoDescription;
@property (nonatomic) NSString *endingInfoDescription;
@property (nonatomic) NSDate* startDate;
@property (nonatomic, assign) double duration;
@property (nonatomic, assign) NSUInteger sampleCount;
@end


@implementation RPRubyTraceLogReader

@synthesize currentLine;
@synthesize beginningInfoDescription;
@synthesize endingInfoDescription;


- (id) initWithData:(NSData*)d
{
	self = [super init]; 
	self.data = d;

	self.stacks = [[NSMutableArray alloc] init];
    self.beginningInfoDescription = [[NSMutableString alloc] init];
	self.endingInfoDescription = [[NSMutableString alloc] init];
	[self readData];
	
	return self;
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
		const UInt8* bytes = [self.data bytes];
		
		while ((eolPos < [self.data length]) && (bytes[eolPos] != '\n')) ++eolPos;

		self.logLineNumber++; 
		
		NSString* line = [[NSString alloc] initWithData:[self.data subdataWithRange:NSMakeRange(currentPos, eolPos - currentPos)] encoding:NSUTF8StringEncoding];
        if (beginningInfo) {
			infoLineCount++;
			switch (self.logLineNumber) {
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
                lines = [[NSMutableArray alloc] init];
            }
        }
		
		currentPos = eolPos + 1;
		
	} while (eolPos < [self.data length]);
	NSLog(@"total %ld info %ld lines %ld", self.logLineNumber, infoLineCount, stackLineCount);
	NSLog(@"stacks %lu", [self.stacks count]);
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
	
	parsedLine.logLineNumber = self.logLineNumber;
	parsedLine.logLine = line;
	parsedLine.threadId = [components[0] integerValue];
	parsedLine.tickCount = [components[1] integerValue];
	parsedLine.fileName = components[2];
	parsedLine.fileLine = [components[3] integerValue];
	parsedLine.file = [NSString stringWithFormat:@"%@:%d", parsedLine.fileName, parsedLine.fileLine];
	parsedLine.type = components[4];
	parsedLine.function = components[6];
	parsedLine.symbol = [NSString stringWithFormat:@"%@", parsedLine.function];
	parsedLine.duration = [components[8] doubleValue];
	if (components[5]) {
		parsedLine.symbolId = components[5];
	} else {
		parsedLine.symbolId = [NSString stringWithFormat:@"%@:%d", parsedLine.fileName, parsedLine.fileLine];
	}
	if ([components count] > 9) {
		parsedLine.ns = components[9];
	}
	
	return parsedLine;
}

- (RPCallTree*)callTree
{
	RPCallTree* callTree;
	int count = 0;
	
	callTree = [[RPCallTree alloc] init];
	callTree.thread = self.currentLine.threadId;
	for (NSArray *lines in self.stacks) {
		RPCallTree *current;
		RPLogLine *line;
		NSInteger lineSampleCount;
		
		lineSampleCount = [lines[0] tickCount];
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
			current.blockedTicks += lineSampleCount - 1;
			[current addCallDetailsForFile:line.file time:line.duration];
		}
	}
	[callTree freeze];
	NSLog(@"count %d", count);
	return callTree;
}

@end
