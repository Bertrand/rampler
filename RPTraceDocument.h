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
	RPCallTree* displayRoot;
	
	IBOutlet NSNumberFormatter* percentFormatter;
	IBOutlet NSOutlineView* mainOutlineView;
    IBOutlet NSButton* focusButton;
    IBOutlet NSButton* focusFunctionButton;
    IBOutlet NSButton* hottestSubpathButton;
	BOOL displayTimeUnitAsPercentOfTotal;
    BOOL hideInsignificantCalls;
}

@property (nonatomic, retain) RPCallTree* root;
@property (nonatomic, retain) RPCallTree* displayRoot;
@property (nonatomic, assign) NSNumberFormatter* percentFormatter;
@property (nonatomic, assign) NSOutlineView* mainOutlineView;;
@property (nonatomic, assign) BOOL displayTimeUnitAsPercentOfTotal;
@property (nonatomic, assign) BOOL hideInsignificantCalls;

- (IBAction)focusButtonAction:(id)sender;
- (IBAction)followHottestSubpath:(id)sender;
- (IBAction)focusFunctionButtonAction:(id)sender;
- (void)updateTimeFormatter;

@end
