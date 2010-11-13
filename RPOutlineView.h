//
//  RPOutlineView.h
//  Rampler
//
//  Created by Jérôme Lebel on 14/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RPOutlineView : NSOutlineView
{
	NSString *columnIdentifierForCopy;
}

@property(retain, nonatomic) NSString *columnIdentifierForCopy;

@end
