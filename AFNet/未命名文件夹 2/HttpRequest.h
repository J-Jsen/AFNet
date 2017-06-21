//
//  HttpRequset.h
//  AFNet
//
//  Created by Suger on 17/6/19.
//  Copyright © 2017年 Suger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>
#import "ZXSTool.h"
/***************************************************************************************/

//宏定义成功block 回调成功后得到的信息
typedef void (^HttpSuccess)(id data);
//宏定义失败block 回调失败信息
typedef void (^HttpFailure)(NSError *error);
/***************************************************************************************/

typedef void (^ZXSDownloadProgress)(int64_t bytesRead,
int64_t totalBytesRead);
typedef void (^ZXSUploadProgress)(int64_t bytesWritten,
int64_t totalBytesWritten);

typedef ZXSDownloadProgress ZXSGetProgress;
typedef ZXSDownloadProgress ZXSPostProgress;

typedef NS_ENUM(NSInteger, ZXSNetworkStatus) {
    ZXSBNetworkStatusUnknown          = -1,//未知网络
    ZXSBNetworkStatusNotReachable     = 0,//网络无连接
    ZXSBNetworkStatusReachableViaWWAN = 1,//2，3，4G网络
    ZXSBNetworkStatusReachableViaWiFi = 2,//WIFI网络
};


@class NSURLSessionTask;

// 请勿直接使用NSURLSessionDataTask,以减少对第三方的依赖
// 所有接口返回的类型都是基类NSURLSessionTask，若要接收返回值
// 且处理，请转换成对应的子类类型
typedef NSURLSessionTask ZXSURLSessionTask;
typedef void(^ZXSResponseSuccess)(id response);
typedef void(^ZXSResponseFail)(NSError *error);

typedef NS_ENUM(NSUInteger,ZXSResponseType) {
    ZXSResponseTypeJSON = 1, // 默认
    ZXSResponseTypeXML  = 2, // XML
    // 特殊情况下，一转换服务器就无法识别的，默认会尝试转换成JSON，若失败则需要自己去转换
    ZXSResponseTypeData = 3
};

typedef NS_ENUM(NSUInteger, ZXSRequestType) {
    ZXSRequestTypeJSON = 1, // 默认
    ZXSRequestTypePlainText  = 2 // 普通text/html
};




@interface HttpRequest : NSObject

/**
 *	设置请求超时时间，默认为60秒
 *
 *	@param timeout 超时时间
 */
+ (void)setTimeout:(NSTimeInterval)timeout;
/**
 *	@author 朱学森
 *
 *	获取缓存总大小/bytes
 *
 *	@return 缓存大小
 */
+ (unsigned long long)totalCacheSize;

/**
 *	@author 朱学森
 *
 *	默认只缓存GET请求的数据，对于POST请求是不缓存的。如果要缓存POST获取的数据，需要手动调用设置
 *  对JSON类型数据有效，对于PLIST、XML不确定！
 *
 *	@param isCacheGet			默认为YES
 *	@param shouldCachePost	默认为NO
 */
+ (void)cacheGetRequest:(BOOL)isCacheGet shoulCachePost:(BOOL)shouldCachePost;
/**
 *	默认不会自动清除缓存，如果需要，可以设置自动清除缓存，并且需要指定上限。当指定上限>0M时，
 *  若缓存达到了上限值，则每次启动应用则尝试自动去清理缓存。
 *
 *	@param mSize				缓存上限大小，单位为M（兆），默认为0，表示不清理
 */
+ (void)autoToClearCacheWithLimitedToSize:(NSUInteger)mSize;

/**
 *	@author 朱学森
 *
 *	清除缓存
 */
+ (void)clearCaches;
/*!
 *  @author 朱学森, 15-11-15 14:11:40
 *
 *  开启或关闭接口打印信息
 *
 *  @param isDebug 开发期，最好打开，默认是NO
 */
+ (void)enableInterfaceDebug:(BOOL)isDebug;
/*!
 *  @author 黄仪标, 17-2-25 15:12:45
 *
 *  配置请求格式，默认为JSON。如果要求传XML或者PLIST，请在全局配置一下
 *
 *  @param requestType 请求格式，默认为JSON
 *  @param responseType 响应格式，默认为JSO，
 *  @param shouldAutoEncode YES or NO,默认为NO，是否自动encode url
 *  @param shouldCallbackOnCancelRequest 当取消请求时，是否要回调，默认为YES
 */
+ (void)configRequestType:(ZXSRequestType)requestType
             responseType:(ZXSResponseType)responseType
      shouldAutoEncodeUrl:(BOOL)shouldAutoEncode
  callbackOnCancelRequest:(BOOL)shouldCallbackOnCancelRequest;
/*!
 *  @author 朱学森, 17-6-16 13:11:41
 *
 *  配置公共的请求头，只调用一次即可，通常放在应用启动的时候配置就可以了
 *
 *  @param httpHeaders 只需要将与服务器商定的固定参数设置即可
 */
+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders;
/**
 *	@author 黄仪标
 *
 *	取消所有请求
 */
+ (void)cancelAllRequest;
/**
 *	@author 黄仪标
 *
 *	取消某个请求。如果是要取消某个请求，最好是引用接口所返回来的HYBURLSessionTask对象，
 *  然后调用对象的cancel方法。如果不想引用对象，这里额外提供了一种方法来实现取消某个请求
 *
 *	@param url				URL，可以是绝对URL，也可以是path（也就是不包括baseurl）
 */
+ (void)cancelRequestWithURL:(NSString *)url;
/*!
 *  @author 黄仪标, 15-11-15 13:11:50
 *
 *  GET请求接口，若不指定baseurl，可传完整的url
 *
 *  @param url     接口路径，如/path/getArticleList
 *  @param refreshCache 是否刷新缓存。由于请求成功也可能没有数据，对于业务失败，只能通过人为手动判断
 *  @param params  接口中所需要的拼接参数，如@{"categoryid" : @(12)}
 *  @param success 接口成功请求到数据的回调
 *  @param fail    接口请求数据失败的回调
 *
 *  @return 返回的对象中有可取消请求的API
 */
+ (ZXSURLSessionTask *)getWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                          success:(ZXSResponseSuccess)success
                             fail:(ZXSResponseFail)fail;
// 多一个params参数
+ (ZXSURLSessionTask *)getWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSDictionary *)params
                          success:(ZXSResponseSuccess)success
                             fail:(ZXSResponseFail)fail;
// 多一个带进度回调
+ (ZXSURLSessionTask *)getWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSDictionary *)params
                         progress:(ZXSGetProgress)progress
                          success:(ZXSResponseSuccess)success
                             fail:(ZXSResponseFail)fail;
/*!
 *  @author 黄仪标, 15-11-15 13:11:50
 *
 *  POST请求接口，若不指定baseurl，可传完整的url
 *
 *  @param url     接口路径，如/path/getArticleList
 *  @param params  接口中所需的参数，如@{"categoryid" : @(12)}
 *  @param success 接口成功请求到数据的回调
 *  @param fail    接口请求数据失败的回调
 *
 *  @return 返回的对象中有可取消请求的API
 */
+ (ZXSURLSessionTask *)postWithUrl:(NSString *)url
                      refreshCache:(BOOL)refreshCache
                            params:(NSDictionary *)params
                           success:(ZXSResponseSuccess)success
                              fail:(ZXSResponseFail)fail;
+ (ZXSURLSessionTask *)postWithUrl:(NSString *)url
                      refreshCache:(BOOL)refreshCache
                            params:(NSDictionary *)params
                          progress:(ZXSPostProgress)progress
                           success:(ZXSResponseSuccess)success
                              fail:(ZXSResponseFail)fail;
/**
 *	@author 黄仪标, 16-01-31 00:01:40
 *
 *	图片上传接口，若不指定baseurl，可传完整的url
 *
 *	@param image			图片对象
 *	@param url				上传图片的接口路径，如/path/images/
 *	@param filename		给图片起一个名字，默认为当前日期时间,格式为"yyyyMMddHHmmss"，后缀为`jpg`
 *	@param name				与指定的图片相关联的名称，这是由后端写接口的人指定的，如imagefiles
 *	@param mimeType		默认为image/jpeg
 *	@param parameters	参数
 *	@param progress		上传进度
 *	@param success		上传成功回调
 *	@param fail				上传失败回调
 *
 *	@return
 */
+ (ZXSURLSessionTask *)uploadWithImage:(UIImage *)image
                                   url:(NSString *)url
                              filename:(NSString *)filename
                                  name:(NSString *)name
                              mimeType:(NSString *)mimeType
                            parameters:(NSDictionary *)parameters
                              progress:(ZXSUploadProgress)progress
                               success:(ZXSResponseSuccess)success
                                  fail:(ZXSResponseFail)fail;
/**
 *	@author 黄仪标, 16-01-31 00:01:59
 *
 *	上传文件操作
 *
 *	@param url						上传路径
 *	@param uploadingFile	待上传文件的路径
 *	@param progress			上传进度
 *	@param success				上传成功回调
 *	@param fail					上传失败回调
 *
 *	@return
 */
+ (ZXSURLSessionTask *)uploadFileWithUrl:(NSString *)url
                           uploadingFile:(NSString *)uploadingFile
                                progress:(ZXSUploadProgress)progress
                                 success:(ZXSResponseSuccess)success
                                    fail:(ZXSResponseFail)fail;
/*!
 *  @author 黄仪标, 16-01-08 15:01:11
 *
 *  下载文件
 *
 *  @param url           下载URL
 *  @param saveToPath    下载到哪个路径下
 *  @param progressBlock 下载进度
 *  @param success       下载成功后的回调
 *  @param failure       下载失败后的回调
 */
+ (ZXSURLSessionTask *)downloadWithUrl:(NSString *)url
                            saveToPath:(NSString *)saveToPath
                              progress:(ZXSDownloadProgress)progressBlock
                               success:(ZXSResponseSuccess)success
                               failure:(ZXSResponseFail)failure;


/***************************************************************************************/
#pragma mark 最简单的get  post 没有做任何缓存处理
//get请求
/**
 get请求
 
 @param urlString 网址
 @param success 成功回调
 @param failure 失败回调
 */
+(void)getWithUrlString:(NSString *)urlString
                success:(HttpSuccess)success
                failure:(HttpFailure)failure;

//post请求
/**
 post请求

 @param urlString 网址
 @param parameters 参数
 @param success 成功回调
 @param failure 失败回调
 */
+(void)postWithUrlString:(NSString *)urlString
              parameters:(NSDictionary *)parameters
                 success:(HttpSuccess)success
                 failure:(HttpFailure)failure;
/***************************************************************************************/

@end
