//
// Created by Jose Portocarrero on 3/4/20.
// Copyright (c) 2020 AppMonet. All rights reserved.
//

#import "AMORemoteConfiguration.h"
#import "AMOConstants.h"
#import "zlib.h"

@interface AMORemoteConfiguration ()
@property(nonatomic, strong) NSString *applicationId;
@end

@implementation AMORemoteConfiguration {
    NSLock *_lock;
    NSURLCache *_cache;
}

- (instancetype)initWithApplicationId:(NSString *)applicationId {
    if (self = [super init]) {
        self.applicationId = applicationId;
        _lock = [[NSLock alloc] init];
        NSUInteger cacheSizeMemory = 10 * 1024 * 1024; // 10 MB
        NSUInteger cacheSizeDisk = 10 * 1024 * 1024; // 10 MB
        _cache = [[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory
                                               diskCapacity:cacheSizeDisk diskPath:@"monet"];
    }
    return self;
}

- (void)getConfiguration:(BOOL)forceServer completion:(void (^)(NSString *response))completion {
    [_lock lock];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.URLCache = _cache;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSURL *url = [[NSURL alloc] initWithString:
            [NSString stringWithFormat:@"%@/%@/%@/%@", kAMAuctionManagerConfigUrl, @"hb", @"c1", self.applicationId]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:(forceServer) ? NSURLRequestReloadIgnoringCacheData
                                                                   : NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:8.0];
    [request setHTTPMethod:@"GET"];
    NSURLSessionDataTask *sessionDataTask =
            [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                [session finishTasksAndInvalidate];
                if (completion) {
                    if (error) {
                        completion(@"{}");
                        return;
                    }
                    NSMutableDictionary *finalResponse = [NSMutableDictionary dictionary];
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                    if ([response respondsToSelector:@selector(allHeaderFields)]) {
                        NSDictionary *headers = [httpResponse allHeaderFields];
                        finalResponse[@"isCached"] = ([self isCached:headers[@"Etag"]]) ? @"true" : @"false";
                        finalResponse[@"remoteAddr"] = headers[@"X-Remote-Addr"];
                        finalResponse[@"country"] = headers[@"X-Client-Country"];
                    }
                    NSDictionary *body = [self responseData:data];
                    finalResponse[@"body"] = body;
                    NSError *err;
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:finalResponse options:0 error:&err];
                    NSString *jsonString = (err) ? @"{}" : [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    completion(jsonString);
                }
                [_lock unlock];
            }];
    [sessionDataTask resume];
}

- (NSDictionary *)responseData:(NSData *)data {
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedData:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSData *decompressedData = [self zlibInflate:decodedData];
    if(decompressedData == nil){
        return nil;
    }
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:decompressedData options:0 error:&error];
    return (error) ? nil : json;
}

- (NSData *)zlibInflate:(NSData *)data {
    if ([data length] == 0) return data;

    unsigned full_length = [data length];
    unsigned half_length = [data length] / 2;

    NSMutableData *decompressed = [NSMutableData dataWithLength:full_length + half_length];
    BOOL done = NO;
    int status;

    z_stream strm;
    strm.next_in = (Bytef *) [data bytes];
    strm.avail_in = [data length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;

    if (inflateInit (&strm) != Z_OK) return nil;

    while (!done) {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length])
            [decompressed increaseLengthBy:half_length];
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = [decompressed length] - strm.total_out;

        // Inflate another chunk.
        status = inflate(&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) done = YES;
        else if (status != Z_OK) break;
    }
    if (inflateEnd(&strm) != Z_OK) return nil;

    // Set real length.
    if (done) {
        [decompressed setLength:strm.total_out];
        return [NSData dataWithData:decompressed];
    } else return nil;
}

- (BOOL)isCached:(NSString *)etag {
    NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"W"];
    NSRange range = [etag rangeOfCharacterFromSet:cset];
    return range.location == NSNotFound;
}

@end