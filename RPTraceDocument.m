
//
//  MyDocument.m
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import "RPTraceDocument.h"
#import "RPCallTree.h"
#import "RPRubyTraceLogReader.h"
#import "RPOutlineView.h"
#import "RPTableHeaderView.h"

#define COLUMN_INFO_VERSION 5

@interface RPTraceDocument()

@property (nonatomic) RPCallTree* root;
@property (nonatomic) RPCallTree* displayRoot;
@property (nonatomic, weak) RPOutlineView* mainOutlineView;;
@property (nonatomic) RPTraceDocument *mainDocument;
@property (nonatomic) NSString *version;
@property (nonatomic) NSURL* url;
@property (nonatomic, assign) double interval;
@property (nonatomic, assign) double duration;

@end


@implementation RPTraceDocument

@synthesize root;
@synthesize percentFormatter;
@synthesize displayTimeUnitAsPercentOfTotal;
@synthesize mainOutlineView;
@synthesize mainDocument;
@synthesize secretKey;

+ (NSArray *)defaultOutlineColumnList
{
	NSMutableArray *result;
	NSMutableArray *defaultValue;

	defaultValue = [[NSMutableArray alloc] initWithObjects:
			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Thread", @"title", @"thread", @"identifier", @52.0f, @"width", @NO, @"enabled", nil],
			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Total", @"title", @"totalTime", @"identifier", @101.0f, @"width", @YES, @"enabled", nil],
			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Self", @"title", @"selfTime", @"identifier", @61.0f, @"width", @YES, @"enabled", nil],
			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Tick count", @"title", @"tickCount", @"identifier", @52.0f, @"width", @NO, @"enabled", nil],
			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Blocked ticks", @"title", @"blockedTicks", @"identifier", @52.0f, @"width", @YES, @"enabled", nil],
			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"File", @"title", @"file", @"identifier", @232.0f, @"width", @NO, @"enabled", nil],
//			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Name Space", @"title", @"namespace", @"identifier", [NSNumber numberWithFloat:232], @"width", [NSNumber numberWithBool:YES], @"enabled", nil],
			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Symbol", @"title", @"symbol", @"identifier", @300.0f, @"width", @YES, @"enabled", nil],
			nil
		];
	result = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"columns"] mutableCopy];
	if (!result || ![result[0] isKindOfClass:[NSNumber class]] || [result[0] intValue] != COLUMN_INFO_VERSION) {
		result = defaultValue;
	} else {
		int ii, count;
		
		[result removeObjectAtIndex:0];
		count = [result count];
		for (ii = 0; ii < count; ii++) {
			NSMutableDictionary *column;
			
			column = [result[ii] mutableCopy];
			result[ii] = column;
		}
	}

	return result;
}

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
}

- (void)loadWithMainDocument:(RPTraceDocument *)document root:(RPCallTree *)newRoot version:(NSString *)newVersion
{
	self.mainDocument = document;
	self.root = newRoot;
	self.version = newVersion;
	self.interval = document.interval;
	self.url = document.url;
	self.duration = document.duration;
}

- (NSString *)windowNibName
{
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (void)setRoot:(RPCallTree *)newRoot
{
	if (newRoot != root) {
		root = newRoot;
		self.displayRoot = newRoot;
		if (root) {
	    	[mainOutlineView reloadData];
		}
	}
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	id<RPLogReader> reader = nil;
	
    if ([typeName isEqualToString:@"Ruby trace"]) {
		reader = [[RPRubyTraceLogReader alloc] initWithData:data];
	}
    
	self.root = [reader callTree];
	self.version = [reader version];
	self.url = [reader url];
	self.interval = [reader interval];
	self.duration = [reader duration];
	
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

- (void)_updateOutlineViewColumn
{
	int ii = 0;
	
	updatingColumns = YES;
	for (NSDictionary *info in columnInfo) {
		NSTableColumn *column;
		
		column = [mainOutlineView tableColumnWithIdentifier:info[@"identifier"]];
		if (!column && [info[@"enabled"] boolValue]) {
			column = [[NSTableColumn alloc] initWithIdentifier:info[@"identifier"]];
			[mainOutlineView addTableColumn:column];
		}
		if ([info[@"enabled"] boolValue]) {
			[mainOutlineView moveColumn:[mainOutlineView columnWithIdentifier:info[@"identifier"]] toColumn:ii];
			[column setWidth:[info[@"width"] floatValue]];
			[[column headerCell] setTitle:info[@"title"]];
			ii++;
		} else if (column) {
			[mainOutlineView removeTableColumn:column];
		}
	}
	updatingColumns = NO;
}

- (void)_saveColumnInfo
{
	NSMutableArray *copy;
	
	copy = [columnInfo mutableCopy];
	[copy insertObject:@COLUMN_INFO_VERSION atIndex:0];
	[[NSUserDefaults standardUserDefaults] setObject:copy forKey:@"columns"];
}

- (void)awakeFromNib
{
	[self updateTimeFormatter];
    if (self.mainDocument) {
    	[focusDownFunctionButton setHidden:YES];
    	[focusUpFunctionButton setHidden:YES];
    }
	[urlTextField setAction:@selector(urlTextFieldClicked:)];
	[totalTimeTextField setStringValue:[NSString stringWithFormat:@"%.2fs", self.root.totalTime]];
	[intervalTextField setStringValue:[NSString stringWithFormat:@"%.2fms", self.interval * 1000]];
	[realIntervalTextField setStringValue:[NSString stringWithFormat:@"%.2fms", (self.root.totalTime / self.root.sampleCount) * 1000]];
	[tickCountTextField setStringValue:[NSString stringWithFormat:@"%ld", self.root.sampleCount]];
	[stackCountTextField setStringValue:[NSString stringWithFormat:@"%ld", self.root.stackTraceCount]];
	[versionTextField setStringValue:self.version];
	[urlTextField setStringValue:self.url ? [self.url absoluteString] : @""];
    mainOutlineView.columnIdentifierForCopy = @"file";
	[mainOutlineView setDoubleAction:@selector(outlineDoubleAction:)];
	
	columnInfo = [[[self class] defaultOutlineColumnList] mutableCopy];
	[self _updateOutlineViewColumn];
}

- (void)updateTimeFormatter
{
	if (displayTimeUnitAsPercentOfTotal) {
		self.percentFormatter.multiplier = @(100.0 / self.displayRoot.totalTime);
		self.percentFormatter.positiveSuffix = @"%";
		self.percentFormatter.maximumFractionDigits = 2;

	} else {
		self.percentFormatter.multiplier = @1000.0;
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
                callTree = result[0];
                if (callTree.totalTime * 5 / 100 < callTree.selfTime) {
                	break;
                }
            } else {
            	NSMutableArray *significantChildren;
                NSInteger ii, count;
                
                significantChildren = [result mutableCopy];
                count = [significantChildren count];
                for (ii = 0; ii < count; ii++) {
                	RPCallTree *current = significantChildren[ii];
                    
                    if (callTree.totalTime * 5 / 100 > current.totalTime) {
                    	[significantChildren removeObjectAtIndex:ii];
                        count--;
                        ii--;
                    }
                }
                result = significantChildren;
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
		hottestNode = [self childrenForCallTree:hottestNode][0];
	}
}

- (IBAction)unfocusButtonAction:(id)sender
{
    if (self.displayRoot != self.root) {
	    RPCallTree *callTreeToSelect = nil;
		NSInteger selectedRow;
    	
	    selectedRow = [mainOutlineView selectedRow];
        if (selectedRow == -1) {
	        callTreeToSelect = self.displayRoot;
        } else {
        	callTreeToSelect = [mainOutlineView itemAtRow:selectedRow];
        }
    	self.displayRoot = self.root;
		[self updateTimeFormatter];
	    [mainOutlineView reloadData];
	    [self expandAndSelectCallTree:callTreeToSelect];
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
        callTreeToSelect = self.displayRoot;
    	self.displayRoot = self.root;
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
			newRoot = [self.root topDownCallTreeForSymbolId:selectedCallTree.symbolId];
		} else {
			newRoot = [self.root bottomUpCallTreeForSymbolId:selectedCallTree.symbolId];
		}
        if (self.mainDocument) {
			[newDocument loadWithMainDocument:self.mainDocument root:newRoot version:self.version];
        } else {
			[newDocument loadWithMainDocument:self root:newRoot version:self.version];
        }
		[[NSDocumentController sharedDocumentController] addDocument:newDocument];
		[newDocument makeWindowControllers];
		[newDocument showWindows];
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

- (IBAction)urlTextFieldClicked:(id)sender
{
	NSLog(@"test");
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (!item) {
    	item = self.displayRoot;
    }
    return [self childrenForCallTree:item][index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return [[self childrenForCallTree:item] count];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!item) {
    	item = self.displayRoot;
    }
	return [[self childrenForCallTree:item] count];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	id result = nil;
    
	if ([[tableColumn identifier] isEqualToString:@"thread"]) {
    	result = @([item thread]);
	} else if ([[tableColumn identifier] isEqualToString:@"totalTime"]) {
    	result = @([item totalTime]);
	} else if ([[tableColumn identifier] isEqualToString:@"selfTime"]) {
    	result = @([item selfTime]);
	} else if ([[tableColumn identifier] isEqualToString:@"tickCount"]) {
    	result = @([item sampleCount]);
	} else if ([[tableColumn identifier] isEqualToString:@"file"]) {
    	result = [item file];
	} else if ([[tableColumn identifier] isEqualToString:@"namespace"]) {
    	result = [item ns];
	} else if ([[tableColumn identifier] isEqualToString:@"symbol"]) {
    	result = [NSString stringWithFormat:@"%@::%@", [item ns], [item symbol]];
	} else if ([[tableColumn identifier] isEqualToString:@"blockedTicks"]) {
    	result = @([item blockedTicks]);
    }
    return result;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification;
{
	if ([mainOutlineView selectedRow] == -1) {
        [unfocusButton setEnabled:self.root != self.displayRoot];
        [focusButton setEnabled:NO];
        [focusDownFunctionButton setEnabled:NO];
        [focusUpFunctionButton setEnabled:NO];
        [hottestSubpathButton setEnabled:NO];
    } else {
        [unfocusButton setEnabled:self.root != self.displayRoot];
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

- (NSMenu *)headerMenuForTableView:(NSTableView *)tableView event:(NSEvent *)event
{
	NSMenu *result;
	NSInteger tag = 0;
	
	result = [[NSMenu alloc] init];
	[result setDelegate:self];
	for (NSDictionary *column in columnInfo) {
		NSMenuItem *item;
		
		item = [result addItemWithTitle:column[@"title"] action:@selector(headerMenuAction:) keyEquivalent:@""];
		[item setState:[column[@"enabled"] boolValue]?NSOnState:NSOffState];
		[item setTag:tag];
		if ([column[@"identifier"] isEqualToString:@"symbol"]) {
			[item setEnabled:NO];
		}
		tag++;
	}
	return result;
}

- (void)headerMenuAction:(NSMenuItem *)item
{
	NSMutableDictionary *info;
	
	info = columnInfo[[item tag]];
	info[@"enabled"] = [NSNumber numberWithBool:![info[@"enabled"] boolValue]];
	[self _updateOutlineViewColumn];
	[self _saveColumnInfo];
}

- (void)outlineViewColumnDidMove:(NSNotification *)notification
{
	if (!updatingColumns) {
		NSInteger newColumn = [[notification userInfo][@"NSNewColumn"] intValue];
		NSInteger oldColumn = [[notification userInfo][@"NSOldColumn"] intValue];
		NSDictionary *info;
		NSInteger ii = 0;
		
		for (info in columnInfo) {
			if (![info[@"enabled"] boolValue]) {
				if (ii <= newColumn) {
					newColumn++;
				}
				if (ii <= oldColumn) {
					oldColumn++;
				}
			}
			ii++;
		}
		info = columnInfo[oldColumn];
		[columnInfo removeObjectAtIndex:oldColumn];
		[columnInfo insertObject:info atIndex:newColumn];
		[self _saveColumnInfo];
	}
}

- (void)outlineViewColumnDidResize:(NSNotification *)notification
{
	if (!updatingColumns) {
		NSTableColumn *column;
		
		column = [notification userInfo][@"NSTableColumn"];
		for (NSMutableDictionary *info in columnInfo) {
			if ([info[@"identifier"] isEqualToString:[column identifier]]) {
				info[@"width"] = [NSNumber numberWithFloat:[column width]];
			}
		}
		[self _saveColumnInfo];
	}
}

- (BOOL)hideInsignificantCalls
{
	return hideInsignificantCalls;
}

@end
