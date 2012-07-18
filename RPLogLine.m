//
//  RPLogLine.m
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import "RPLogLine.h"


@implementation RPLogLine


@synthesize threadId;
@synthesize time;
@synthesize type;
@synthesize ns;
@synthesize function;
@synthesize file;
@synthesize fileName;
@synthesize fileLine;
@synthesize stackDepth;
@synthesize logLineNumber;
@synthesize logLine;
@synthesize duration;
@synthesize tickCount;

@synthesize symbol;
@synthesize symbolId;



- (NSString*) symbol
{
	if (symbol == nil) {
		self.symbol = [NSString stringWithFormat:@"%@::%@", self.ns, self.function];
	}
	return symbol;
}


- (BOOL) isFunctionBegin
{
	return [self.type isEqual:@"I"];
}


@end
