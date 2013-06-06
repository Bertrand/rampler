//
//  RPRubyTraceLogReader.m
//  Rampler
//
//  Copyright 2010-2012 Fotonauts. All rights reserved.
//

#import "RPRubyTraceLogReader.h"
#import "RPCallTree.h"
#import "RPSampleSession.h"
#import "RPStackTrace.h"


static NSString* kTabSeparator = @"\t";
static NSString* kTracesStartMarker = @"-- Traces --";
static NSString* kFileIndexStartMarker = @"-- File Index --";
static NSString* kClassIndexStartMarker = @"-- Class Index --";
static NSString* kFunctionIndexStartMarker = @"-- Function Index --";
static NSString* kFooterStartMarker = @"-- Footer --";
static NSString* kEmptyLine = @"";

NSString* RPRubyTraceErrorDomain = @"RPRubyTraceErrorDomain";
NSInteger RPRubyTraceParseError = -1;

@interface RPRubyTraceLogReader ()
@property(nonatomic) NSMutableArray* stacks;
@property(nonatomic) NSArray* filesIndex;
@property(nonatomic) NSArray* classesIndex;
@property(nonatomic) NSArray* functionsIndex;

@property(nonatomic) NSString* version;
@property(nonatomic) NSURL* url;
@property(nonatomic, assign)double interval;
@property (nonatomic) NSString *beginningInfoDescription;
@property (nonatomic) NSString *endingInfoDescription;
@property (nonatomic) NSDate* startDate;
@property (nonatomic, assign) double duration;
@property (nonatomic, assign) NSUInteger sampleCount;
@end


@implementation RPRubyTraceLogReader

@synthesize beginningInfoDescription;
@synthesize endingInfoDescription;


- (id) initWithData:(NSData*)d
{
	self = [super init]; 
	self.data = d;
    
	self.stacks = [[NSMutableArray alloc] init];
    self.beginningInfoDescription = [[NSMutableString alloc] init];
	self.endingInfoDescription = [[NSMutableString alloc] init];
	BOOL dataOK = [self readData];
	if (!dataOK && self.parseError) {
        [[NSAlert alertWithError:self.parseError] runModal];
    }
	return self;
}


- (NSString*)readNextLine
{
    NSInteger dataLength = [self.data length];
    if (_currentPosition >= dataLength) return nil;

    NSInteger eolPos = _currentPosition;
    const UInt8* bytes = [self.data bytes];
    
    while ((eolPos < dataLength) && (bytes[eolPos] != '\n')) ++eolPos;
    NSString* line = [[NSString alloc] initWithData:[self.data subdataWithRange:NSMakeRange(_currentPosition, eolPos - _currentPosition)] encoding:NSUTF8StringEncoding];

    _currentPosition = eolPos + 1;
    return line;
}

#define THROW_ON_PARSE_ERROR 0

#define _PARSE_ASSERT(__boolValue__, __reasonString__, __return_value__, __throw__) if (!(__boolValue__)) { \
    self.parseError = [NSError errorWithDomain:RPRubyTraceErrorDomain code:RPRubyTraceParseError userInfo:@{NSLocalizedDescriptionKey : (__reasonString__)}];\
    if (__throw__) { \
        NSAssert(NO, (__reasonString__));\
    } \
    return NO;\
}
#define PARSE_ASSERT(__boolValue__, __reasonString__, __return_value__) _PARSE_ASSERT(__boolValue__, __reasonString__, __return_value__, THROW_ON_PARSE_ERROR)


#define _ASSERT_CURRENT_LINE(__expected_line__, __return_value__, __throw__) if (![(__expected_line__) isEqualToString:curLine]) { \
    NSString* errorString = [NSString stringWithFormat:@"expecting '%@' in file. Found '%@'.", (__expected_line__), curLine]; \
    self.parseError = [NSError errorWithDomain:RPRubyTraceErrorDomain code:RPRubyTraceParseError userInfo:@{NSLocalizedDescriptionKey : errorString}];\
    if (__throw__) { \
        NSAssert(NO, (errorString));\
    } \
    return NO; \
}
#define ASSERT_CURRENT_LINE(__expected_line__, __return_value__) _ASSERT_CURRENT_LINE(__expected_line__, __return_value__, THROW_ON_PARSE_ERROR)

- (BOOL) parseHeader:(NSString*)curLine
{
    NSArray* values = [curLine componentsSeparatedByString:kTabSeparator];
    PARSE_ASSERT(values.count >= 4, @"invalid number of element in header line", NO);
    
    self.version = values[0];
    self.url = [NSURL URLWithString:values[1]];
    self.interval = [values[2] doubleValue] / 1000000.0;
    self.startDate = [NSDate dateWithString:values[3]];
    
    if (values.count > 4) {
        self.beginningInfoDescription = values[4]; // Fixme: unescape when writer escapes \t and \n
    }
        
    return YES;
}

- (RPStackFrame*) parseLine:(NSString*)line
{
	
	NSArray* components = [line componentsSeparatedByString:@"\t"];
    PARSE_ASSERT(components.count == 4, @"Invalid index number (index is probably not given in order", nil);

	
	RPStackFrame* parsedLine = [[RPStackFrame alloc] init];
	
    parsedLine.fileId = [components[0] integerValue];
    parsedLine.fileLine = [components[1] integerValue];
    parsedLine.classId = [components[2] integerValue];
    parsedLine.functionId = [components[3] integerValue];
	
	return parsedLine;
}

- (NSArray*) parseSymbolIndexUpTo:(NSString*)endDelimiter
{
    NSMutableArray* symbols = [[NSMutableArray alloc] init];
    NSInteger indexCheck = 1;
    
    NSString* curLine = [self readNextLine];
    while (curLine && ![curLine isEqualToString:endDelimiter]) {
        NSArray* indexEntry = [curLine componentsSeparatedByString:kTabSeparator];
        if (indexEntry.count != 2) {
            self.parseError = [NSError errorWithDomain:RPRubyTraceErrorDomain code:RPRubyTraceParseError userInfo:@{NSLocalizedDescriptionKey : @"Invalid number of elements in index line"}];
            return NO;
        }
        NSInteger index = [indexEntry[0] integerValue];
        NSString* value = indexEntry[1];
        PARSE_ASSERT(index == indexCheck, @"Invalid index number (index is probably not given in order", nil)
        [symbols addObject:value];
        
        indexCheck++;
        curLine = [self readNextLine];
    }

    ASSERT_CURRENT_LINE(endDelimiter, NO);
    return symbols;
}

- (BOOL) parseFooter:(NSString*)curLine
{
    NSArray* values = [curLine componentsSeparatedByString:kTabSeparator];
    PARSE_ASSERT(values.count <= 3, @"invalid number of element in footer line", NO);
    
    self.duration = [values[0] doubleValue];
    self.sampleCount = [values[1] integerValue];
    
    if (values.count > 2) {
        self.endingInfoDescription = values[2]; // Fixme: unescape when writer escapes \t and \n
    }
    
    return YES;
}



- (BOOL) readData
{
    NSString* curLine = [self readNextLine];
    PARSE_ASSERT(curLine, @"empty file", NO);
    
    BOOL headerOK = [self parseHeader:curLine];
    if (!headerOK) return NO;
    
    curLine = [self readNextLine];
    ASSERT_CURRENT_LINE(kTracesStartMarker, NO);
    
    curLine = [self readNextLine];
    while (curLine && ![curLine isEqualToString:kFileIndexStartMarker]) {
        NSArray* stackTraceInfos = [curLine componentsSeparatedByString:kTabSeparator];
        PARSE_ASSERT(stackTraceInfos.count == 3, @"invalid number of element in frame header", NO);
        int stackDepth = [stackTraceInfos[0] intValue];

        RPStackTrace* stackTrace = [[RPStackTrace alloc] init];
        stackTrace.sampleCount = [stackTraceInfos[1] integerValue];
        stackTrace.duration = [stackTraceInfos[2] doubleValue];
        
        NSMutableArray* stackLines = [[NSMutableArray alloc] initWithCapacity:stackDepth];
        for (int i=0; i<stackDepth; ++i) {
            curLine = [self readNextLine];
            PARSE_ASSERT(curLine, @"unexpected end of file while reading stack trace", NO);
            RPStackFrame* parsedLine  = [self parseLine:curLine];
            if (!parsedLine) return NO;
            parsedLine.isLeaf = (i == stackDepth-1);
            [stackLines addObject:parsedLine];
        }
        stackTrace.frames = stackLines;
        [self.stacks addObject:stackTrace];
        
        curLine = [self readNextLine]; // eat aesthetic empty line between frames
        ASSERT_CURRENT_LINE(kEmptyLine, NO);

        curLine = [self readNextLine]; // next stack trace
    }
    
    ASSERT_CURRENT_LINE(kFileIndexStartMarker, NO);
    self.filesIndex = [self parseSymbolIndexUpTo:kClassIndexStartMarker];
    if (!self.filesIndex) return NO;
    
    self.classesIndex = [self parseSymbolIndexUpTo:kFunctionIndexStartMarker];
    if (!self.classesIndex) return NO;
    
    self.functionsIndex = [self parseSymbolIndexUpTo:kFooterStartMarker];
    if (!self.functionsIndex) return NO;
        
    curLine = [self readNextLine];
    PARSE_ASSERT(curLine, @"unexpected end of file reaching footer", NO);
    
    BOOL footerOK = [self parseFooter:curLine];
    if (!footerOK) return NO;
    
    NSLog(@"File read successfully");
    NSLog(@"stacks %lu", [self.stacks count]);

    return YES;
}


- (NSString*) filePathForIndex:(NSInteger)index
{
    if (index == 0) return @"-";
    return _filesIndex[index-1];
}

- (NSString*) classnameForIndex:(NSInteger)index
{
    if (index == 0) return @"-";
    return _classesIndex[index-1];
}

- (NSString*) functionForIndex:(NSInteger)index
{
    if (index == 0) return @"-";
    return _functionsIndex[index-1];
}

- (RPSampleSession*)sampleSession
{
	RPSampleSession* session;
	int totalSampleCount = 0;
	
	session = [[RPSampleSession alloc] init];
	session.thread = 0;

	for (RPStackTrace *stackTrace in self.stacks) {
		RPCallTree *callTreeFrame;
		RPStackFrame *frame;
		NSInteger stackTraceSampleCount;
		
		stackTraceSampleCount = [stackTrace sampleCount];
		totalSampleCount += stackTraceSampleCount;
        
		callTreeFrame = session;
		for (frame in stackTrace.frames) {
            
            NSString* filePath = [self filePathForIndex:frame.fileId];
            NSString* className = [self classnameForIndex:frame.classId];
            NSString* function = [self functionForIndex:frame.functionId];
            

            callTreeFrame = [callTreeFrame subTreeForFunctionId:frame.functionId classId:frame.classId create:YES];
            
            if (frame.isLeaf) {
                // last frame. Assign all canonical durations to this one.
                callTreeFrame.selfSampleCount += stackTrace.sampleCount;
                callTreeFrame.selfBlockedTicks += stackTrace.sampleCount - 1;
                callTreeFrame.selfStackTraceCount += 1;
            }

			callTreeFrame.startLine = frame.logLineNumber;
			callTreeFrame.method = function;
			callTreeFrame.file = filePath;
			callTreeFrame.moduleOrClass = className;
		}
	}
    
    session.sessionDurationPerTick = self.duration / totalSampleCount;
    
	[session freeze];
	NSLog(@"totalSampleCount %d", totalSampleCount);
	return session;
}

@end
