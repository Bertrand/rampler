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
	return self;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"RPCallTree %@::%@, %ld children", self.ns, self.symbol, self.subTrees ? self.subTrees.count : 0];
}


- (RPCallTree*) subTreeForFunctionId:(NSInteger)functionId classId:(NSInteger)classId create:(BOOL)createIfNeeded
{
	if (self.subTrees == nil) {
		self.subTrees = [NSMutableArray array];
	}
    
    for (RPCallTree* child in self.subTrees) {
        if (child.functionId == functionId && child.classId == classId) return child;
    }
    
    RPCallTree* subTree = nil;
    if (createIfNeeded) {
        subTree = [[RPCallTree alloc] init];
        
		subTree.parent = self;
		subTree.functionId = functionId;
        subTree.classId = classId;
        
        [self.subTrees addObject:subTree];
    }
    
    return subTree;
}

- (RPCallTree*) matchingSubTree:(RPCallTree*)otherSubTree create:(BOOL)createIfNeeded
{
    return [self subTreeForFunctionId:otherSubTree.functionId classId:otherSubTree.classId create:createIfNeeded];
}


- (void)eachChild:(void(^)(RPCallTree* child))block
{
    for (RPCallTree* child in self.subTrees) {
        block(child);
    }
}

- (void)addSubTree:(RPCallTree*)child
{
	if (self.subTrees == nil) {
		self.subTrees = [NSMutableArray array];
	}
    RPCallTree* existingMatchingChild = [self matchingSubTree:child create:NO];
    NSAssert(existingMatchingChild == nil, @"There is already a matching child in this node. Use merge instead");
    [self.subTrees addObject:child];
    child.parent = self;
    child.root = self.root;
}

- (void)removeSubTree:(RPCallTree*)subTree
{
    [self.subTrees removeObject:subTree];
}

- (BOOL)isSameFrameAs:(RPCallTree*)otherCallTree
{
    return [self.symbolId isEqualToString:otherCallTree.symbolId] && [self.ns isEqualToString:otherCallTree.ns];
}

- (NSArray*)snapshotOfCurrentChildren
{
    return [self.subTrees copy];
}

- (void)freeze
{
	double subTreesTime = 0; 
	NSInteger sampleCountTest = 0;
	
	for (RPCallTree* subtree in self.subTrees)
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
	
	self.children = [self.subTrees sortedArrayUsingDescriptors:[self.class defaultSortDescriptor]];
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

    if (bottomUp) {
    	if (callTreeToAdd.parent.symbolId) {
            [[self matchingSubTree:callTreeToAdd.parent create:YES] addCallTreeInfo:callTreeToAdd.parent bottomUp:bottomUp time:time];
        }
    } else {
		for (RPCallTree *child in callTreeToAdd.children) {
			[[self matchingSubTree:child create:YES] addCallTreeInfo:child bottomUp:bottomUp time:time];
		}
    }
}

- (NSArray *)allCallTreeForSymbolId:(NSString *)searchSymbolId withRecursiveCall:(BOOL)recursive
{
	NSMutableArray *subTreeToTest;
	NSMutableArray *result;
	
	subTreeToTest = [[NSMutableArray alloc] init];
	result = [[NSMutableArray alloc] init];
	[subTreeToTest addObjectsFromArray:self.subTrees];
	while ([subTreeToTest count] > 0) {
		RPCallTree *current = subTreeToTest[0];
		
		for (RPCallTree *newCallTree in current.subTrees) {
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
		
		mergedCallTree = [result matchingSubTree:current create:YES];
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
		
		mergedCallTree = [result matchingSubTree:current create:YES];
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

- (RPCallTree *)copyWithParent:(RPCallTree*)parent withRoot:(RPCallTree*)root
{
    RPCallTree* treeCopy = [[RPCallTree alloc] init];
    
    treeCopy.functionId = self.functionId;
    treeCopy.classId = self.classId;
    treeCopy.fileId = self.fileId;

    treeCopy.symbolId = self.symbolId;
    treeCopy.symbol = self.symbol;
    treeCopy.ns = self.ns;
    treeCopy.file = self.file;
    treeCopy.thread = self.thread;
    treeCopy.stackDepth = self.stackDepth;
    treeCopy.totalTime = self.totalTime;
    treeCopy.selfTime = self.selfTime;
    treeCopy.startLine = self.startLine;
    treeCopy.sampleCount = self.sampleCount;
    treeCopy.blockedTicks = self.blockedTicks;
    
    treeCopy.parent = parent;
    if (root == nil) root = treeCopy;
    treeCopy.root = root;
    
    if (self.subTrees) {
        treeCopy.subTrees = [[NSMutableArray alloc] initWithCapacity:self.subTrees.count];
        
        for (RPCallTree *child in self.subTrees) {
            [treeCopy addSubTree:[child copyWithParent:treeCopy withRoot:root]];
        }
    }
    
    return treeCopy;
}


#pragma mark -
#pragma mark Advanced Tree Manipulation functions



- (void) moveToUpperCallTree:(RPCallTree*)upperCallTree
{
    NSAssert(self.parent, @"How can we move to an upper level without having a parent");
    RPCallTree* tree = self; // Since we're ARC-based, avoid accidental release of self when calling removeSubTree
    [tree.parent removeSubTree:self];
    [tree mergeTreeTo:upperCallTree deep:YES];
}

- (void) mergeTreeTo:(RPCallTree*)otherTree deep:(BOOL)deepMerge
{
    otherTree.totalTime += self.totalTime;
    otherTree.selfTime += self.selfTime;
    otherTree.sampleCount += self.sampleCount;
    otherTree.blockedTicks += self.blockedTicks;

    if (deepMerge) {
        [self eachChild:^(RPCallTree* child) {
            RPCallTree* otherChild = [otherTree matchingSubTree:child create:NO];
            if (otherChild) {
                [child mergeTreeTo:otherChild deep:YES];
            } else {
                [otherTree addSubTree:child];
            }
        }];
    }
}

- (void) mergeRecursionsWithMaxRecursionHops:(NSInteger)maxHops
{
    RPCallTree* duplicateAncestor = nil;
    RPCallTree* ancestor = self.parent;
    NSInteger hops = 0;
    
    while (hops<maxHops && ancestor && !duplicateAncestor) {
        
        if (ancestor.file && (ancestor.file.length > 1)) { // do not take into account core library calls.
            if ([self isSameFrameAs:ancestor]) duplicateAncestor = ancestor;
            ++hops;
        }
        ancestor = ancestor.parent;
    }
    
    if (duplicateAncestor) {
        // we found a duplicate call in self ancestor. Merge self to this ancestor and restart down traversal from there
        [self moveToUpperCallTree:duplicateAncestor];
        [duplicateAncestor mergeRecursionsWithMaxRecursionHops:maxHops];
    } else {
        // no duplicate found in self ancestors. We can now proceed with children.
        NSArray* currentChildren = [self snapshotOfCurrentChildren];
        for (RPCallTree* child in currentChildren) {
            [child mergeRecursionsWithMaxRecursionHops:maxHops];
        }
    }
}

- (RPCallTree *)callTreeByFlattenRecursionInSubTree:(RPCallTree*)subtree
{
    RPCallTree* result = [subtree copyWithParent:nil withRoot:nil];
    
    [result mergeRecursionsWithMaxRecursionHops:6];
    
    [result freeze];
    return result;
}

@end
