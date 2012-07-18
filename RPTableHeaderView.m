//
//  RPTableHeaderView.m
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import "RPTableHeaderView.h"

@interface NSObject(RPTableHeaderView)

- (NSMenu *)headerMenuForTableView:(NSTableView *)tableView event:(NSEvent *)event;

@end


@implementation RPTableHeaderView

- (NSMenu *)menuForEvent:(NSEvent *)event;
{
	return [(NSObject *)[[self tableView] delegate] headerMenuForTableView:[self tableView] event:event];
}

@end
