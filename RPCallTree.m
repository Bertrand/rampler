//
//  RPCallTree.m
//  Rampler
//
//  Created by Guiheneuf Bertrand on 9/29/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import "RPCallTree.h"
#import "RPDTraceLogReader.h"

@implementation RPCallTree

@synthesize symbol;
@synthesize symbolId;
@synthesize subTrees;
@synthesize totalTime;
@synthesize selfTime;
@synthesize file;
@synthesize parent;
@synthesize children;
@synthesize thread;
@synthesize stackDepth;
@synthesize startLine;
@synthesize callCount;
@synthesize callDetails;



+ (NSArray*) defaultSortDescriptor
{
	static NSArray* _defaultSortDescriptor = nil; 
	if (_defaultSortDescriptor == nil) {
		_defaultSortDescriptor = [[NSArray alloc] initWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"totalTime" ascending:NO], nil];
	}
	
	return _defaultSortDescriptor;
}

- (id)init
{
	self = [super init];
	if (self) {
		callDetails = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[callDetails release];
	[super dealloc];
}

- (RPCallTree*) subTreeForSymbolId:(NSString*)symId
{
	if (self.subTrees == nil) {
		self.subTrees = [NSMutableDictionary dictionary];
	}
	
	RPCallTree* subTree = [self.subTrees objectForKey:symId];
	if (subTree == nil) {
		//NSLog(@"Creating subtree for symbol %@", symId);
		subTree = [[RPCallTree alloc] init];

		subTree->parent = self;
		subTree.symbolId = symId;


		[self.subTrees setObject:subTree forKey:symId];
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

- (void)addCallDetailsForFile:(NSString *)fileNameNumber time:(double)valueToAdd
{
	double time;
	NSNumber *number;
	
	time = [[callDetails objectForKey:fileNameNumber] doubleValue] + valueToAdd;
	number = [[NSNumber alloc] initWithDouble:time];
	[callDetails setObject:number forKey:fileNameNumber];
	[number release];
}

- (void)addCallTreeInfo:(RPCallTree *)callTreeToAdd
{
	NSAssert([self.symbolId isEqualToString:callTreeToAdd.symbolId], @"symbol id are not identical %@ %@", self.symbolId, callTreeToAdd.symbolId);
	self.callCount += callTreeToAdd.callCount;
	if (!self.symbol) {
		self.symbol = callTreeToAdd.symbol;
	}
	if (!self.file) {
		self.file = callTreeToAdd.file;
	}
	self.totalTime += callTreeToAdd.totalTime;
	if (self.startLine == 0) {
		self.startLine = callTreeToAdd.startLine;
	}
	for (NSString *fileNameNumber in [callTreeToAdd.callDetails allKeys]) {
		[self addCallDetailsForFile:fileNameNumber time:[[callTreeToAdd.callDetails objectForKey:fileNameNumber] doubleValue]];
	}
	for (RPCallTree *child in callTreeToAdd.children) {
		[[self subTreeForSymbolId:child.symbolId] addCallTreeInfo:child];
	}
}

- (NSArray *)allCallTreeForSymbolId:(NSString *)searchSymbolId withRecursiveCall:(BOOL)recursive
{
	NSMutableArray *subTreeToTest;
	NSMutableArray *result;
	
	subTreeToTest = [[NSMutableArray alloc] init];
	result = [[NSMutableArray alloc] init];
	[subTreeToTest addObjectsFromArray:[self.subTrees allValues]];
	while ([subTreeToTest count] > 0) {
		RPCallTree *current = [subTreeToTest objectAtIndex:0];
		
		for (RPCallTree *newCallTree in [current.subTrees allValues]) {
			BOOL found = NO;
			
			if ([newCallTree.symbolId isEqualToString:searchSymbolId]) {
				[result addObject:newCallTree];
				found = YES;
			}
			if (recursive || !found) {
				[subTreeToTest addObject:newCallTree];
			}
		}
		[subTreeToTest removeObjectAtIndex:0];
	}
	[subTreeToTest release];
	return [result autorelease];
}

- (RPCallTree *)topDownCallTreeForSymbolId:(NSString *)functionSymbolId
{
	RPCallTree *result;
	NSArray *allCallTrees;
	
	result = [[RPCallTree alloc] init];
	result.symbolId = functionSymbolId;
	result.file = @"-";
	allCallTrees = [self allCallTreeForSymbolId:functionSymbolId withRecursiveCall:NO];
	for (RPCallTree *current in allCallTrees) {
		RPCallTree *mergedCallTree;
		
		mergedCallTree = [result subTreeForSymbolId:current.symbolId];
		[mergedCallTree addCallTreeInfo:current];
	}
	[result freeze];
	return [result autorelease];
}

@end
