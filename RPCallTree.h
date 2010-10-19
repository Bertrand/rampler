//
//  RPCallTree.h
//  Rampler
//
//  Created by Guiheneuf Bertrand on 9/29/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RPLogReader;

@interface RPCallTree : NSObject {
	double		totalTime;
	double		selfTime;
	NSInteger	callCount;
	
	NSString*	symbol;
	NSArray*	children;
	SInt64	thread;
	NSInteger	stackDepth;
	NSInteger	startLine;
	
	RPCallTree* parent;
	RPCallTree* root;
	
	NSMutableDictionary* subTrees;
}

@property (readwrite, retain)	NSString* symbol;
@property (readwrite, assign)	SInt64 thread;
@property (readwrite, assign)	NSInteger stackDepth;
@property (readonly,  assign)	RPCallTree* parent;
@property (readwrite, assign)	double totalTime;
@property (readwrite, assign)	double selfTime;
@property (readwrite, retain)	NSMutableDictionary* subTrees;
@property (readwrite, retain)	NSArray* children;
@property (readwrite, assign)	NSInteger startLine;
@property (readwrite, assign)	NSInteger callCount;


- (void) feedFromLogReader:(RPLogReader*)reader;
- (RPCallTree*) subTreeForSymbol:(NSString*)symbol;


- (void)freeze;

@end
