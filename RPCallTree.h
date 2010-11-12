//
//  RPCallTree.h
//  Rampler
//
//  Created by Guiheneuf Bertrand on 9/29/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RPCallTree : NSObject {
	double		totalTime;
	double		selfTime;
	NSInteger	callCount;
	
	NSString*	symbol;
	NSArray*	children;
	SInt64	thread;
	NSInteger	stackDepth;
	NSInteger	startLine;
	NSString*	file;
	
	RPCallTree* parent;
	RPCallTree* root;
	
	NSMutableDictionary* subTrees;
	
	NSMutableDictionary* callDetails;
}

@property (nonatomic, retain)	NSString* symbolId;
@property (nonatomic, retain)	NSString* symbol;
@property (nonatomic, retain)	NSString* file;
@property (nonatomic, assign)	SInt64 thread;
@property (nonatomic, assign)	NSInteger stackDepth;
@property (readonly,  assign)	RPCallTree* parent;
@property (nonatomic, assign)	double totalTime;
@property (nonatomic, assign)	double selfTime;
@property (nonatomic, retain)	NSMutableDictionary* subTrees;
@property (nonatomic, retain)	NSArray* children;
@property (nonatomic, assign)	NSInteger startLine;
@property (nonatomic, assign)	NSInteger callCount;
@property (nonatomic, assign)	NSMutableDictionary* callDetails;


- (RPCallTree*) subTreeForSymbolId:(NSString*)sym;


- (void)freeze;

- (void)addCallDetailsForFile:(NSString *)file time:(double)valueToAdd;

@end
