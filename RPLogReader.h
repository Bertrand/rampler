//
//  RPLogReader.h
//  Rampler
//
//  Created by Bertrand Guiheneuf on 7/25/12.
//  Copyright (c) 2012 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RPSampleSession;

@protocol RPLogReader <NSObject>

- (double)interval;
- (NSString *)version;
- (NSURL *)url;
- (NSInteger)logLineNumber;
- (void)setLogLineNumber:(NSInteger)logLineNumber;
- (NSData*)data;
- (void)setData:(NSData*)data;
- (NSDate *)startDate;
- (double)duration;

- (RPSampleSession*)sampleSession;

@end
