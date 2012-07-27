
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

- (void)exportAsSampleToFile:(NSURL*)url
{
    NSError* e = nil;
    NSMutableString* buffer = [NSMutableString new];
    [buffer appendString:
     @"Sampling process 83676 for 3 seconds with 1 millisecond of run time between samples\n"
     "Sampling completed, processing symbols...\n"
     "Analysis of sampling Google Chrome (pid 83676) every 1 millisecond\n"
     "            Process:         Google Chrome [83676]\n"
     "               Path:            /MesApps/Google Chrome.app/Contents/MacOS/Google Chrome\n"
     "Load Address:    0xc1000\n"
     "         Identifier:      com.google.Chrome\n"
     "            Version:         20.0.1132.57 (1132.57)\n"
     "Code Type:       X86 (Native)\n"
     "Parent Process:  launchd [67629]\n"
     "\n"
     "Date/Time:       2012-07-27 10:56:26.981 +0200\n"
     "OS Version:      Mac OS X 10.7.4 (11E53)\n"
     "Report Version:  7\n"
     "\n"
     "Call graph:\n"
     
     ];
    [self.root _exportToBuffer:buffer indendation:0];
    [buffer appendString:
     @"\n"
     "Total number in stack (recursive counted multiple, when >=5):\n"
     "27       _pthread_start  (in libsystem_c.dylib) + 335  [0x9b299ed9]\n"
     "27       thread_start  (in libsystem_c.dylib) + 34  [0x9b29d6de]\n"
     "25       ChromeMain  (in Google Chrome Framework) + 9926026  [0xa3ef0a]\n"
     "18       ChromeMain  (in Google Chrome Framework) + 9793532  [0xa1e97c]\n"
     "17       ChromeMain  (in Google Chrome Framework) + 9938289  [0xa41ef1]\n"
     "17       ChromeMain  (in Google Chrome Framework) + 9938423  [0xa41f77]\n"
     "17       __psynch_cvwait  (in libsystem_kernel.dylib) + 0  [0x905eb834]\n"
     "17       _pthread_cond_wait  (in libsystem_c.dylib) + 827  [0x9b29de21]\n"
     "10       ChromeMain  (in Google Chrome Framework) + 9905240  [0xa39dd8]\n"
     "10       pthread_cond_wait$UNIX2003  (in libsystem_c.dylib) + 71  [0x9b24e42c]\n"
     "8       ChromeMain  (in Google Chrome Framework) + 9806428  [0xa21bdc]\n"
     "8       ChromeMain  (in Google Chrome Framework) + 9906182  [0xa3a186]\n"
     "8       ChromeMain  (in Google Chrome Framework) + 9906443  [0xa3a28b]\n"
     "8       mach_msg  (in libsystem_kernel.dylib) + 70  [0x905e91f6]\n"
     "8       mach_msg_trap  (in libsystem_kernel.dylib) + 0  [0x905e9c18]\n"
     "7       ChromeMain  (in Google Chrome Framework) + 9905463  [0xa39eb7]\n"
     "7       pthread_cond_timedwait$UNIX2003  (in libsystem_c.dylib) + 70  [0x9b24e3e0]\n"
     "\n"
     "Sort by top of stack, same collapsed (when >= 5):\n"
     "__psynch_cvwait  (in libsystem_kernel.dylib)        44523\n"
     "mach_msg_trap  (in libsystem_kernel.dylib)        18326\n"
     "kevent  (in libsystem_kernel.dylib)        10473\n"
     "__read  (in libsystem_kernel.dylib)        2619\n"
     "\n"
     "Binary Images:\n"
     "0xc1000 -    0xc1ff7 +com.google.Chrome (20.0.1132.57 - 1132.57) <681AF636-91E2-6FB2-E17F-BF8BBE452DE4> /MesApps/Google Chrome.app/Contents/MacOS/Google Chrome\n"
     "0xc5000 -  0x365af03 +com.google.Chrome.framework (20.0.1132.57 - 1132.57) <64A660CA-DD92-DEB3-8CA4-3C069EACB0E7> /MesApps/Google Chrome.app/Contents/Versions/20.0.1132.57/Google Chrome Framework.framework/Google Chrome Framework\n"
     "\n"
     ];
    if (![buffer writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&e]){
        [[NSAlert alertWithError:e] runModal];
    }
}
#pragma mark -
#pragma mark IBAction

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

- (IBAction)exportSample:(id)sender
{
    NSSavePanel* panel = [NSSavePanel savePanel];
    [panel beginWithCompletionHandler:^(NSInteger click){
        if (NSFileHandlingPanelOKButton == click) {
            NSURL* url = [panel URL];
            NSLog(@"got url = %@", url);
            [self exportAsSampleToFile:url];
        }
    }];
}


#pragma mark -
#pragma mark Outline view delegation

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
