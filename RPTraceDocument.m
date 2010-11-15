//
//  MyDocument.m
//  Rampler
//
//  Created by Guiheneuf Bertrand on 9/29/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import "RPTraceDocument.h"
#import "RPCallTree.h"
#import "RPDTraceLogReader.h"
#import "RPRubyTraceLogReader.h"
#import "RPOutlineView.h"

@interface RPTraceDocument()

@property (nonatomic, retain) RPCallTree* root;
@property (nonatomic, retain) RPCallTree* displayRoot;
@property (nonatomic, assign) RPOutlineView* mainOutlineView;;
@property (nonatomic, retain) RPTraceDocument *mainDocument;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSURL* url;
@property (nonatomic, assign) double interval;

@end


@implementation RPTraceDocument

@synthesize root, displayRoot;
@synthesize percentFormatter;
@synthesize displayTimeUnitAsPercentOfTotal;
@synthesize mainOutlineView;
@synthesize mainDocument;
@synthesize version;
@synthesize url;
@synthesize interval;

- (id)init
{
    self = [super init];
    if (self) {
		self.displayTimeUnitAsPercentOfTotal = YES;
    }
    return self;
}

- (void)dealloc
{
	self.root = nil;
	self.displayRoot = nil;
    self.mainDocument = nil;
	self.version = nil;
	self.url = nil;
	[super dealloc];
}

- (void)loadWithMainDocument:(RPTraceDocument *)document root:(RPCallTree *)newRoot version:(NSString *)newVersion
{
	self.mainDocument = document;
	self.root = newRoot;
	self.version = newVersion;
	self.interval = document.interval;
	self.url = document.url;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.

    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (void)setRoot:(RPCallTree *)newRoot
{
	if (newRoot != root) {
		[root release];
		root = [newRoot retain];
		self.displayRoot = root;
		if (root) {
	    	[mainOutlineView reloadData];
		}
	}
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	id<RPLogReader> reader = nil;
	
	if ([typeName isEqualToString:@"Dtrace files"]) {
		reader = [[RPDTraceLogReader alloc] initWithData:data];
	} else if ([typeName isEqualToString:@"Ruby trace"]) {
		reader = [[RPRubyTraceLogReader alloc] initWithData:data];
	}
	self.root = [reader callTree];
	self.version = [reader version];
	self.url = [reader url];
	self.interval = [reader interval];
	[reader release];
	
    // Insert code here to read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.

    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead. 
    
    // For applications targeted for Panther or earlier systems, you should use the deprecated API -loadDataRepresentation:ofType. In this case you can also choose to override -readFromFile:ofType: or -loadFileWrapperRepresentation:ofType: instead.
    
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    
    return YES;
}


- (void) setDisplayTimeUnitAsPercentOfTotal:(BOOL)percentEnabled
{
	displayTimeUnitAsPercentOfTotal = percentEnabled;
	[self updateTimeFormatter];
	[self.mainOutlineView reloadData];
	[self.mainOutlineView setNeedsDisplay];
}

- (void)awakeFromNib
{
	[self updateTimeFormatter];
    if (self.mainDocument) {
    	[focusDownFunctionButton setHidden:YES];
    	[focusUpFunctionButton setHidden:YES];
    }
	if (self.mainDocument) {
	    [infoTextField setStringValue:[NSString stringWithFormat:@"%d stacks (%.2f%%) / %.2fms", root.stackTraceCount, (double)(self.root.totalTime / self.mainDocument.root.totalTime * 100.0), self.interval * 1000.0]];
	} else {
	    [infoTextField setStringValue:[NSString stringWithFormat:@"%d stacks / %.2fms", root.stackTraceCount, self.interval * 1000.0]];
	}
	[infoTextField setToolTip:self.version];
	[urlTextField setStringValue:[self.url absoluteString]];
	[urlTextField setToolTip:[self.url absoluteString]];
    mainOutlineView.columnIdentifierForCopy = @"file";
	[mainOutlineView setDoubleAction:@selector(outlineDoubleAction:)];
}

- (void)updateTimeFormatter
{
	if (displayTimeUnitAsPercentOfTotal) {
		self.percentFormatter.multiplier = [NSNumber numberWithDouble:100.0 / displayRoot.totalTime];
		self.percentFormatter.positiveSuffix = @"%";
		self.percentFormatter.maximumFractionDigits = 2;

	} else {
		self.percentFormatter.multiplier = [NSNumber numberWithDouble:1.0 / 1000.0];
		self.percentFormatter.positiveSuffix = @"ms";
		self.percentFormatter.maximumFractionDigits = 2;
	}
	
}

- (NSArray *)childrenForCallTree:(RPCallTree *)callTree
{
	NSArray *result;
    
	if (!hideInsignificantCalls) {
    	result = [callTree children];
    } else {
    	while (YES) {
        	result = [callTree children];
            if ([result count] == 0) {
            	break;
            } else if ([result count] == 1) {
                callTree = [result objectAtIndex:0];
                if (callTree.totalTime * 5 / 100 < callTree.selfTime) {
                	break;
                }
            } else {
            	NSMutableArray *significantChildren;
                NSInteger ii, count;
                
                significantChildren = [result mutableCopy];
                count = [significantChildren count];
                for (ii = 0; ii < count; ii++) {
                	RPCallTree *current = [significantChildren objectAtIndex:ii];
                    
                    if (callTree.totalTime * 5 / 100 > current.totalTime) {
                    	[significantChildren removeObjectAtIndex:ii];
                        count--;
                        ii--;
                    }
                }
                result = [significantChildren autorelease];
                break;
        	}
        }
    }
    return result;
}

- (void)expandAndSelectCallTree:(RPCallTree *)node
{
    NSMutableArray *parents;
    NSInteger selectedRow;
    
    selectedRow = -1;
    parents = [[NSMutableArray alloc] init];
    while (node) {
        [parents insertObject:node atIndex:0];
        node = node.parent;
    }
    for (RPCallTree *node in parents) {
        NSInteger row;
        
        [mainOutlineView expandItem:node];
        row = [mainOutlineView rowForItem:node];
        if (row != -1) {
            selectedRow = row;
        }
    }
    if (selectedRow != -1) {
        [mainOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
    } else {
        [mainOutlineView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    }
    [parents release];
}

- (IBAction)outlineDoubleAction:(id)sender
{
	NSInteger selectedRow = [self.mainOutlineView selectedRow];
	
	if (selectedRow != -1) {
		RPCallTree* selectedNode = [self.mainOutlineView itemAtRow:selectedRow];
		
		if ([mainOutlineView isItemExpanded:selectedNode]) {
			[mainOutlineView collapseItem:selectedNode];
		} else {
			[self followHottestSubpath:nil];
		}
	}
}

- (IBAction)followHottestSubpath:(id)sender
{
	NSInteger selectedRow = [self.mainOutlineView selectedRow];
	RPCallTree* selectedNode = [self.mainOutlineView itemAtRow:selectedRow];
	
	RPCallTree* hottestNode = selectedNode;
	while ([[self childrenForCallTree:hottestNode] count] > 0) {
		[self.mainOutlineView expandItem:hottestNode];
		hottestNode = [[self childrenForCallTree:hottestNode] objectAtIndex:0];
	}
}

- (IBAction)focusButtonAction:(id)sender
{
	NSInteger selectedRow;
    RPCallTree *callTreeToSelect = nil;
    
    selectedRow = [mainOutlineView selectedRow];
    if (selectedRow != -1) {
    	self.displayRoot = [mainOutlineView itemAtRow:selectedRow];
    } else {
        callTreeToSelect = displayRoot;
    	self.displayRoot = root;
    }
	[self updateTimeFormatter];
    [mainOutlineView reloadData];
    [self expandAndSelectCallTree:callTreeToSelect];
}

- (void)openFocusOnSelectionWithTopDown:(BOOL)topDown
{
	NSInteger selectedRow;
	
    selectedRow = [mainOutlineView selectedRow];
    if (selectedRow != -1) {
		RPTraceDocument *newDocument;
		RPCallTree *selectedCallTree;
		RPCallTree *newRoot;
		
    	selectedCallTree = [mainOutlineView itemAtRow:selectedRow];
		newDocument = [[RPTraceDocument alloc] initWithType:@"Ruby trace" error:nil];
		if (topDown) {
			newRoot = [root topDownCallTreeForSymbolId:selectedCallTree.symbolId];
		} else {
			newRoot = [root bottomUpCallTreeForSymbolId:selectedCallTree.symbolId];
		}
        if (self.mainDocument) {
			[newDocument loadWithMainDocument:self.mainDocument root:newRoot version:self.version];
        } else {
			[newDocument loadWithMainDocument:self root:newRoot version:self.version];
        }
		[[NSDocumentController sharedDocumentController] addDocument:newDocument];
		[newDocument makeWindowControllers];
		[newDocument showWindows];
		[newDocument release];
	}
}

- (IBAction)focusDownFunctionButtonAction:(id)sender;
{
	[self openFocusOnSelectionWithTopDown:YES];
}

- (IBAction)focusUpFunctionButtonAction:(id)sender
{
	[self openFocusOnSelectionWithTopDown:NO];
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (!item) {
    	item = displayRoot;
    }
    return [[self childrenForCallTree:item] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return [[self childrenForCallTree:item] count];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!item) {
    	item = displayRoot;
    }
	return [[self childrenForCallTree:item] count];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	id result = nil;
    
	if ([[tableColumn identifier] isEqualToString:@"thread"]) {
    	result = [NSNumber numberWithLongLong:[item thread]];
	} else if ([[tableColumn identifier] isEqualToString:@"totalTime"]) {
    	result = [NSNumber numberWithFloat:[item totalTime]];
	} else if ([[tableColumn identifier] isEqualToString:@"selfTime"]) {
    	result = [NSNumber numberWithFloat:[item selfTime]];
	} else if ([[tableColumn identifier] isEqualToString:@"callCount"]) {
    	result = [NSNumber numberWithInteger:[item sampleCount]];
	} else if ([[tableColumn identifier] isEqualToString:@"file"]) {
    	result = [item file];
	} else if ([[tableColumn identifier] isEqualToString:@"symbol"]) {
    	result = [item symbol];
    }
    return result;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification;
{
	if ([mainOutlineView selectedRow] == -1) {
		[focusButton setTitle:@"Unfocus"];
        [focusButton setEnabled:root != displayRoot];
        [focusDownFunctionButton setEnabled:NO];
        [focusUpFunctionButton setEnabled:NO];
        [hottestSubpathButton setEnabled:NO];
    } else {
		[focusButton setTitle:@"Focus"];
        [focusButton setEnabled:YES];
        [focusDownFunctionButton setEnabled:YES];
        [focusUpFunctionButton setEnabled:YES];
        [hottestSubpathButton setEnabled:YES];
    }
}

- (void)setHideInsignificantCalls:(BOOL)value
{
	NSInteger selectedRow = [self.mainOutlineView selectedRow];
	RPCallTree* selectedNode = nil;
    
    if (selectedRow != -1) {
	    selectedNode = [self.mainOutlineView itemAtRow:selectedRow];
    }
	hideInsignificantCalls = value;
    [mainOutlineView reloadData];
    if (selectedNode) {
    	[self expandAndSelectCallTree:selectedNode];
    }
}

- (BOOL)hideInsignificantCalls
{
	return hideInsignificantCalls;
}

@end
