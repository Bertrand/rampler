//
//  RPCallTree.m
//  Rampler
//
//  Created by Guiheneuf Bertrand on 9/29/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import "RPCallTree.h"
#import "RPLogReader.h"

@implementation RPCallTree

@synthesize symbol;
@synthesize subTrees;
@synthesize totalTime;
@synthesize selfTime;
@synthesize parent;
@synthesize children;
@synthesize thread;
@synthesize stackDepth;
@synthesize startLine;
@synthesize callCount;



+ (NSArray*) defaultSortDescriptor
{
	static NSArray* _defaultSortDescriptor = nil; 
	if (_defaultSortDescriptor == nil) {
		_defaultSortDescriptor = [[NSArray alloc] initWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"totalTime" ascending:NO], nil];
	}
	
	return _defaultSortDescriptor;
}

- (void) feedFromLogReader:(RPLogReader*)reader
{
	
	SInt64 startTime = reader.currentLine.time;
	// NSLog(@"start time : %ld", startTime);
	self.thread = reader.currentLine.threadId;
	self.stackDepth = reader.currentLine.stackDepth;
	self.startLine = reader.currentLine.logLineNumber;
	self.callCount++;
	
	[reader moveNextLine];

	BOOL shouldEatCurrentLine;

	do {
		shouldEatCurrentLine = YES;
		
		if (reader.eof) {
			break;
			// [NSException raise:@"InvalidLogFile" format:@"the logFile ended too early"];
		}
		
		if ([reader.currentLine isFunctionBegin]) {
			[[self subTreeForSymbol:reader.currentLine.symbol] feedFromLogReader:reader];
			
			continue;	
		} 
		
		if (NO == [reader.currentLine.symbol isEqual:self.symbol]) {
			NSLog(@"oops, returning out of current symbol (%@) with symbol %@ (out line %d, begin line:%d)", self.symbol, reader.currentLine.symbol, reader.currentLine.logLineNumber, self.startLine);
			shouldEatCurrentLine = NO;
		}
		
		if (parent) break; // found a function output, end processing at this level.

		
		// No parent, we're at root level. We're going to ignore the line, but let's whine a little bit. 
		NSLog(@"found a function-out log at root level, ignoring it (line %d: \"%@\")", reader.currentLine.logLineNumber, reader.currentLine.logLine);
		[reader moveNextLine];
		
	} while(!reader.eof);
	
	// processing ended at this level. Compute total time
	SInt64 endTime = reader.currentLine.time; 
	self.totalTime += endTime - startTime;
	// NSLog(@"start time : %ld, end time : %ld, delta : %ld, totalTime : %ld", startTime, endTime, endTime - startTime, self.totalTime);
	
	// before moving up, eat current line. 
	if (shouldEatCurrentLine) [reader moveNextLine];	
}

- (RPCallTree*) subTreeForSymbol:(NSString*)sym
{
	if (self.subTrees == nil) {
		self.subTrees = [NSMutableDictionary dictionary];
	}
	
	RPCallTree* subTree = [self.subTrees objectForKey:sym];
	if (subTree == nil) {
		//NSLog(@"Creating subtree for symbol %@", sym);
		subTree = [[RPCallTree alloc] init];

		subTree->parent = self;
		subTree.symbol = sym;


		[self.subTrees setObject:subTree forKey:sym];
		[subTree release];
	} else {
		//NSLog(@"Reusing subtree");
	}
	
	return subTree;
}



- (void)freeze
{
	SInt64 subTreesTime = 0; 
	for (RPCallTree* subtree in [subTrees objectEnumerator])
		subTreesTime += subtree.totalTime;

	// root object needs special treatment. 
	if (self.parent == nil) {
		root = nil; 
		self.totalTime = subTreesTime;
		self.selfTime = 0;
		//NSLog(@"total root time : %ld", self.totalTime);
	} else {
		root = parent->root ? parent->root : parent;
		selfTime = totalTime - subTreesTime;
	}
	
	self.children = [[self.subTrees allValues] sortedArrayUsingDescriptors:[self.class defaultSortDescriptor]];
	for (RPCallTree* child in self.children) {
		[child freeze];
	}
}

@end
