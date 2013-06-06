//
//  RPSampleSession.m
//  Rampler
//
//  Created by Bertrand Guiheneuf on 6/6/13.
//
//

#import "RPSampleSession.h"

@implementation RPSampleSession


- (RPCallTree *)copyWithParent:(RPCallTree*)parent withRoot:(RPCallTree*)root
{
    RPSampleSession* treeCopy = (RPSampleSession*)[super copyWithParent:parent withRoot:root];
    
    treeCopy.sessionDurationPerTick = self.sessionDurationPerTick;

    return treeCopy;
}

- (id)copy
{
    RPSampleSession* treeCopy = (RPSampleSession*)[super copy];
    treeCopy.sessionDurationPerTick = self.sessionDurationPerTick;
    
    return treeCopy;
}

    

- (RPSampleSession*)sessionByFocussingOnSubTree:(RPCallTree*)subTree
{
    RPSampleSession* newSession = [self copy];
    RPCallTree* treeCopy = [subTree copyWithParent:newSession withRoot:newSession];
    [newSession addSubTree:treeCopy];
    [newSession freeze];
    return newSession;
}

- (RPSampleSession*)callTreeByMergingDownIdenticalCalls:(RPCallTree*)call
{
    RPSampleSession* result = [[RPSampleSession alloc] init];
    result.sessionDurationPerTick = self.sessionDurationPerTick;
    
    [self recursivelyMergeIdenticalCalls:call into:result];
    [result freeze];
    
    return result;
}



- (RPSampleSession *)sessionByFlatteningRecursion
{
    RPSampleSession* result = (RPSampleSession*)[self copyWithParent:nil withRoot:nil];
    
    [result mergeRecursionsWithMaxRecursionHops:6];
    [result freeze];
    
    return result;
}

@end
