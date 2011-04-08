//
//  RPApplication.h
//  Rampler
//
//  Created by Guiheneuf Bertrand on 08/04/11.
//  Copyright 2011 Fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RPApplication : NSApplication {

}

@property(nonatomic, readwrite, retain) NSMutableDictionary* additionalHTTPHeaders;



@end
