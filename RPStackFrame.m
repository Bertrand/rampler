//
//  RPLogLine.m
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import "RPStackFrame.h"


@implementation RPStackFrame

@synthesize symbol;


- (NSString*) symbol
{
	if (symbol == nil) {
		symbol = [NSString stringWithFormat:@"%@::%@", self.ns, self.function];
	}
	return symbol;
}


- (BOOL) isFunctionBegin
{
	return [self.type isEqual:@"I"];
}


@end
