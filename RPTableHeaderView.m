//
//  RPTableHeaderView.m
//  Rampler
//
//  Created by Jérôme Lebel on 09/12/10.
//  Copyright 2010 Fotonauts. All rights reserved.
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
