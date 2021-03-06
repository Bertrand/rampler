//
//  RPStackTrace.h
//  Rampler
//
//

#import <Foundation/Foundation.h>

@class RPStackFrame;

@interface RPStackTrace : NSObject

@property (nonatomic, readwrite) NSMutableArray* frames;
@property (nonatomic, readwrite, assign) double duration;
@property (nonatomic, readwrite, assign) NSUInteger sampleCount;
@end
