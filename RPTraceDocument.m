//
//  MyDocument.m
//  Rampler
//
//  Created by Guiheneuf Bertrand on 9/29/10.
//  Copyright 2010 Fotonauts. All rights reserved.
//

#import "RPTraceDocument.h"
#import "RPCallTree.h"
#import "RPLogReader.h"



@implementation RPTraceDocument

@synthesize root;
@synthesize percentFormatter;
@synthesize displayTimeUnitAsPercentOfTotal;
@synthesize mainOutlineView;



- (id)init
{
    self = [super init];
    if (self) {
    
    }
    return self;
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

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	RPLogReader* reader = [[RPLogReader alloc] initWithData:data];
	
	root = [[RPCallTree alloc] init];
	[root feedFromLogReader:reader];
	[root freeze];
	[reader release];
	
	self.displayTimeUnitAsPercentOfTotal = YES;

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
	
}

- (void)awakeFromNib
{
	[self updateTimeFormatter];
}

- (void)updateTimeFormatter
{
	if (displayTimeUnitAsPercentOfTotal) {
		self.percentFormatter.multiplier = [NSNumber numberWithDouble:100.0 / root.totalTime];
		self.percentFormatter.positiveSuffix = @"%";
		self.percentFormatter.maximumFractionDigits = 2;

	} else {
		self.percentFormatter.multiplier = [NSNumber numberWithDouble:1.0 / 1000.0];
		self.percentFormatter.positiveSuffix = @"ms";
		self.percentFormatter.maximumFractionDigits = 2;
	}
	
	[self.mainOutlineView reloadData];
	[self.mainOutlineView setNeedsDisplay];
}


- (IBAction) followHottestSubpath:(id)sender
{
	NSInteger selelectedRow = [self.mainOutlineView selectedRow];
	NSTreeNode* selectedNode = [self.mainOutlineView itemAtRow:selelectedRow];
	//NSLog(@"selected item : %@", selectedNode);
	
	NSTreeNode* hottestNode = selectedNode;
	while ([hottestNode.childNodes count] > 0) {
		[self.mainOutlineView expandItem:hottestNode];
		hottestNode = [hottestNode.childNodes objectAtIndex:0];
	}

}

@end
