//
//  HMPlaintextLogger.m
//  Pods
//
//  Created by lilingang on 16/3/26.
//
//

#import "HMPlaintextLogger.h"
#import <pthread/pthread.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

@interface HMLumberjackFileManager : DDLogFileManagerDefault

@property (nonatomic, copy) NSString *nameprefix;

@property (nonatomic, copy) NSString *pathComponent;

@end

@implementation HMLumberjackFileManager

- (NSDateFormatter *)logFileDateFormatter {
    NSMutableDictionary *dictionary = [[NSThread currentThread]
                                       threadDictionary];
    NSString *dateFormat = @"yyyyMMdd";
    NSString *key = [NSString stringWithFormat:@"logFileDateFormatter.%@", dateFormat];
    NSDateFormatter *dateFormatter = dictionary[key];
    
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        [dateFormatter setDateFormat:dateFormat];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        dictionary[key] = dateFormatter;
    }
    
    return dateFormatter;
}

- (NSString *)newLogFileName {
    NSDateFormatter *dateFormatter = [self logFileDateFormatter];
    NSString *formattedDate = [dateFormatter stringFromDate:[NSDate date]];
    NSString *fileName = @"";
    if (self.nameprefix) {
        fileName = [fileName stringByAppendingString:self.nameprefix];
    }
    fileName = [fileName stringByAppendingFormat:@"_%@.%@",formattedDate,self.pathComponent];
    return fileName;
}

- (BOOL)isLogFile:(NSString *)fileName {
    BOOL hasProperPrefix = [fileName hasPrefix:self.nameprefix];
    BOOL hasProperSuffix = [fileName hasSuffix:@".log"];
    BOOL hasProperDate = NO;
    
    if (hasProperPrefix && hasProperSuffix) {
        NSString *dateString = [fileName.stringByDeletingLastPathComponent stringByReplacingOccurrencesOfString:self.nameprefix withString:@""];
        dateString = [dateString stringByReplacingOccurrencesOfString:@"_" withString:@""];
        NSDateFormatter *dateFormatter = [self logFileDateFormatter];
        NSDate *date = [dateFormatter dateFromString:dateString];
        if (date) {
            hasProperDate = YES;
        }
    }
    return (hasProperPrefix && hasProperDate && hasProperSuffix);
}

@end


@interface HMLumberjackFormatter : NSObject<DDLogFormatter>

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation HMLumberjackFormatter

- (instancetype)init {
    self = [super init];
    if (self) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4]; // 10.4+ style
        [self.dateFormatter setDateFormat:@"yyyy-MM-dd z HH:mm:ss.SSS"];
    }
    return self;
}

- (NSString * __nullable)formatLogMessage:(DDLogMessage *)logMessage {
    NSProcessInfo* info = [NSProcessInfo processInfo];
    
    NSString *logString = @"";
    switch (logMessage.flag) {
        case DDLogFlagDebug:
            logString = [logString stringByAppendingString:@"[D]"];
            break;
        case DDLogFlagInfo:
            logString = [logString stringByAppendingString:@"[I]"];
            break;
        case DDLogFlagWarning:
            logString = [logString stringByAppendingString:@"[W]"];
            break;
        case DDLogFlagError:
            logString = [logString stringByAppendingString:@"[E]"];
            break;
        case DDLogFlagVerbose:
            logString = [logString stringByAppendingString:@"[V]"];
            break;
        default:
            break;
    }
    NSString *dateStr = [self.dateFormatter stringFromDate:logMessage.timestamp];
    logString = [logString stringByAppendingFormat:@"[%@][%d,%@]", dateStr, info.processIdentifier, logMessage.threadID];
    if (logMessage.tag) {
        logString = [logString stringByAppendingFormat:@"[%@]",logMessage.tag];
    }
    
    logString = [logString stringByAppendingString:@"["];
    if (logMessage.file) {
        logString = [logString stringByAppendingFormat:@"%@,",[logMessage.file lastPathComponent]];
    }
    if (logMessage.function) {
        NSArray *tmpArray = [logMessage.function componentsSeparatedByString:@" "];
        NSString *lastString = [tmpArray lastObject];
        lastString = [lastString stringByReplacingOccurrencesOfString:@":]" withString:@""];
        logString = [logString stringByAppendingFormat:@" %@",lastString];
    }
    logString = [logString stringByAppendingString:@"]"];
    
    logString = [logString stringByAppendingFormat:@"[%@\n",logMessage.message];
    return logString;
}

@end

@interface HMFileLogger: DDFileLogger


@end

@implementation HMFileLogger

- (instancetype)initWithLogFileManager:(id<DDLogFileManager>)logFileManager{
    self = [super initWithLogFileManager:logFileManager];
    if (self) {
        self.rollingFrequency = 60 * 60 * 24;//一天
        self.maximumFileSize  = 50 * 1024 * 1024;
        self.logFileManager.maximumNumberOfLogFiles = 10;
        self.automaticallyAppendNewlineForCustomFormatters = NO;
    }
    return self;
}

- (BOOL)shouldArchiveRecentLogFileInfo:(DDLogFileInfo *)recentLogFileInfo {
    //自定义判断日志是否创建
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents * creationDateComponents = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:recentLogFileInfo.creationDate];
    NSDateComponents * currentDateComponents = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:[NSDate date]];
    if (creationDateComponents.year == currentDateComponents.year && creationDateComponents.month == currentDateComponents.month && creationDateComponents.day == currentDateComponents.day) {
        return NO;
    } else {
        return YES;
    }
}

@end


#ifdef DEBUG
static const NSUInteger ddLogLevel = DDLogLevelAll;
#else
static const NSUInteger ddLogLevel = DDLogLevelError | DDLogFlagWarning | DDLogFlagInfo;
#endif

@implementation HMPlaintextLogger

+ (void)startLogWithCacheDirectory:(NSString *)cacheDirectory
                        nameprefix:(NSString *)nameprefix{
    HMLumberjackFormatter *logFormatter = [[HMLumberjackFormatter alloc] init];

    
    HMLumberjackFileManager *fileManager = [[HMLumberjackFileManager alloc] initWithLogsDirectory:cacheDirectory];
    fileManager.nameprefix = nameprefix;
    fileManager.pathComponent = @"log";
    HMFileLogger *fileLogger = [[HMFileLogger alloc] initWithLogFileManager:fileManager];
    fileLogger.logFormatter = logFormatter;
    [DDLog addLogger:fileLogger withLevel:ddLogLevel];
#if DEBUG
    DDTTYLogger *tyLogger = [DDTTYLogger sharedInstance];
    tyLogger.logFormatter = logFormatter;
    [DDLog addLogger:tyLogger];
#endif
}

+ (void)setLogSuffix:(NSString *)logSuffix fileCount:(NSUInteger)fileCount {
    __block DDFileLogger *fileLogger = nil;
    [[DDLog allLoggers] enumerateObjectsUsingBlock:^(id<DDLogger>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[DDFileLogger class]]) {
            fileLogger = obj;
            *stop = YES;
        }
    }];
    if (!fileLogger) {
        return;
    }
    if (logSuffix) {
        ((HMLumberjackFileManager *)fileLogger.logFileManager).pathComponent = logSuffix;
    }
    if (fileCount > 0) {
        fileLogger.logFileManager.maximumNumberOfLogFiles = fileCount;
    }
}



+ (void)writeLogFile:(const char *)file
            function:(const char *)function
                line:(int)line
               level:(HMLogLevel)level
                 tag:(NSString *)tag
              format:(NSString *)format
                args:(va_list)args {
    DDLogFlag flag = DDLogFlagDebug;
    switch (level) {
        case HMLogLevelDebug:
            flag = DDLogFlagDebug;
            break;
        case HMLogLevelInfo:
            flag = DDLogFlagInfo;
            break;
        case HMLogLevelWarn:
            flag = DDLogFlagWarning;
            break;
        case HMLogLevelError:
            flag = DDLogFlagError;
            break;
        case HMLogLevelFatal:
            flag = DDLogFlagVerbose;
            break;
        default:
            break;
    }
    [DDLog log:YES level:ddLogLevel flag:flag context:0 file:file function:function line:line tag:tag format:format args:args];
}


+ (void)flushToDisk {
    [DDLog flushLog];
}


@end
