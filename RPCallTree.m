//
//  RPCallTree.m
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import "RPCallTree.h"


@interface RPCallTree()
@property (readwrite,  weak)	RPCallTree* parent;
@property (readwrite,  weak)	RPCallTree* root;
@end


@implementation RPCallTree


+ (NSArray*) defaultSortDescriptor
{
	static NSArray* _defaultSortDescriptor = nil; 
	if (_defaultSortDescriptor == nil) {
		_defaultSortDescriptor = @[[NSSortDescriptor sortDescriptorWithKey:@"totalTime" ascending:NO]];
	}
	
	return _defaultSortDescriptor;
}

- (id)init
{
	self = [super init];
	if (self) {
		self.callDetails = [[NSMutableDictionary alloc] init];
	}
	return self;
}


- (RPCallTree*) subTreeForSymbolId:(NSString*)symId
{
	if (self.subTrees == nil) {
		self.subTrees = [NSMutableDictionary dictionary];
	}
	
	RPCallTree* subTree = (self.subTrees)[symId];
	if (subTree == nil) {
		//NSLog(@"Creating subtree for symbol %@", symId);
		subTree = [[RPCallTree alloc] init];

		subTree.parent = self;
		subTree.symbolId = symId;

		(self.subTrees)[symId] = subTree;
	} else {
		//NSLog(@"Reusing subtree");
	}
	
	return subTree;
}

- (void)freeze
{
	double subTreesTime = 0; 
	NSInteger sampleCountTest = 0;
	
	for (RPCallTree* subtree in [self.subTrees objectEnumerator])
		subTreesTime += subtree.totalTime;

	// root object needs special treatment. 
	if (self.parent == nil) {
		self.root = nil;
		self.totalTime = subTreesTime;
		self.selfTime = 0;
		//NSLog(@"total root time : %ld", self.totalTime);
	} else {
		self.root = self.parent.root ? self.parent.root : self.parent;
		self.selfTime = self.totalTime - subTreesTime;
		if (self.selfTime < 0) {
			self.selfTime = 0;
		}
	}
	
	self.children = [[self.subTrees allValues] sortedArrayUsingDescriptors:[self.class defaultSortDescriptor]];
	self.stackTraceCount = 0;
	for (RPCallTree* child in self.children) {
		[child freeze];
		self.stackTraceCount += child.stackTraceCount;
		sampleCountTest += child.sampleCount;
	}
	if (self.stackTraceCount == 0) {
		self.stackTraceCount = 1;
	}
	if (self.sampleCount == 0 && self.parent == nil) {
		self.sampleCount = sampleCountTest;
	} else if (self.sampleCount < sampleCountTest) {
		NSLog(@"self.sampleCount %ld sampleCountTest %ld", self.sampleCount, sampleCountTest);
	}
}

- (void)addCallDetailsForFile:(NSString *)fileNameNumber time:(double)valueToAdd
{
	double time;
	NSNumber *number;
	
	time = [self.callDetails[fileNameNumber] doubleValue] + valueToAdd;
	number = @(time);
	if (fileNameNumber) self.callDetails[fileNameNumber] = number;
}

- (void)addCallTreeInfo:(RPCallTree *)callTreeToAdd bottomUp:(BOOL)bottomUp time:(float)time
{
	NSAssert([self.symbolId isEqualToString:callTreeToAdd.symbolId], @"symbol id are not identical %@ %@", self.symbolId, callTreeToAdd.symbolId);
	self.sampleCount += callTreeToAdd.sampleCount;
	if (!self.symbol) {
		self.symbol = callTreeToAdd.symbol;
	}
	if (!self.file) {
		self.file = callTreeToAdd.file;
	}
    if (bottomUp) {
		self.totalTime += time;
    } else {
		self.totalTime += callTreeToAdd.totalTime;
    }
	if (self.startLine == 0) {
		self.startLine = callTreeToAdd.startLine;
	}
	for (NSString *fileNameNumber in [callTreeToAdd.callDetails allKeys]) {
		[self addCallDetailsForFile:fileNameNumber time:[(callTreeToAdd.callDetails)[fileNameNumber] doubleValue]];
	}
    if (bottomUp) {
    	if (callTreeToAdd.parent.symbolId) {
			[[self subTreeForSymbolId:callTreeToAdd.parent.symbolId] addCallTreeInfo:callTreeToAdd.parent bottomUp:bottomUp time:time];
        }
    } else {
		for (RPCallTree *child in callTreeToAdd.children) {
			[[self subTreeForSymbolId:child.symbolId] addCallTreeInfo:child bottomUp:bottomUp time:time];
		}
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
		RPCallTree *current = subTreeToTest[0];
		
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
	return result;
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
		[mergedCallTree addCallTreeInfo:current bottomUp:NO time:0];
	}
	[result freeze];
	return result;
}

- (RPCallTree *)bottomUpCallTreeForSymbolId:(NSString *)functionSymbolId
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
		[mergedCallTree addCallTreeInfo:current bottomUp:YES time:current.totalTime];
	}
	[result freeze];
	return result;
}

- (void) _exportToBuffer:(NSMutableString*)buffer indendation:(int)indentation
{
    [buffer appendString:@"    "];
    for (int i = 0; i < indentation; i++) {
        [buffer appendString:@" "];
    }
    NSString* symb = self.symbol;
    if (nil == symb) {
        symb = @"Unknown";
    }
    if (self.ns) {
        symb = [NSString stringWithFormat:@"%@:%@", self.ns, symb];
    }
    [buffer appendFormat:@"%ld %@\n", self.sampleCount, symb];
    for (RPCallTree* child in self.children) {
        [child _exportToBuffer:buffer indendation:indentation+1];
    }
}


#pragma mark -
#pragma mark Simple Tree Manipulation functions 

- (RPCallTree *)copyWithParent:(RPCallTree*)parent withRoot:(RPCallTree*)root deep:(BOOL)deepCopy
{
    RPCallTree* treeCopy = [[RPCallTree alloc] init];
    treeCopy.symbolId = self.symbolId;
    treeCopy.symbol = self.symbol;
    treeCopy.file = self.file;
    treeCopy.thread = self.thread;
    treeCopy.stackDepth = self.stackDepth;
    treeCopy.totalTime = self.totalTime;
    treeCopy.selfTime = self.selfTime;
    treeCopy.startLine = self.startLine;
    treeCopy.sampleCount = self.sampleCount;
    treeCopy.blockedTicks = self.blockedTicks;
    
    treeCopy.parent = parent;
    treeCopy.root = root;
    
    if (deepCopy) {
        if (self.subTrees) {
            treeCopy.subTrees = [[NSMutableDictionary alloc] initWithCapacity:self.subTrees.count];
            for (NSString* symbolId in self.subTrees) {
                treeCopy.subTrees[symbolId] = [self.subTrees[symbolId] copyWithParent:self withRoot:self.root deep:YES];
            }
        }
    } else {
        treeCopy.subTrees = self.subTrees;
    }
    
    return treeCopy;
}


#pragma mark -
#pragma mark Advanced Tree Manipulation functions

- (RPCallTree *)callTreeByFlattenRecursionInSubTree:(RPCallTree*)subtree
{
    RPCallTree* result = [self copyWithParent:nil withRoot:nil deep:YES];
    [result freeze];
    return result;
}

@end
