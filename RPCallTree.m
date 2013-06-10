//
//  RPCallTree.m
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import "RPCallTree.h"
#import "RPSampleSession.h"

@interface RPCallTree()
@property (readwrite,  unsafe_unretained)	RPCallTree* parent;
@property (readwrite,  unsafe_unretained)	RPCallTree* root;
@end



@implementation RPCallTree

@dynamic totalTime;
@dynamic selfTime;

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
    return [NSString stringWithFormat:@"RPCallTree %@::%@, %ld children", self.moduleOrClass, self.method, self.subTrees ? self.subTrees.count : 0];
}

- (RPSampleSession*)session
{
    return (RPSampleSession*)self.root;
}


- (double)totalTime
{
    return self.sampleCount * self.session.sessionDurationPerTick;
}

- (double)selfTime
{
    return self.selfSampleCount * self.session.sessionDurationPerTick;
}

- (RPCallTree*) subTreeForMethodId:(NSInteger)methodId classId:(NSInteger)classId create:(BOOL)createIfNeeded
{
	if (self.subTrees == nil) {
		self.subTrees = [NSMutableArray array];
	}
    
    for (RPCallTree* child in self.subTrees) {
        if (child.methodId == methodId && child.classId == classId) return child;
    }
    
    RPCallTree* subTree = nil;
    if (createIfNeeded) {
        subTree = [[RPCallTree alloc] init];
        
		subTree.parent = self;
		subTree.methodId = methodId;
        subTree.classId = classId;
        
        [self.subTrees addObject:subTree];
    }
    
    return subTree;
}

- (RPCallTree*) matchingSubTree:(RPCallTree*)otherSubTree create:(BOOL)createIfNeeded
{
    return [self subTreeForMethodId:otherSubTree.methodId classId:otherSubTree.classId create:createIfNeeded];
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

- (BOOL)isSameFrameAs:(RPCallTree* __unsafe_unretained)otherCallTree
{
    if (!otherCallTree)return NO;
    return _methodId == otherCallTree->_methodId && _classId == otherCallTree->_classId;
}

- (NSArray*)snapshotOfCurrentChildren
{
    return [self.subTrees copy];
}

- (void)freeze
{
	if (self.parent == nil) {
		self.root = self;
	} else {
		self.root = self.parent.root;
	}
    
    self.sampleCount = self.selfSampleCount;
    self.stackTraceCount = self.selfStackTraceCount;
    self.blockedTicks = self.selfBlockedTicks;
    self.children = self.subTrees;

	for (RPCallTree* child in self.children) {
		[child freeze];

        self.sampleCount += child.sampleCount;
        self.stackTraceCount += child.stackTraceCount;
        self.blockedTicks += child.blockedTicks;
	}
    self.children = [self.children sortedArrayUsingDescriptors:[self.class defaultSortDescriptor]];

}




#pragma mark -
#pragma mark Simple Tree Manipulation functions 

- (id)copy
{
    return [[[self class] alloc] init];
}

- (RPCallTree *)copyWithParent:(RPCallTree*)parent withRoot:(RPCallTree*)root
{
    RPCallTree* treeCopy = [[[self class] alloc] init];
    
    treeCopy.methodId = self.methodId;
    treeCopy.classId = self.classId;
    treeCopy.fileId = self.fileId;

    treeCopy.selfSampleCount = self.selfSampleCount;
    treeCopy.selfStackTraceCount = self.selfStackTraceCount;
    treeCopy.selfBlockedTicks = self.selfBlockedTicks;
    
    treeCopy.method = self.method;
    treeCopy.moduleOrClass = self.moduleOrClass;
    treeCopy.file = self.file;
    treeCopy.thread = self.thread;
    treeCopy.startLine = self.startLine;
    
    treeCopy.parent = parent;

    
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


- (void) moveToUpperCallTree:(RPCallTree* __unsafe_unretained)upperCallTree
{
    NSAssert(self.parent, @"How can we move to an upper level without having a parent");
    RPCallTree* tree = self; // Since we're ARC-based, avoid accidental release of self when calling removeSubTree
    [tree.parent removeSubTree:self];
    [tree mergeTreeTo:upperCallTree deep:YES];
    self.root = nil;
    self.parent = nil;
}

- (void) mergeTreeTo:(RPCallTree*)otherTree deep:(BOOL)deepMerge
{
    otherTree.selfSampleCount += self.selfSampleCount;
    otherTree.selfStackTraceCount += self.selfStackTraceCount;
    otherTree.selfBlockedTicks += self.selfBlockedTicks;

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

- (void) addTreeTo:(RPCallTree*)otherTree deep:(BOOL)deepMerge
{
    otherTree.selfSampleCount += self.selfSampleCount;
    otherTree.selfStackTraceCount += self.selfStackTraceCount;
    otherTree.selfBlockedTicks += self.selfBlockedTicks;
    
    // FixMe: really, we shouldn't have to do this. Properly implement copies.
    otherTree.methodId = self.methodId;
    otherTree.classId = self.classId;
    otherTree.fileId = self.fileId;
    otherTree.method = self.method;
    otherTree.moduleOrClass = self.moduleOrClass;
    otherTree.file = self.file;
    otherTree.thread = self.thread;
    otherTree.startLine = self.startLine;
    
    if (deepMerge) {
        [self eachChild:^(RPCallTree* child) {
            RPCallTree* otherChild = [otherTree matchingSubTree:child create:YES];
            [child addTreeTo:otherChild deep:YES];
        }];
    }
}

- (void) mergeRecursionsWithMaxRecursionHops:(NSInteger)maxHops
{
    RPCallTree* __unsafe_unretained duplicateAncestor = nil;
    RPCallTree* __unsafe_unretained ancestor = self.parent;
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
        for (RPCallTree* __unsafe_unretained child in currentChildren) {
            if (child.parent == self) [child mergeRecursionsWithMaxRecursionHops:maxHops];
        }
    }
}


- (void) recursivelyMergeIdenticalCalls:(RPCallTree*)targetCall into:(RPCallTree*)rootDestination
{
    if ([self isSameFrameAs:targetCall]) {
        [self addTreeTo:rootDestination deep:YES];
    } else {
        for (RPCallTree* child in self.subTrees) {
            [child recursivelyMergeIdenticalCalls:targetCall into:rootDestination];
        }
    }
}


@end
