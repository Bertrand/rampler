//
//  RPSampleSession.h
//  Rampler
//
//  Created by Bertrand Guiheneuf on 6/6/13.
//
//

#import "RPCallTree.h"

@interface RPSampleSession : RPCallTree

@property (nonatomic, assign)   double sessionDurationPerTick;

- (RPSampleSession*)sessionByFocussingOnSubTree:(RPCallTree*)subTree;
- (RPSampleSession*)callTreeByMergingDownIdenticalCalls:(RPCallTree*)call;
- (RPSampleSession *)sessionByFlatteningRecursion;

@end
