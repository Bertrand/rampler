//
//  MyDocument.h
//  Rampler
//
//  Created by Guiheneuf Bertrand on 9/29/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class RPCallTree, RPOutlineView;


@interface RPTraceDocument : NSDocument
{
	NSString *version;
	RPCallTree* root;
	RPCallTree* displayRoot;
	
	IBOutlet NSNumberFormatter* percentFormatter;
	IBOutlet RPOutlineView* mainOutlineView;
    IBOutlet NSButton* focusButton;
    IBOutlet NSButton* focusDownFunctionButton;
    IBOutlet NSButton* focusUpFunctionButton;
    IBOutlet NSButton* hottestSubpathButton;
    IBOutlet NSTextField* infoTextField;
	BOOL displayTimeUnitAsPercentOfTotal;
    BOOL hideInsignificantCalls;
    
    RPTraceDocument *mainDocument;
}

@property (nonatomic, retain) RPCallTree* root;
@property (nonatomic, retain) RPCallTree* displayRoot;
@property (nonatomic, assign) NSNumberFormatter* percentFormatter;
@property (nonatomic, assign) RPOutlineView* mainOutlineView;;
@property (nonatomic, assign) BOOL displayTimeUnitAsPercentOfTotal;
@property (nonatomic, assign) BOOL hideInsignificantCalls;
@property (nonatomic, readonly, retain) RPTraceDocument *mainDocument;
@property (nonatomic, readonly, retain) NSString *version;

- (IBAction)focusButtonAction:(id)sender;
- (IBAction)followHottestSubpath:(id)sender;
- (IBAction)focusDownFunctionButtonAction:(id)sender;
- (IBAction)focusUpFunctionButtonAction:(id)sender;
- (void)updateTimeFormatter;

@end
