//
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import "NSURLAdditions.h"


#pragma mark -
#pragma mark NSString Additions

@interface NSString(RamplerURL)
- (NSString *)URLEncodedString;
@end

@implementation NSString(RamplerURL)
- (NSString *)URLEncodedString
{
	CFStringRef result = CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)self, NULL, (CFStringRef)@" !*'\"();:@&=+$,/?%#[]%", kCFStringEncodingUTF8);

    return CFBridgingRelease(result);
}
@end


#pragma mark -
#pragma mark NSURL Additions

@interface NSURL(RamplerPrivate)
- (NSDictionary*)rp_queryDictionaryFromString:(NSString*)string;
@end

@implementation NSURL (DooLittle)

+ (NSString*)queryStringForParameters:(NSDictionary*)parameters
{
    BOOL  first = YES;
    NSMutableString*   queryString = [NSMutableString string];
    NSArray* keys = [[parameters allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for (NSString* key in keys){
        if (first) {
            first = NO;
            [queryString appendString:@"?"];
        }
        else {
            [queryString appendString:@"&"];
        }
        
        NSObject* val = parameters[key];
        [queryString appendString:[key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
        [queryString appendString:@"="];
        [queryString appendString:[[val description] URLEncodedString]];
    }
    
    return queryString;
}

- (NSDictionary*)rp_queryDictionary 
{
    return [self rp_queryDictionaryFromString:[self query]];
}

- (NSURL*) rp_URLByAppendingQuery: (NSDictionary*)query
{
    NSMutableString* path = [[self path] mutableCopy];
    if (path.length == 0) [path appendString:@"/"]; // normalize URL for signing.
    
    NSString* previousQuery = [[self query] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    BOOL first = YES;
    if (previousQuery && [previousQuery length] > 0) {
        // there is already a query. Unless proven necessary, we don't parse it and we just append the query dict to the url
        first = NO;
        [path appendString:@"?"];
        [path appendString:previousQuery];
    }
    NSArray* keys = [[query allKeys] sortedArrayUsingSelector:@selector(compare:)]; // using predictible order avoids misses in stupid caches
    for (NSString* key in keys){
        if (first) {
            first = NO;
            [path appendString:@"?"];
        }
        else {
            [path appendString:@"&"];
        }
        
        NSObject* val = query[key];
        [path appendString:[key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
        [path appendString:@"="];
        [path appendString:[[val description] URLEncodedString]];
    }
    
    NSString* portString = [self port] ? [NSString stringWithFormat:@":%@", [self port]] : @"";
    NSString* urlString = [NSString stringWithFormat:@"%@://%@%@%@", [self scheme], [self host], portString, path]; // we forge the string ourselves to avoid very stupid NSURL encoding issues
    NSURL* result = [NSURL URLWithString:urlString];
    
    return result;
}

- (NSURL*)rp_URLByAppendingQueryValue:(NSString*)value forKey:(NSString*)queryKey
{
    return  [self rp_URLByAppendingQuery:@{queryKey: value}];
}


@end


@implementation NSURL(RamplerPrivate)

// adapted from http://cocoadev.com/index.pl?URLParsing

- (NSDictionary*)rp_queryDictionaryFromString:(NSString*)string 
{
    NSCharacterSet* delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@"&;?"] ;
    NSMutableDictionary* pairs = [NSMutableDictionary dictionary] ;
    NSScanner* scanner = [[NSScanner alloc] initWithString:string] ;
    while (![scanner isAtEnd]) {
        NSString* pairString ;
        [scanner scanUpToCharactersFromSet:delimiterSet
                                intoString:&pairString] ;
        [scanner scanCharactersFromSet:delimiterSet intoString:NULL] ;
        NSArray* kvPair = [pairString componentsSeparatedByString:@"="] ;
        if ([kvPair count] == 2) {
            NSString* key = [kvPair[0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ;
            NSString* value = [kvPair[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ;
            pairs[key] = value ;
        }
    }

    return [NSDictionary dictionaryWithDictionary:pairs] ;
}

@end