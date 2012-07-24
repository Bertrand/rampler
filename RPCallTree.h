//
//  RPCallTree.h
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RPCallTree : NSObject {
	double		totalTime;
	double		selfTime;
	NSInteger	sampleCount;
	NSInteger   stackTraceCount;
	
	NSString*	symbol;
	NSArray*	children;
	SInt64	thread;
	NSInteger	stackDepth;
	NSInteger	startLine;
	NSString*	file;
	NSString*	ns;
	NSInteger	blockedTicks;
	
	RPCallTree* __weak parent;
	RPCallTree* root;
	
	NSMutableDictionary* subTrees;
	
	NSMutableDictionary* callDetails;
}

@property (nonatomic)	NSString* symbolId;
@property (nonatomic)	NSString* symbol;
@property (nonatomic)	NSString* file;
@property (nonatomic, assign)	SInt64 thread;
@property (nonatomic, assign)	NSInteger stackDepth;
@property (readonly,  weak)	RPCallTree* parent;
@property (nonatomic, assign)	double totalTime;
@property (nonatomic, assign)	double selfTime;
@property (nonatomic)	NSMutableDictionary* subTrees;
@property (nonatomic)	NSArray* children;
@property (nonatomic, assign)	NSInteger startLine;
@property (nonatomic, assign)	NSInteger sampleCount;
@property (nonatomic, assign)	NSInteger stackTraceCount;
@property (nonatomic)	NSMutableDictionary* callDetails;
@property (nonatomic)	NSString* ns;
@property (nonatomic, assign)	NSInteger blockedTicks;


- (RPCallTree*) subTreeForSymbolId:(NSString*)sym;


- (void)freeze;

- (void)addCallDetailsForFile:(NSString *)file time:(double)valueToAdd;
- (RPCallTree *)topDownCallTreeForSymbolId:(NSString *)symbolId;
- (RPCallTree *)bottomUpCallTreeForSymbolId:(NSString *)functionSymbolId;

@end
