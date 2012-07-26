//
//  MyDocument.h
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class RPCallTree, RPOutlineView;


@interface RPTraceDocument : NSDocument <NSMenuDelegate>
{	
	IBOutlet NSNumberFormatter* __weak percentFormatter;
	IBOutlet RPOutlineView* __weak mainOutlineView;
    IBOutlet NSButton* unfocusButton;
    IBOutlet NSButton* focusButton;
    IBOutlet NSButton* focusDownFunctionButton;
    IBOutlet NSButton* focusUpFunctionButton;
    IBOutlet NSButton* hottestSubpathButton;
	IBOutlet NSTextField* urlTextField;
	
	IBOutlet NSTextField* totalTimeTextField;
	IBOutlet NSTextField* intervalTextField;
	IBOutlet NSTextField* realIntervalTextField;
	IBOutlet NSTextField* tickCountTextField;
	IBOutlet NSTextField* stackCountTextField;
	IBOutlet NSTextField* versionTextField;
	
	BOOL displayTimeUnitAsPercentOfTotal;
    BOOL hideInsignificantCalls;
    
	NSMutableArray *columnInfo;
	BOOL updatingColumns;
    RPTraceDocument *mainDocument;
}

@property (nonatomic, readonly) RPCallTree* root;
@property (nonatomic, readonly) RPCallTree* displayRoot;
@property (nonatomic, weak) NSNumberFormatter* percentFormatter;
@property (nonatomic, readonly, weak) RPOutlineView* mainOutlineView;;
@property (nonatomic, assign) BOOL displayTimeUnitAsPercentOfTotal;
@property (nonatomic, assign) BOOL hideInsignificantCalls;
@property (nonatomic, readonly) RPTraceDocument *mainDocument;
@property (nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) NSURL* url;
@property (nonatomic, readonly) NSString* secretKey;
@property (nonatomic, readonly, assign) double interval;
@property (nonatomic, readonly, assign) double duration;

- (IBAction)unfocusButtonAction:(id)sender;
- (IBAction)focusButtonAction:(id)sender;
- (IBAction)followHottestSubpath:(id)sender;
- (IBAction)focusDownFunctionButtonAction:(id)sender;
- (IBAction)focusUpFunctionButtonAction:(id)sender;
- (IBAction)urlTextFieldClicked:(id)sender;
- (void)updateTimeFormatter;

@end
