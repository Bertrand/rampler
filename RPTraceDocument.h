//
//  MyDocument.h
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class RPSampleSession, RPCallTree, RPOutlineView;


@interface RPTraceDocument : NSDocument <NSMenuDelegate>
{	
    IBOutlet NSButton* unfocusButton;
    IBOutlet NSButton* focusButton;
    IBOutlet NSButton* focusDownFunctionButton;
    IBOutlet NSButton* hottestSubpathButton;
    IBOutlet NSButton* flattenRecursionButton;
	IBOutlet NSTextField* urlTextField;
	
	IBOutlet NSTextField* totalTimeTextField;
	IBOutlet NSTextField* intervalTextField;
	IBOutlet NSTextField* realIntervalTextField;
	IBOutlet NSTextField* tickCountTextField;
	IBOutlet NSTextField* stackCountTextField;
	IBOutlet NSTextField* versionTextField;
	
    BOOL hideInsignificantCalls;
    
	NSMutableArray *columnInfo;
	BOOL updatingColumns;
}

@property (nonatomic, readonly) RPSampleSession* root;
@property (nonatomic, readonly) RPSampleSession* displayRoot;
@property (nonatomic, weak) NSNumberFormatter* percentFormatter;
@property (nonatomic, readonly, weak) RPOutlineView* mainOutlineView;;
@property (nonatomic, assign) BOOL displayTimeUnitAsPercentOfTotal;

@property (nonatomic, assign) BOOL hideInsignificantCalls;
@property (nonatomic, assign) BOOL flattenRecursion;

@property (nonatomic, readonly) RPTraceDocument *mainDocument;
@property (nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) NSURL* url;
@property (nonatomic, readonly, assign) double interval;
@property (nonatomic, readonly, assign) double duration;

- (IBAction)focusButtonAction:(id)sender;
- (IBAction)followHottestSubpath:(id)sender;
- (IBAction)focusDownFunctionButtonAction:(id)sender;
- (IBAction)flattenRecursionButtonAction:(id)sender;
- (void)updateTimeFormatter;
@end
