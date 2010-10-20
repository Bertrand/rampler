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



+ (NSArray*) defaultSortDescriptor
{
	static NSArray* _defaultSortDescriptor = nil; 
	if (_defaultSortDescriptor == nil) {
		_defaultSortDescriptor = [[NSArray alloc] initWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"totalTime" ascending:NO], nil];
	}
	
	return _defaultSortDescriptor;
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

@end
