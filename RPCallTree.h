//
//  RPCallTree.h
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RPCallTree : NSObject {
    UInt8  _mergeStatus;
}

// canonical identifiers

@property (nonatomic, assign)	NSInteger functionId;
@property (nonatomic, assign)	NSInteger classId;
@property (nonatomic, assign)	NSInteger fileId;

// canonical timing data

@property (nonatomic, assign)	NSInteger selfSampleCount;
@property (nonatomic, assign)	NSInteger selfStackTraceCount;
@property (nonatomic, assign)	NSInteger selfBlockedTicks;

// computed timing data (recomputed by freeze method)

@property (nonatomic, assign)	NSInteger sampleCount;
@property (nonatomic, assign)	NSInteger stackTraceCount;
@property (nonatomic, assign)	NSInteger blockedTicks;

// dynamically computed timing data

@property (nonatomic, readonly)	double totalTime;
@property (nonatomic, readonly)	double selfTime;

@property (nonatomic, assign)   double duration; 


// children

@property (nonatomic)	NSMutableArray* subTrees;   // canonical data
@property (nonatomic)	NSArray* children;          // sorted children for presentation

// access to ancestors.

@property (readonly,  unsafe_unretained)	RPCallTree* parent; // Consistency is handled by the code. Declared unsafe to avoid costly weak ARC maps
@property (readonly,  unsafe_unretained)	RPCallTree* root;   // Same comment ^^

// more or less deprecated or not yet refactored

@property (nonatomic)	NSString* symbolId;
@property (nonatomic)	NSString* symbol;
@property (nonatomic)	NSString* file;
@property (nonatomic)	NSString* ns;
@property (nonatomic, assign)	SInt64 thread;

@property (nonatomic, assign)	NSInteger startLine;



- (RPCallTree*) subTreeForFunctionId:(NSInteger)functionId classId:(NSInteger)classId create:(BOOL)createIfNeeded;


- (void)freeze;

- (RPCallTree *)topDownCallTreeForSymbolId:(NSString *)symbolId;
- (RPCallTree *)bottomUpCallTreeForSymbolId:(NSString *)functionSymbolId;


- (void) mergeRecursionsWithMaxRecursionHops:(NSInteger)maxHops;
- (void) recursivelyMergeIdenticalCalls:(RPCallTree*)targetCall into:(RPCallTree*)rootDestination;

- (RPCallTree *)copyWithParent:(RPCallTree*)parent withRoot:(RPCallTree*)root;
- (void)addSubTree:(RPCallTree*)child;

@end
