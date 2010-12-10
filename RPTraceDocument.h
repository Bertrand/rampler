//
//  MyDocument.h
//  Rampler
//
//  Created by Guiheneuf Bertrand on 9/29/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class RPCallTree, RPOutlineView;


@interface RPTraceDocument : NSDocument <NSMenuDelegate>
{
	NSString *version;
	double interval;
	NSURL *url;
	RPCallTree* root;
	RPCallTree* displayRoot;
	double duration;
	
	IBOutlet NSNumberFormatter* percentFormatter;
	IBOutlet RPOutlineView* mainOutlineView;
    IBOutlet NSButton* focusButton;
    IBOutlet NSButton* focusDownFunctionButton;
    IBOutlet NSButton* focusUpFunctionButton;
    IBOutlet NSButton* hottestSubpathButton;
	IBOutlet NSTextField* urlTextField;
	
	IBOutlet NSTextField* totalTimeTextField;
	IBOutlet NSTextField* intervalTextField;
	IBOutlet NSTextField* tickCountTextField;
	IBOutlet NSTextField* stackCountTextField;
	IBOutlet NSTextField* versionTextField;
	
	BOOL displayTimeUnitAsPercentOfTotal;
    BOOL hideInsignificantCalls;
    
	NSMutableArray *columnInfo;
	BOOL updatingColumns;
    RPTraceDocument *mainDocument;
}

@property (nonatomic, readonly, retain) RPCallTree* root;
@property (nonatomic, readonly, retain) RPCallTree* displayRoot;
@property (nonatomic, assign) NSNumberFormatter* percentFormatter;
@property (nonatomic, readonly, assign) RPOutlineView* mainOutlineView;;
@property (nonatomic, assign) BOOL displayTimeUnitAsPercentOfTotal;
@property (nonatomic, assign) BOOL hideInsignificantCalls;
@property (nonatomic, readonly, retain) RPTraceDocument *mainDocument;
@property (nonatomic, readonly, retain) NSString *version;
@property (nonatomic, readonly, retain) NSURL* url;
@property (nonatomic, readonly, assign) double interval;
@property (nonatomic, readonly, assign) double duration;

- (IBAction)focusButtonAction:(id)sender;
- (IBAction)followHottestSubpath:(id)sender;
- (IBAction)focusDownFunctionButtonAction:(id)sender;
- (IBAction)focusUpFunctionButtonAction:(id)sender;
- (void)updateTimeFormatter;

@end
