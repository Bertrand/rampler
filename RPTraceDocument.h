//
//  MyDocument.h
//  Rampler
//
//  Created by Guiheneuf Bertrand on 9/29/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//


#import <Cocoa/Cocoa.h>
@class RPCallTree;


@interface RPTraceDocument : NSDocument
{
	RPCallTree* root;
	
	IBOutlet NSNumberFormatter* percentFormatter;
	IBOutlet NSOutlineView* mainOutlineView;
	BOOL displayTimeUnitAsPercentOfTotal;
}

@property (readwrite, assign) RPCallTree* root;
@property (readwrite, assign) NSNumberFormatter* percentFormatter;
@property (readwrite, assign) NSOutlineView* mainOutlineView;;
@property (readwrite, assign) BOOL displayTimeUnitAsPercentOfTotal;

- (IBAction) followHottestSubpath:(id)sender;
- (void)updateTimeFormatter;

@end
