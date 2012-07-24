//
//  RPApplication.h
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>



@interface RPApplication : NSApplication {

}

@property(nonatomic, readwrite) NSMutableDictionary* additionalHTTPHeaders;



@end
