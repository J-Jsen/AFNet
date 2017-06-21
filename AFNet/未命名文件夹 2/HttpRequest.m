//
//  HttpRequset.m
//  AFNet
//
//  Created by Suger on 17/6/19.
//  Copyright © 2017年 Suger. All rights reserved.
//

#import "HttpRequest.h"
#import <AFNetworkActivityIndicatorManager.h>
#import <CommonCrypto/CommonDigest.h>
//超时时间
static NSTimeInterval xs_timeout = 60.0f;
static NSMutableArray *xs_requestTasks;
static BOOL xs_cacheGet = YES;
static BOOL xs_cachePost = NO;
static NSUInteger xs_maxCacheSize = 0;
static BOOL xs_isEnableInterfaceDebug = NO;
static ZXSResponseType xs_responseType = ZXSResponseTypeJSON;
static ZXSRequestType  xs_requestType  = ZXSRequestTypePlainText;
static BOOL xs_shouldAutoEncode = NO;
static BOOL xs_shouldCallbackOnCancelRequest = YES;
static NSDictionary * xs_httpHeaders = nil;
static NSString *xs_privateNetworkBaseUrl = nil;
static BOOL xs_shoulObtainLocalWhenUnconnected = NO;
static ZXSNetworkStatus xs_networkStatus = ZXSBNetworkStatusReachableViaWiFi;
static AFHTTPSessionManager *xs_sharedManager = nil;

@interface NSString (md5)

+ (NSString *)hybnetworking_md5:(NSString *)string;

@end

@implementation NSString (md5)

+ (NSString *)hybnetworking_md5:(NSString *)string {
    if (string == nil || [string length] == 0) {
        return nil;
    }
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
    CC_MD5([string UTF8String], (int)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
    NSMutableString *ms = [NSMutableString string];
    
    for (i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ms appendFormat:@"%02x", (int)(digest[i])];
    }
    
    return [ms copy];
}

@end

@implementation HttpRequest

+ (void)setTimeout:(NSTimeInterval)timeout{
    xs_timeout = timeout;
}
//缓存路径
static inline NSString *cachePath() {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/ZXSNetworkingCaches"];
}

+ (unsigned long long)totalCacheSize {
    NSString *directoryPath = cachePath();
    BOOL isDir = NO;
    unsigned long long total = 0;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
        if (isDir) {
            NSError *error = nil;
            NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
            
            if (error == nil) {
                for (NSString *subpath in array) {
                    NSString *path = [directoryPath stringByAppendingPathComponent:subpath];
                    NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                                          error:&error];
                    if (!error) {
                        total += [dict[NSFileSize] unsignedIntegerValue];
                    }
                }
            }
        }
    }
    
    return total;
}

+ (NSMutableArray *)allTasks {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (xs_requestTasks == nil) {
            xs_requestTasks = [[NSMutableArray alloc] init];
        }
    });
    
    return xs_requestTasks;
}

+ (void)cancelAllRequest {
    @synchronized(self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(ZXSURLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task isKindOfClass:[ZXSURLSessionTask class]]) {
                [task cancel];
            }
        }];
        
        [[self allTasks] removeAllObjects];
    };
}
+ (void)cancelRequestWithURL:(NSString *)url {
    if (url == nil) {
        return;
    }
    
    @synchronized(self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(ZXSURLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task isKindOfClass:[ZXSURLSessionTask class]]
                && [task.currentRequest.URL.absoluteString hasSuffix:url]) {
                [task cancel];
                [[self allTasks] removeObject:task];
                return;
            }
        }];
    };
}

+ (void)cacheGetRequest:(BOOL)isCacheGet shoulCachePost:(BOOL)shouldCachePost {
    xs_cacheGet = isCacheGet;
    xs_cachePost = shouldCachePost;
}

+ (void)autoToClearCacheWithLimitedToSize:(NSUInteger)mSize {
    xs_maxCacheSize = mSize;
}


+ (void)clearCaches {
    NSString *directoryPath = cachePath();
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:directoryPath error:&error];
        
        if (error) {
            NSLog(@"clear caches error: %@", error);
        } else {
            NSLog(@"clear caches ok");
        }
    }
}
+ (void)enableInterfaceDebug:(BOOL)isDebug {
    xs_isEnableInterfaceDebug = isDebug;
}

+ (BOOL)isDebug {
    return xs_isEnableInterfaceDebug;
}
+ (void)configRequestType:(ZXSRequestType)requestType
             responseType:(ZXSResponseType)responseType
      shouldAutoEncodeUrl:(BOOL)shouldAutoEncode
  callbackOnCancelRequest:(BOOL)shouldCallbackOnCancelRequest {
    xs_requestType = requestType;
    xs_responseType = responseType;
    xs_shouldAutoEncode = shouldAutoEncode;
    xs_shouldCallbackOnCancelRequest = shouldCallbackOnCancelRequest;
}
+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders {
    xs_httpHeaders = httpHeaders;
}

+ (ZXSURLSessionTask *)getWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                          success:(ZXSResponseSuccess)success
                             fail:(ZXSResponseFail)fail {
    return [self getWithUrl:url
               refreshCache:refreshCache
                     params:nil
                    success:success
                       fail:fail];
}

+ (ZXSURLSessionTask *)getWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSDictionary *)params
                          success:(ZXSResponseSuccess)success
                             fail:(ZXSResponseFail)fail {
    return [self getWithUrl:url
               refreshCache:refreshCache
                     params:params
                   progress:nil
                    success:success
                       fail:fail];
}
+ (ZXSURLSessionTask *)getWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSDictionary *)params
                         progress:(ZXSGetProgress)progress
                          success:(ZXSResponseSuccess)success
                             fail:(ZXSResponseFail)fail {
    return [self _requestWithUrl:url
                    refreshCache:refreshCache
                       httpMedth:1
                          params:params
                        progress:progress
                         success:success
                            fail:fail];
}
+ (ZXSURLSessionTask *)postWithUrl:(NSString *)url
                      refreshCache:(BOOL)refreshCache
                            params:(NSDictionary *)params
                           success:(ZXSResponseSuccess)success
                              fail:(ZXSResponseFail)fail {
    return [self postWithUrl:url
                refreshCache:refreshCache
                      params:params
                    progress:nil
                     success:success
                        fail:fail];
}

+ (ZXSURLSessionTask *)postWithUrl:(NSString *)url
                      refreshCache:(BOOL)refreshCache
                            params:(NSDictionary *)params
                          progress:(ZXSPostProgress)progress
                           success:(ZXSResponseSuccess)success
                              fail:(ZXSResponseFail)fail {
    return [self _requestWithUrl:url
                    refreshCache:refreshCache
                       httpMedth:2
                          params:params
                        progress:progress
                         success:success
                            fail:fail];
}


+ (ZXSURLSessionTask *)_requestWithUrl:(NSString *)url
                          refreshCache:(BOOL)refreshCache
                             httpMedth:(NSUInteger)httpMethod
                                params:(NSDictionary *)params
                              progress:(ZXSDownloadProgress)progress
                               success:(ZXSResponseSuccess)success
                                  fail:(ZXSResponseFail)fail {
    if ([self shouldEncode]) {
        url = [self encodeUrl:url];
    }
    
    AFHTTPSessionManager *manager = [self manager];
    NSURL *absoluteURL = [NSURL URLWithString:url];
        
    if (absoluteURL == nil) {
        ZXSLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
        return nil;
    }
    
    ZXSURLSessionTask *session = nil;
    
    if (httpMethod == 1) {
        if (xs_cacheGet) {
            if (xs_shoulObtainLocalWhenUnconnected) {
                if (xs_networkStatus == ZXSBNetworkStatusNotReachable ||  xs_networkStatus == ZXSBNetworkStatusUnknown ) {
                    id response = [HttpRequest cahceResponseWithURL:url
                                                           parameters:params];
                    if (response) {
                        if (success) {
                            [self successResponse:response callback:success];
                            
                            if ([self isDebug]) {
                                [self logWithSuccessResponse:response
                                                         url:url
                                                      params:params];
                            }
                        }
                        return nil;
                    }
                }
            }
            if (!refreshCache) {// 获取缓存
                id response = [HttpRequest cahceResponseWithURL:url
                                                       parameters:params];
                if (response) {
                    if (success) {
                        [self successResponse:response callback:success];
                        
                        if ([self isDebug]) {
                            [self logWithSuccessResponse:response
                                                     url:url
                                                  params:params];
                        }
                    }
                    return nil;
                }
            }
        }
        
        session = [manager GET:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
            if (progress) {
                progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
            }
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [self successResponse:responseObject callback:success];
            
            if (xs_cacheGet) {
                [self cacheResponseObject:responseObject request:task.currentRequest parameters:params];
            }
            
            [[self allTasks] removeObject:task];
            
            if ([self isDebug]) {
                [self logWithSuccessResponse:responseObject
                                         url:url
                                      params:params];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [[self allTasks] removeObject:task];
            
            if ([error code] < 0 && xs_cacheGet) {// 获取缓存
                id response = [HttpRequest cahceResponseWithURL:url
                                                       parameters:params];
                if (response) {
                    if (success) {
                        [self successResponse:response callback:success];
                        
                        if ([self isDebug]) {
                            [self logWithSuccessResponse:response
                                                     url:url
                                                  params:params];
                        }
                    }
                } else {
                    [self handleCallbackWithError:error fail:fail];
                    
                    if ([self isDebug]) {
                        [self logWithFailError:error url:url params:params];
                    }
                }
            } else {
                [self handleCallbackWithError:error fail:fail];
                
                if ([self isDebug]) {
                    [self logWithFailError:error url:url params:params];
                }
            }
        }];
    } else if (httpMethod == 2) {
        if (xs_cachePost ) {// 获取缓存
            if (xs_shoulObtainLocalWhenUnconnected) {
                if (xs_networkStatus == ZXSBNetworkStatusNotReachable ||  xs_networkStatus == ZXSBNetworkStatusUnknown ) {
                    id response = [HttpRequest cahceResponseWithURL:url
                                                           parameters:params];
                    if (response) {
                        if (success) {
                            [self successResponse:response callback:success];
                            
                            if ([self isDebug]) {
                                [self logWithSuccessResponse:response
                                                         url:url
                                                      params:params];
                            }
                        }
                        return nil;
                    }
                }
            }
            if (!refreshCache) {
                id response = [HttpRequest cahceResponseWithURL:url
                                                       parameters:params];
                if (response) {
                    if (success) {
                        [self successResponse:response callback:success];
                        
                        if ([self isDebug]) {
                            [self logWithSuccessResponse:response
                                                     url:url
                                                  params:params];
                        }
                    }
                    return nil;
                }
            }
        }
        
        session = [manager POST:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
            if (progress) {
                progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
            }
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [self successResponse:responseObject callback:success];
            
            if (xs_cachePost) {
                [self cacheResponseObject:responseObject request:task.currentRequest  parameters:params];
            }
            
            [[self allTasks] removeObject:task];
            
            if ([self isDebug]) {
                [self logWithSuccessResponse:responseObject
                                         url:url
                                      params:params];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [[self allTasks] removeObject:task];
            
            if ([error code] < 0 && xs_cachePost) {// 获取缓存
                id response = [HttpRequest cahceResponseWithURL:url
                                                       parameters:params];
                
                if (response) {
                    if (success) {
                        [self successResponse:response callback:success];
                        
                        if ([self isDebug]) {
                            [self logWithSuccessResponse:response
                                                     url:url
                                                  params:params];
                        }
                    }
                } else {
                    [self handleCallbackWithError:error fail:fail];
                    
                    if ([self isDebug]) {
                        [self logWithFailError:error url:url params:params];
                    }
                }
            } else {
                [self handleCallbackWithError:error fail:fail];
                
                if ([self isDebug]) {
                    [self logWithFailError:error url:url params:params];
                }
            }
        }];
    }
    
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
}
//上传图片
+ (ZXSURLSessionTask *)uploadWithImage:(UIImage *)image
                                   url:(NSString *)url
                              filename:(NSString *)filename
                                  name:(NSString *)name
                              mimeType:(NSString *)mimeType
                            parameters:(NSDictionary *)parameters
                              progress:(ZXSUploadProgress)progress
                               success:(ZXSResponseSuccess)success
                                  fail:(ZXSResponseFail)fail {

    
    if ([self shouldEncode]) {
        url = [self encodeUrl:url];
    }
    
    AFHTTPSessionManager *manager = [self manager];
    ZXSURLSessionTask *session = [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSData *imageData = UIImageJPEGRepresentation(image, 1);
        
        NSString *imageFileName = filename;
        if (filename == nil || ![filename isKindOfClass:[NSString class]] || filename.length == 0) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            imageFileName = [NSString stringWithFormat:@"%@.jpg", str];
        }
        
        // 上传图片，以文件流的格式
        [formData appendPartWithFileData:imageData name:name fileName:imageFileName mimeType:mimeType];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[self allTasks] removeObject:task];
        [self successResponse:responseObject callback:success];
        
        if ([self isDebug]) {
            [self logWithSuccessResponse:responseObject
                                     url:url
                                  params:parameters];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self allTasks] removeObject:task];
        
        [self handleCallbackWithError:error fail:fail];
        
        if ([self isDebug]) {
            [self logWithFailError:error url:url params:nil];
        }
    }];
    
    [session resume];
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
}
//下载文件到指定位置
+ (ZXSURLSessionTask *)downloadWithUrl:(NSString *)url
                            saveToPath:(NSString *)saveToPath
                              progress:(ZXSDownloadProgress)progressBlock
                               success:(ZXSResponseSuccess)success
                               failure:(ZXSResponseFail)failure {
    
    NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFHTTPSessionManager *manager = [self manager];
    
    ZXSURLSessionTask *session = nil;
    
    session = [manager downloadTaskWithRequest:downloadRequest progress:^(NSProgress * _Nonnull downloadProgress) {
        if (progressBlock) {
            progressBlock(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
        }
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:saveToPath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [[self allTasks] removeObject:session];
        
        if (error == nil) {
            if (success) {
                success(filePath.absoluteString);
            }
            
            if ([self isDebug]) {
                ZXSLog(@"Download success for url %@",
                          url);
            }
        } else {
            [self handleCallbackWithError:error fail:failure];
            
            if ([self isDebug]) {
                ZXSLog(@"Download fail for url %@, reason : %@",
                          url,
                          [error description]);
            }
        }
    }];
    
    [session resume];
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
}
//上传文件
+ (ZXSURLSessionTask *)uploadFileWithUrl:(NSString *)url
                           uploadingFile:(NSString *)uploadingFile
                                progress:(ZXSUploadProgress)progress
                                 success:(ZXSResponseSuccess)success
                                    fail:(ZXSResponseFail)fail {
    if ([NSURL URLWithString:uploadingFile] == nil) {
        ZXSLog(@"uploadingFile无效，无法生成URL。请检查待上传文件是否存在");
        return nil;
    }
    
    NSURL * uploadURL = [NSURL URLWithString:url];
    if (uploadURL == nil) {
        ZXSLog(@"URLString无效，无法生成URL。可能是URL中有中文或特殊字符，请尝试Encode URL");
        return nil;
    }
    
    AFHTTPSessionManager *manager = [self manager];
    NSURLRequest *request = [NSURLRequest requestWithURL:uploadURL];
    ZXSURLSessionTask *session = nil;
    
    [manager uploadTaskWithRequest:request fromFile:[NSURL URLWithString:uploadingFile] progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        }
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        [[self allTasks] removeObject:session];
        
        [self successResponse:responseObject callback:success];
        
        if (error) {
            [self handleCallbackWithError:error fail:fail];
            
            if ([self isDebug]) {
                [self logWithFailError:error url:response.URL.absoluteString params:nil];
            }
        } else {
            if ([self isDebug]) {
                [self logWithSuccessResponse:responseObject
                                         url:response.URL.absoluteString
                                      params:nil];
            }
        }
    }];
    
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
}

+ (BOOL)shouldEncode {
    return xs_shouldAutoEncode;
}
+ (NSString *)encodeUrl:(NSString *)url {
    return [self ZXS_URLEncode:url];
}
+ (NSString *)ZXS_URLEncode:(NSString *)url {
    return [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}


#pragma mark - Private
+ (AFHTTPSessionManager *)manager {
    @synchronized (self) {
        // 只要不切换baseurl，就一直使用同一个session manager
        if (xs_sharedManager == nil) {
            // 开启转圈圈
            [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
            
            }
        AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];

        switch (xs_requestType) {
            case ZXSRequestTypeJSON: {
                manager.requestSerializer = [AFJSONRequestSerializer serializer];
                break;
            }
            case ZXSRequestTypePlainText: {
                manager.requestSerializer = [AFHTTPRequestSerializer serializer];
                break;
            }
            default: {
                break;
            }
        }
            
        switch (xs_responseType) {
            case ZXSResponseTypeJSON: {
                manager.responseSerializer = [AFJSONResponseSerializer serializer];
                break;
            }
            case ZXSResponseTypeXML: {
                manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
                break;
            }
            case ZXSResponseTypeData: {
                manager.responseSerializer = [AFHTTPResponseSerializer serializer];
                break;
            }
            default: {
                break;
            }
        }
        manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
        
        
        for (NSString *key in xs_httpHeaders.allKeys) {
            if (xs_httpHeaders[key] != nil) {
                [manager.requestSerializer setValue:xs_httpHeaders[key] forHTTPHeaderField:key];
            }
        }
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                                  @"text/html",
                                                                                  @"text/json",
                                                                                  @"text/plain",
                                                                                  @"text/javascript",
                                                                                  @"text/xml",
                                                                                  @"image/*"]];
        
        manager.requestSerializer.timeoutInterval = xs_timeout;
        
        // 设置允许同时最大并发数量，过大容易出问题
        manager.operationQueue.maxConcurrentOperationCount = 3;
        xs_sharedManager = manager;
    
    }

    return xs_sharedManager;
}
/*
+ (NSString *)absoluteUrlWithPath:(NSString *)path {
    if (path == nil || path.length == 0) {
        return @"";
    }
    
    
    NSString *absoluteUrl = path;
    
    if (![path hasPrefix:@"http:"] && ![path hasPrefix:@"https:"]) {
        if ([[self baseUrl] hasSuffix:@"/"]) {
            if ([path hasPrefix:@"/"]) {
                NSMutableString * mutablePath = [NSMutableString stringWithString:path];
                [mutablePath deleteCharactersInRange:NSMakeRange(0, 1)];
                absoluteUrl = [NSString stringWithFormat:@"%@%@",
                               [self baseUrl], mutablePath];
            } else {
                absoluteUrl = [NSString stringWithFormat:@"%@%@",[self baseUrl], path];
            }
        } else {
            if ([path hasPrefix:@"/"]) {
                absoluteUrl = [NSString stringWithFormat:@"%@%@",[self baseUrl], path];
            } else {
                absoluteUrl = [NSString stringWithFormat:@"%@/%@",
                               [self baseUrl], path];
            }
        }
    }
    
    return absoluteUrl;
}
*/
+ (id)cahceResponseWithURL:(NSString *)url parameters:params {
    id cacheData = nil;
    
    if (url) {
        // Try to get datas from disk
        NSString *directoryPath = cachePath();
        NSString *absoluteURL = [self generateGETAbsoluteURL:url params:params];
        NSString *key = [NSString hybnetworking_md5:absoluteURL];
        NSString *path = [directoryPath stringByAppendingPathComponent:key];
        
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
        if (data) {
            cacheData = data;
            ZXSLog(@"Read data from cache for url: %@\n", url);
        }
    }
    
    return cacheData;
}
+ (void)successResponse:(id)responseData callback:(ZXSResponseSuccess)success {
    if (success) {
        success([self tryToParseData:responseData]);
    }
}
+ (id)tryToParseData:(id)responseData {
    if ([responseData isKindOfClass:[NSData class]]) {
        // 尝试解析成JSON
        if (responseData == nil) {
            return responseData;
        } else {
            NSError *error = nil;
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData
                                                                     options:NSJSONReadingMutableContainers
                                                                       error:&error];
            
            if (error != nil) {
                return responseData;
            } else {
                return response;
            }
        }
    } else {
        return responseData;
    }
}

+ (void)logWithSuccessResponse:(id)response url:(NSString *)url params:(NSDictionary *)params {
    ZXSLog(@"\n");
    ZXSLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",
              [self generateGETAbsoluteURL:url params:params],
              params,
              [self tryToParseData:response]);
}
+ (void)logWithFailError:(NSError *)error url:(NSString *)url params:(id)params {
    NSString *format = @" params: ";
    if (params == nil || ![params isKindOfClass:[NSDictionary class]]) {
        format = @"";
        params = @"";
    }
    
    ZXSLog(@"\n");
    if ([error code] == NSURLErrorCancelled) {
        ZXSLog(@"\nRequest was canceled mannully, URL: %@ %@%@\n\n",
                  [self generateGETAbsoluteURL:url params:params],
                  format,
                  params);
    } else {
        ZXSLog(@"\nRequest error, URL: %@ %@%@\n errorInfos:%@\n\n",
                  [self generateGETAbsoluteURL:url params:params],
                  format,
                  params,
                  [error localizedDescription]);
    }
}
// 仅对一级字典结构起作用
+ (NSString *)generateGETAbsoluteURL:(NSString *)url params:(id)params {
    if (params == nil || ![params isKindOfClass:[NSDictionary class]] || [params count] == 0) {
        return url;
    }
    
    NSString *queries = @"";
    for (NSString *key in params) {
        id value = [params objectForKey:key];
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            continue;
        } else if ([value isKindOfClass:[NSArray class]]) {
            continue;
        } else if ([value isKindOfClass:[NSSet class]]) {
            continue;
        } else {
            queries = [NSString stringWithFormat:@"%@%@=%@&",
                       (queries.length == 0 ? @"&" : queries),
                       key,
                       value];
        }
    }
    
    if (queries.length > 1) {
        queries = [queries substringToIndex:queries.length - 1];
    }
    
    if (([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) && queries.length > 1) {
        if ([url rangeOfString:@"?"].location != NSNotFound
            || [url rangeOfString:@"#"].location != NSNotFound) {
            url = [NSString stringWithFormat:@"%@%@", url, queries];
        } else {
            queries = [queries substringFromIndex:1];
            url = [NSString stringWithFormat:@"%@?%@", url, queries];
        }
    }
    
    return url.length == 0 ? queries : url;
}


+ (void)cacheResponseObject:(id)responseObject request:(NSURLRequest *)request parameters:params {
    if (request && responseObject && ![responseObject isKindOfClass:[NSNull class]]) {
        NSString *directoryPath = cachePath();
        
        NSError *error = nil;
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
            if (error) {
                ZXSLog(@"create cache dir error: %@\n", error);
                return;
            }
        }
        
        NSString *absoluteURL = [self generateGETAbsoluteURL:request.URL.absoluteString params:params];
        NSString *key = [NSString hybnetworking_md5:absoluteURL];
        NSString *path = [directoryPath stringByAppendingPathComponent:key];
        NSDictionary *dict = (NSDictionary *)responseObject;
        
        NSData *data = nil;
        if ([dict isKindOfClass:[NSData class]]) {
            data = responseObject;
        } else {
            data = [NSJSONSerialization dataWithJSONObject:dict
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
        }
        
        if (data && error == nil) {
            BOOL isOk = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
            if (isOk) {
                ZXSLog(@"cache file ok for request: %@\n", absoluteURL);
            } else {
                ZXSLog(@"cache file error for request: %@\n", absoluteURL);
            }
        }
    }
}
+ (void)handleCallbackWithError:(NSError *)error fail:(ZXSResponseFail)fail {
    if ([error code] == NSURLErrorCancelled) {
        if (xs_shouldCallbackOnCancelRequest) {
            if (fail) {
                fail(error);
            }
        }
    } else {
        if (fail) {
            fail(error);
        }
    }
}



/***************************************************************************************/

//GET请求
+(void)getWithUrlString:(NSString *)urlString success:(HttpSuccess)success failure:(HttpFailure)failure{
    //创建请求管理者
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    //内容类型
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/json",@"text/javascript",@"text/html", nil];
    //get请求
    [manager GET:urlString parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //数据请求的进度
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
    
}

//POST请求
+(void)postWithUrlString:(NSString *)urlString parameters:(NSDictionary *)parameters success:(HttpSuccess)success failure:(HttpFailure)failure{
    //创建请求管理者
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    //内容类型
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/json",@"text/javascript",@"text/html", nil];
    //post请求
    [manager POST:urlString parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        //数据请求的进度
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
}
@end
