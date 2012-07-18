//
//  RPOutlineView.m
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import "RPOutlineView.h"


@implementation RPOutlineView

@synthesize columnIdentifierForCopy;

- (void)copy:(id)sender
{
	NSInteger selectedRow;
    
    selectedRow = [self selectedRow];
    if (selectedRow != -1) {
		id item;
        
        item = [self itemAtRow:selectedRow];
		for (NSTableColumn *column in [self tableColumns]) {
    		if ([[column identifier] isEqualToString:columnIdentifierForCopy]) {
            	NSString *string;
                NSPasteboard *pasteboard;
                
                string = [[self dataSource] outlineView:self objectValueForTableColumn:column byItem:item];
                pasteboard = [NSPasteboard generalPasteboard];
				[pasteboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
        		[pasteboard setString:string forType:NSStringPboardType];
                break;
	        }
        }
    }
}

@end
