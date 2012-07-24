//
//  RPOutlineView.h
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RPOutlineView : NSOutlineView
{
	NSString *columnIdentifierForCopy;
}

@property( nonatomic) NSString *columnIdentifierForCopy;

@end
