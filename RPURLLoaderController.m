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
#import "RPSha1Signer.h"

#define MAX_RECENT_URLS 30 // the number of URLs we keep in history

#define INTERVAL_PARAMETER_NAME @"ruby_sanspleur_interval" 
#define TIMEOUT_PARAMETER_NAME @"ruby_sanspleur_timeout" 
#define UUID_PARAMETER_NAME @"ruby_sanspleur_uuid" 
#define ACTIVATE_SAMPLING_PARAMETER_NAME @"ruby_sanspleur"

#define REQUEST_SIGNATURE_HEADER @"X-RUBY-SANSPLEUR-SIGNATURE"


@interface RPURLLoaderController()
    @property(nonatomic, readwrite, assign) BOOL isLoadingURL;
- (NSURL*)samplinglURL;
- (void)updateDefaultsFromCurrentValues;
@end 

@implementation RPURLLoaderController

    @synthesize fileName = _fileName;
    @synthesize openURLWindow;
    @synthesize progressWindow;
    @synthesize samplingInterval;
    @synthesize samplingTimeout;
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
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef UUIDString = CFUUIDCreateString(NULL, theUUID);
    
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            self.samplingInterval,  INTERVAL_PARAMETER_NAME, 
                            @"true",                ACTIVATE_SAMPLING_PARAMETER_NAME, 
                            UUIDString,             UUID_PARAMETER_NAME,
                            nil];
    if ([self.samplingTimeout intValue] > 0) {
        [params setObject:self.samplingTimeout forKey:TIMEOUT_PARAMETER_NAME];
    }
    return [[self baseURL] rp_URLByAppendingQuery:params];
}

- (BOOL)start
{
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef uuidString = CFUUIDCreateString(NULL, theUUID);
	NSAssert(_connection == nil, @"Should have no connection");
		
	_fileName = [[@"/tmp/" stringByAppendingPathComponent:[(NSString *)uuidString stringByAppendingPathExtension:@"rubytrace"]] retain];	
	_fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:open([_fileName UTF8String], O_CREAT | O_WRONLY, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH) closeOnDealloc:YES];
	
    NSURL* samplingURL = [self samplinglURL]; 
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:samplingURL];
	
	NSDictionary* httpHeaders = [(RPApplication*)[RPApplication sharedApplication] additionalHTTPHeaders];
	for (NSString* key in httpHeaders) {
		[request addValue:[httpHeaders objectForKey:key] forHTTPHeaderField:key];
	}
    
    if (self.secretKey) {
        RPSha1Signer* signer = [[RPSha1Signer alloc] init];
        signer.dataString = [samplingURL absoluteString];
        signer.keyHexString = self.secretKey;
        NSString* signature = signer.signatureHexString;
        [signer release];
        if (signature) {
            [request addValue:signature forHTTPHeaderField:REQUEST_SIGNATURE_HEADER];
        } else {
            NSLog(@"WARNING: unable to compute signature.");
        }
    }
    
	_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    self.isLoadingURL = YES; 
    	
	CFRelease(uuidString);
	CFRelease(theUUID);
	return YES;
}




- (void)_close
{
    self.isLoadingURL = NO; 
    _httpStatusCode = -1;
    
	[_fileHandle release];
	_fileHandle = nil;
        
    [_connection release];
    _connection = nil; 
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse*)response
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    _httpStatusCode = [httpResponse statusCode];
    NSLog(@"response status code : %ld", _httpStatusCode);
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_fileHandle writeData:data];
}

- (void)_downloadFailed
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:@"Request returned no sampling data"];
	[alert setInformativeText:[[self baseURL] absoluteString]];
	[alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
}

- (void)_downloadSucceed
{
	[[NSWorkspace sharedWorkspace] openFile:self.fileName];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    BOOL httpFailure = _httpStatusCode >= 400; 
    if (httpFailure || [[[[NSFileManager defaultManager] attributesOfItemAtPath:_fileName error:nil] objectForKey:NSFileSize] longLongValue] < 100) {
        [self _downloadFailed];
    } else {
        [self _downloadSucceed];
    }

    [self _close];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self _downloadFailed];
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:@"Error while loading the sampling data"];
	[alert setInformativeText:[NSString stringWithFormat:@"%@ %@", error, [error userInfo]]];
	[alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal]; 
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
