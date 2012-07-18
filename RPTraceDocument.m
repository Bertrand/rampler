//
//  MyDocument.m
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import "RPTraceDocument.h"
#import "RPCallTree.h"
#import "RPDTraceLogReader.h"
#import "RPRubyTraceLogReader.h"
#import "RPOutlineView.h"
#import "RPTableHeaderView.h"

#define COLUMN_INFO_VERSION 5

@interface RPTraceDocument()

@property (nonatomic, retain) RPCallTree* root;
@property (nonatomic, retain) RPCallTree* displayRoot;
@property (nonatomic, assign) RPOutlineView* mainOutlineView;;
@property (nonatomic, retain) RPTraceDocument *mainDocument;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSURL* url;
@property (nonatomic, assign) double interval;
@property (nonatomic, assign) double duration;

@end


@implementation RPTraceDocument

@synthesize root, displayRoot;
@synthesize percentFormatter;
@synthesize displayTimeUnitAsPercentOfTotal;
@synthesize mainOutlineView;
@synthesize mainDocument;
@synthesize version;
@synthesize url;
@synthesize secretKey;
@synthesize interval;
@synthesize duration;

+ (NSArray *)defaultOutlineColumnList
{
	NSMutableArray *result;
	NSMutableArray *defaultValue;

	defaultValue = [[NSMutableArray alloc] initWithObjects:
			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Thread", @"title", @"thread", @"identifier", [NSNumber numberWithFloat:52], @"width", [NSNumber numberWithBool:NO], @"enabled", nil],
			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Total", @"title", @"totalTime", @"identifier", [NSNumber numberWithFloat:101], @"width", [NSNumber numberWithBool:YES], @"enabled", nil],
			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Self", @"title", @"selfTime", @"identifier", [NSNumber numberWithFloat:61], @"width", [NSNumber numberWithBool:YES], @"enabled", nil],
			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Tick count", @"title", @"tickCount", @"identifier", [NSNumber numberWithFloat:52], @"width", [NSNumber numberWithBool:NO], @"enabled", nil],
			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Blocked ticks", @"title", @"blockedTicks", @"identifier", [NSNumber numberWithFloat:52], @"width", [NSNumber numberWithBool:YES], @"enabled", nil],
			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"File", @"title", @"file", @"identifier", [NSNumber numberWithFloat:232], @"width", [NSNumber numberWithBool:NO], @"enabled", nil],
//			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Name Space", @"title", @"namespace", @"identifier", [NSNumber numberWithFloat:232], @"width", [NSNumber numberWithBool:YES], @"enabled", nil],
			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Symbol", @"title", @"symbol", @"identifier", [NSNumber numberWithFloat:300], @"width", [NSNumber numberWithBool:YES], @"enabled", nil],
			nil
		];
	result = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"columns"] mutableCopy];
	if (!result || ![[result objectAtIndex:0] isKindOfClass:[NSNumber class]] || [[result objectAtIndex:0] intValue] != COLUMN_INFO_VERSION) {
		[result release];
		result = [[defaultValue retain] autorelease];
	} else {
		int ii, count;
		
		[result removeObjectAtIndex:0];
		count = [result count];
		for (ii = 0; ii < count; ii++) {
			NSMutableDictionary *column;
			
			column = [[result objectAtIndex:ii] mutableCopy];
			[result replaceObjectAtIndex:ii withObject:column];
			[column release];
		}
	}
	[defaultValue release];

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
	self.duration = document.duration;
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
	self.duration = [reader duration];
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

- (void)_updateOutlineViewColumn
{
	int ii = 0;
	
	updatingColumns = YES;
	for (NSDictionary *info in columnInfo) {
		NSTableColumn *column;
		
		column = [mainOutlineView tableColumnWithIdentifier:[info objectForKey:@"identifier"]];
		if (!column && [[info objectForKey:@"enabled"] boolValue]) {
			column = [[NSTableColumn alloc] initWithIdentifier:[info objectForKey:@"identifier"]];
			[mainOutlineView addTableColumn:column];
			[column release];
		}
		if ([[info objectForKey:@"enabled"] boolValue]) {
			[mainOutlineView moveColumn:[mainOutlineView columnWithIdentifier:[info objectForKey:@"identifier"]] toColumn:ii];
			[column setWidth:[[info objectForKey:@"width"] floatValue]];
			[[column headerCell] setTitle:[info objectForKey:@"title"]];
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
	[copy insertObject:[NSNumber numberWithInt:COLUMN_INFO_VERSION] atIndex:0];
	[[NSUserDefaults standardUserDefaults] setObject:copy forKey:@"columns"];
	[copy release];
}

- (void)awakeFromNib
{
	[self updateTimeFormatter];
    if (self.mainDocument) {
    	[focusDownFunctionButton setHidden:YES];
    	[focusUpFunctionButton setHidden:YES];
    }
	[urlTextField setAction:@selector(urlTextFieldClicked:)];
	[totalTimeTextField setStringValue:[NSString stringWithFormat:@"%.2fs", root.totalTime]];
	[intervalTextField setStringValue:[NSString stringWithFormat:@"%.2fms", self.interval * 1000]];
	[realIntervalTextField setStringValue:[NSString stringWithFormat:@"%.2fms", (root.totalTime / root.sampleCount) * 1000]];
	[tickCountTextField setStringValue:[NSString stringWithFormat:@"%d", root.sampleCount]];
	[stackCountTextField setStringValue:[NSString stringWithFormat:@"%d", root.stackTraceCount]];
	[versionTextField setStringValue:self.version];
	[urlTextField setStringValue:[self.url absoluteString]];
    mainOutlineView.columnIdentifierForCopy = @"file";
	[mainOutlineView setDoubleAction:@selector(outlineDoubleAction:)];
	
	columnInfo = [[[self class] defaultOutlineColumnList] mutableCopy];
	[self _updateOutlineViewColumn];
}

- (void)updateTimeFormatter
{
	if (displayTimeUnitAsPercentOfTotal) {
		self.percentFormatter.multiplier = [NSNumber numberWithDouble:100.0 / displayRoot.totalTime];
		self.percentFormatter.positiveSuffix = @"%";
		self.percentFormatter.maximumFractionDigits = 2;

	} else {
		self.percentFormatter.multiplier = [NSNumber numberWithDouble:1000.0];
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

- (IBAction)unfocusButtonAction:(id)sender
{
    if (self.displayRoot != root) {
	    RPCallTree *callTreeToSelect = nil;
		NSInteger selectedRow;
    	
	    selectedRow = [mainOutlineView selectedRow];
        if (selectedRow == -1) {
	        callTreeToSelect = displayRoot;
        } else {
        	callTreeToSelect = [mainOutlineView itemAtRow:selectedRow];
        }
    	self.displayRoot = root;
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

- (IBAction)urlTextFieldClicked:(id)sender
{
	NSLog(@"test");
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
    	result = [NSNumber numberWithDouble:[item totalTime]];
	} else if ([[tableColumn identifier] isEqualToString:@"selfTime"]) {
    	result = [NSNumber numberWithDouble:[item selfTime]];
	} else if ([[tableColumn identifier] isEqualToString:@"tickCount"]) {
    	result = [NSNumber numberWithInteger:[item sampleCount]];
	} else if ([[tableColumn identifier] isEqualToString:@"file"]) {
    	result = [item file];
	} else if ([[tableColumn identifier] isEqualToString:@"namespace"]) {
    	result = [item ns];
	} else if ([[tableColumn identifier] isEqualToString:@"symbol"]) {
    	result = [NSString stringWithFormat:@"%@::%@", [item ns], [item symbol]];
	} else if ([[tableColumn identifier] isEqualToString:@"blockedTicks"]) {
    	result = [NSNumber numberWithInteger:[item blockedTicks]];
    }
    return result;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification;
{
	if ([mainOutlineView selectedRow] == -1) {
        [unfocusButton setEnabled:root != displayRoot];
        [focusButton setEnabled:NO];
        [focusDownFunctionButton setEnabled:NO];
        [focusUpFunctionButton setEnabled:NO];
        [hottestSubpathButton setEnabled:NO];
    } else {
        [unfocusButton setEnabled:root != displayRoot];
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
		
		item = [result addItemWithTitle:[column objectForKey:@"title"] action:@selector(headerMenuAction:) keyEquivalent:@""];
		[item setState:[[column objectForKey:@"enabled"] boolValue]?NSOnState:NSOffState];
		[item setTag:tag];
		if ([[column objectForKey:@"identifier"] isEqualToString:@"symbol"]) {
			[item setEnabled:NO];
		}
		tag++;
	}
	return [result autorelease];
}

- (void)headerMenuAction:(NSMenuItem *)item
{
	NSMutableDictionary *info;
	
	info = [columnInfo objectAtIndex:[item tag]];
	[info setObject:[NSNumber numberWithBool:![[info objectForKey:@"enabled"] boolValue]] forKey:@"enabled"];
	[self _updateOutlineViewColumn];
	[self _saveColumnInfo];
}

- (void)outlineViewColumnDidMove:(NSNotification *)notification
{
	if (!updatingColumns) {
		NSInteger newColumn = [[[notification userInfo] objectForKey:@"NSNewColumn"] intValue];
		NSInteger oldColumn = [[[notification userInfo] objectForKey:@"NSOldColumn"] intValue];
		NSDictionary *info;
		NSInteger ii = 0;
		
		for (info in columnInfo) {
			if (![[info objectForKey:@"enabled"] boolValue]) {
				if (ii <= newColumn) {
					newColumn++;
				}
				if (ii <= oldColumn) {
					oldColumn++;
				}
			}
			ii++;
		}
		info = [[columnInfo objectAtIndex:oldColumn] retain];
		[columnInfo removeObjectAtIndex:oldColumn];
		[columnInfo insertObject:info atIndex:newColumn];
		[info release];
		[self _saveColumnInfo];
	}
}

- (void)outlineViewColumnDidResize:(NSNotification *)notification
{
	if (!updatingColumns) {
		NSTableColumn *column;
		
		column = [[notification userInfo] objectForKey:@"NSTableColumn"];
		for (NSMutableDictionary *info in columnInfo) {
			if ([[info objectForKey:@"identifier"] isEqualToString:[column identifier]]) {
				[info setObject:[NSNumber numberWithFloat:[column width]] forKey:@"width"];
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
