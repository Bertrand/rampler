//
//  RPURLLoaderController.m
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import "RPURLLoaderController.h"
#import "RPApplicationDelegate.h"
#import "RPApplication.h"
#import "NSURLAdditions.h"
#import "RPKeychainWrapper.h"

#define MAX_RECENT_URLS 30 // the number of URLs we keep in history


@interface RPURLLoaderController()
    @property(nonatomic, readwrite, assign) BOOL isLoadingURL;
- (NSURL*)samplinglURL;
- (void)updateDefaultsFromCurrentValues;
@end 

@implementation RPURLLoaderController

    @synthesize compressed = _compressed;
    @synthesize fileName = _fileName;
    @synthesize openURLWindow;
    @synthesize progressWindow;
    @synthesize samplingInterval;
    @synthesize urlString;
    @synthesize isLoadingURL;

    @dynamic secretKey;


- (id) init
{
    id me = [super init];
    [self updateCurrentValuesFromDefault];
    self.isLoadingURL = NO;
    return me; 
}

- (void)dealloc
{
	[_fileHandle release];
	[_connection release];
	[_fileName release];
    self.openURLWindow = nil;
    
	[super dealloc];
}

- (NSString*)secretKey
{
    return _secretKey; 
}

- (void)setSecretKey:(NSString *)newSecretKey
{
    if (![newSecretKey isEqual:_secretKey]) {
        [newSecretKey retain];
        [_secretKey release];
        _secretKey = newSecretKey; 
        
        [self setDefaultSecretKey:newSecretKey];
    }
}

- (NSURL*)baseURL
{
    NSString* s = self.urlString;
    if (s == nil) return nil; 
    if (!([s hasPrefix:@"http://"] || [s hasPrefix:@"https://"])) {
        s = [NSString stringWithFormat:@"http://%@", s];
    }
    
    return [NSURL URLWithString:s];
}

- (NSURL*)samplinglURL
{
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            self.samplingInterval, @"interval", 
                            @"true", @"ruby_sanspleur", 
                            nil];
    return [[self baseURL] rp_URLByAppendingQuery:params];
}

- (BOOL)start
{
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef string = CFUUIDCreateString(NULL, theUUID);
	NSString *realFilename;
	NSAssert(_connection == nil, @"Should have no connection");
		
	_fileName = [[@"/tmp/" stringByAppendingPathComponent:[(NSString *)string stringByAppendingPathExtension:@"rubytrace"]] retain];
	if (_compressed) {
		realFilename = [_fileName stringByAppendingPathExtension:@"gz"];
	} else {
		realFilename = _fileName;
	}
	_fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:open([realFilename UTF8String], O_CREAT | O_WRONLY, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH) closeOnDealloc:YES];
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[self samplinglURL]];
	
	NSDictionary* httpHeaders = [(RPApplication*)[RPApplication sharedApplication] additionalHTTPHeaders];
	for (NSString* key in httpHeaders) {
		[request addValue:[httpHeaders objectForKey:key] forHTTPHeaderField:key];
	}
	_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    self.isLoadingURL = YES; 
    	
	CFRelease(string);
	CFRelease(theUUID);
	return YES;
}



- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_fileHandle writeData:data];
}

- (void)_close
{
	[_fileHandle closeFile];
	[_fileHandle release];
	_fileHandle = nil;
	[_fileHandle closeFile];
	[_fileHandle release];
	_fileHandle = nil;
	[_window close];
	[_window release];
	_window = nil;
}


- (void)_downloadFailed
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:@"No data"];
	[alert setInformativeText:[[self baseURL] absoluteString]];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)_downloadSucceed
{
	//[[NSApp delegate] urlLoaderControllerDidFinish:self];
	[self _close];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (_compressed) {
		if ([[[[NSFileManager defaultManager] attributesOfItemAtPath:[_fileName stringByAppendingPathExtension:@"gz"] error:nil] objectForKey:NSFileSize] longLongValue] < 100) {
			[self _downloadFailed];
		} else {
			system([[NSString stringWithFormat:@"gunzip %@", [_fileName stringByAppendingPathExtension:@"gz"]] UTF8String]);
			[self _downloadSucceed];
		}
	} else {
		if ([[[[NSFileManager defaultManager] attributesOfItemAtPath:_fileName error:nil] objectForKey:NSFileSize] longLongValue] < 100) {
			[self _downloadFailed];
		} else {
			[self _downloadSucceed];
		}
	}
    
    self.isLoadingURL = NO; 

    [_connection release];
    _connection = nil; 
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:@"Error while loading the stack trace"];
	[alert setInformativeText:[NSString stringWithFormat:@"%@ %@", error, [error userInfo]]];
	[alert setAlertStyle:NSWarningAlertStyle];
	[error retain];
	[alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:error];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)error
{
	[self _close];
	//[[NSApp delegate] urlLoaderController:self didFailWithError:error];
	[(id)error release];
}


// open Url dialog

- (void) openOpenURLDialog:(id)sender
{
    if (!_openURLNibLoaded) {
        _openURLNibLoaded = [NSBundle loadNibNamed:@"RPURLLoaderOpenDialog" owner:self];
        NSAssert(_openURLNibLoaded, @"unable to open RPURLLoaderOpenDialog nil");
    }
    
    _urlOpenerSession = [[NSApplication sharedApplication] beginModalSessionForWindow:self.openURLWindow];
    [[NSApplication sharedApplication] runModalSession:_urlOpenerSession];

}

- (void) closeOpenURLDialog:(id)sender
{
	[[NSApplication sharedApplication] endModalSession:_urlOpenerSession];
	[self.openURLWindow orderOut:sender];
}

- (IBAction)openDialogCloseButtonClicked:(id)sender
{
    [self closeOpenURLDialog:sender];
}

- (IBAction)openDialogActionButtonClicked:(id)sender
{
    [self commitEditing];
    [self closeOpenURLDialog:sender];
    [self.openURLWindow orderOut:nil];
    [self updateDefaultsFromCurrentValues];
    [self start];
}

#pragma mark -
#pragma mark Defaults 

- (NSArray*)recentURLStrings
{
	return [[NSUserDefaults standardUserDefaults] stringArrayForKey:@"recentURLStrings"];
}

- (void)setRecentURLStrings:(NSArray*)urlStrings
{
    return [[NSUserDefaults standardUserDefaults] setObject:urlStrings forKey:@"recentURLStrings"];
}

- (void)addURLStringToRecentURLStrings:(NSString*)newURLString
{
    NSArray* oldRecentURLStrings = self.recentURLStrings;
    NSMutableArray* newRecentURLStrings = [[NSMutableArray alloc] init];
    
    [newRecentURLStrings addObject:newURLString];
    for (NSString* recentURLString in oldRecentURLStrings) {
        if (![recentURLString isEqual:newURLString]) [newRecentURLStrings addObject:recentURLString];
        if ([newRecentURLStrings count] > MAX_RECENT_URLS) break; 
    }
    [self setRecentURLStrings:newRecentURLStrings];
    [newRecentURLStrings release];
}

- (NSString*)defaultSecretKey
{
    return [RPKeychainWrapper internetPasswordForServiceName:@"com.fotonauts.ruby-sanspleur" accountName:@"secret-key"];
}

- (void) setDefaultSecretKey:(NSString*)newSecretKey
{
    return [RPKeychainWrapper setInternetPassword:newSecretKey forServiceName:@"com.fotonauts.ruby-sanspleur" accountName:@"secret-key"];
}

- (NSNumber*)defaultSamplingInterval
{	
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultSamplingInterval"];
}

- (void)setDefaultSamplingInterval:(NSNumber*)interval
{
	[[NSUserDefaults standardUserDefaults] setObject:interval forKey:@"defaultSamplingInterval"];
}

- (void) updateDefaultsFromCurrentValues
{
    [self addURLStringToRecentURLStrings:self.urlString];
    [self setDefaultSamplingInterval:self.samplingInterval];
}

- (void)updateCurrentValuesFromDefault
{
    self.urlString = [[self recentURLStrings] objectAtIndex:0];
    self.samplingInterval = [self defaultSamplingInterval];
    self.secretKey = [self defaultSecretKey];
}


@end
