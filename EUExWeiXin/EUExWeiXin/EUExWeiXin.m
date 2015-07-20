//
//  EUExWeiXin.m
//  WBPlam
//
//  Created by AppCan on 13-3-5.
//  Copyright (c) 2013年 AppCan. All rights reserved.
//

#import "EUExWeiXin.h"
#import "EUExBaseDefine.h"
#import "EUtility.h"
#import "JSON.h"
#import <CommonCrypto/CommonDigest.h>
#import "SBJSON.h"
#import "ApiXml.h"


@implementation EUExWeiXin{
    int  WXRespErrCode;
    NSString *weixinSecret;
    NSString *grant_type;
    
}

-(id)initWithBrwView:(EBrowserView *)eInBrwView{
    if (self=[super initWithBrwView:eInBrwView]) {
        
    }
    return self;
}

-(void)clean{
    
}

-(void)dealloc{
    [super dealloc];
}

#pragma mark -
#pragma mark - 微信支付

-(void)isSupportPay:(NSMutableArray *)inArguments {
    BOOL isSupportApi = [WXApi isWXAppSupportApi];
    if (isSupportApi) {
        [self jsSuccessWithName:@"uexWeiXin.cbIsSupportPay" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:0];
    }else {
        [self jsSuccessWithName:@"uexWeiXin.cbIsSupportPay" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:1];
    }
}

-(void)getAccessToken:(NSMutableArray *)inArguments {
    NSString *appid = [inArguments objectAtIndex:0];
    NSString *secret = [inArguments objectAtIndex:1];
    [self getDataAsynchronous:appid andSecret:secret];
}

-(void)getAccessTokenLocal:(NSMutableArray *)inArguments {
    NSString *uexWeiXin_access_token = nil;
    if ([[NSUserDefaults standardUserDefaults]  objectForKey:@"uexWeiXin_access_token"]) {
        uexWeiXin_access_token = [[NSUserDefaults standardUserDefaults]  objectForKey:@"uexWeiXin_access_token"];
    }
    [self jsSuccessWithName:@"uexWeiXin.cbGetAccessTokenLocal" opId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT strData:uexWeiXin_access_token];
}

-(void)generateAdvanceOrder:(NSMutableArray *)inArguments {
    NSString *accessTocken = [inArguments objectAtIndex:0];
    NSString *varStr = [inArguments objectAtIndex:1];
    //第一步，创建url
    NSString *urlStr = [NSString stringWithFormat:@"https://api.weixin.qq.com/pay/genprepay?access_token=%@",accessTocken];
    NSURL *url = [NSURL URLWithString:urlStr];
    
    //第二步，创建请求
    NSMutableURLRequest *requests = [[NSMutableURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    [requests setHTTPMethod:@"POST"];
    NSData *data = [varStr dataUsingEncoding:NSUTF8StringEncoding];
    [requests setHTTPBody:data];
    [requests setTimeoutInterval:60000];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:requests delegate:self];
    [requests release];
}

-(void)gotoPay:(NSMutableArray *)inArguments {
    NSString * _pactnerid = [inArguments objectAtIndex:0];
    NSString * _prapayid = [inArguments objectAtIndex:1];
    NSString * _package = [inArguments objectAtIndex:2];
    NSString * _noncestr = [inArguments objectAtIndex:3];
    NSString * _timestamp = [inArguments objectAtIndex:4];
    NSString * _sign = [inArguments objectAtIndex:5];
    PayReq *request = [[[PayReq alloc] init] autorelease];
    request.partnerId = _pactnerid;
    request.prepayId = _prapayid;
    request.package = _package;
    request.nonceStr = _noncestr;
    request.timeStamp = [_timestamp intValue];
    request.sign = _sign;
    
    BOOL result = [WXApi safeSendReq:request];
}



//*******20141013==xrg==代替generateAdvanceOrder和gotoPay方法*********

//代替generateAdvanceOrder
-(void)generatePrepayID:(NSMutableArray *)inArguments{
    NSString * accessTocken = [inArguments objectAtIndex:0];
    NSString * app_key = [inArguments objectAtIndex:1];
    NSString * packageValue = [inArguments objectAtIndex:2];
    NSString * traceId = @"crestxu";
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count] == 4) {
        traceId = [inArguments objectAtIndex:3];
    }
    
    NSString * timeStamp = [self getTimeStamp];
    NSString * nonceStr = [self getNonceStr];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:self.appID forKey:@"appid"];
    [params setObject:app_key forKey:@"appkey"];
    [params setObject:nonceStr forKey:@"noncestr"];
    [params setObject:packageValue forKey:@"package"];
    [params setObject:timeStamp forKey:@"timestamp"];
    [params setObject:[self getTraceId] forKey:@"traceid"];
    
    [params setObject:[self getSign:params] forKey:@"app_signature"];
    
    [params setObject:@"sha1" forKey:@"sign_method"];
    [params removeObjectForKey:@"appkey"];
    NSString *jsonString = [params JSONFragment];
//    SBJsonWriter *jsonWriter = [[SBJsonWriter alloc] init];
//    NSString *jsonString = [jsonWriter stringWithObject:params];
//    [params removeAllObjects];
//    [params release];
//    [jsonWriter release];
    //第一步，创建url
    NSString *urlStr = [NSString stringWithFormat:@"https://api.weixin.qq.com/pay/genprepay?access_token=%@",accessTocken];
    NSURL *url = [NSURL URLWithString:urlStr];
    //第二步，创建请求
    NSMutableURLRequest *requests = [[NSMutableURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    [requests setHTTPMethod:@"POST"];
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
//    NSError *error = nil;
//    NSData * jsData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error: &error];
//    NSMutableData * data = [NSMutableData dataWithData:jsData];
    [requests setHTTPBody:data];
    [requests setTimeoutInterval:60000];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:requests delegate:self];
    [requests release];
}

//代替gotoPay
-(void)sendPay:(NSMutableArray *)inArguments{
    NSString * partnerId = [inArguments objectAtIndex:0];
    NSString * prepayid = [inArguments objectAtIndex:1];
    NSString * app_key = [inArguments objectAtIndex:2];
    NSString * packageValue = [inArguments objectAtIndex:3];
    
    NSString * nonceStr = [self getNonceStr];
    NSString * timeStamp = [self getTimeStamp];
    
    
    
    PayReq *request = [[[PayReq alloc] init] autorelease];
    request.partnerId = partnerId;
    request.prepayId = prepayid;
    request.package = @"Sign=WXPay";
    request.nonceStr = nonceStr;
    request.timeStamp = [timeStamp intValue];
    
    // 构造参数列表
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:self.appID forKey:@"appid"];
    [params setObject:app_key forKey:@"appkey"];
    [params setObject:nonceStr forKey:@"noncestr"];
    [params setObject:@"Sign=WXPay" forKey:@"package"];
    [params setObject:partnerId forKey:@"partnerid"];
    [params setObject:prepayid forKey:@"prepayid"];
    [params setObject:timeStamp forKey:@"timestamp"];
    request.sign = [self getSign:params];
    
    BOOL result = [WXApi safeSendReq:request];
    NSLog(@"result===%d",result);
}

- (NSString *)getTraceId
{
    return [NSString stringWithFormat:@"crestxu_%@", [self getTimeStamp]];
}

- (NSString *)getSign:(NSDictionary *)signParams {
    // 排序
    NSArray *keys = [signParams allKeys];
    NSArray *sortedKeys = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    
    // 生成
    NSMutableString *sign = [NSMutableString string];
    for (NSString *key in sortedKeys) {
        [sign appendString:key];
        [sign appendString:@"="];
        [sign appendString:[signParams objectForKey:key]];
        [sign appendString:@"&"];
    }
    NSString *signString = [[sign copy] substringWithRange:NSMakeRange(0, sign.length - 1)];
    
    NSString *result = [self sha1_1:signString];
    return result;
}




- (NSString *)getTimeStamp {
    return [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
}

- (NSString *)getNonceStr {
    return [self md5:[NSString stringWithFormat:@"%d", arc4random() % 10000]];
}

- (NSString *)md5:(NSString *)input {
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}

- (NSString*) sha1_1:(NSString *)input
{
    const char *cstr = [input UTF8String];
    int length = strlen(cstr);
    
    NSData *data = [NSData dataWithBytes:cstr length:length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}


//2015-6-4 by lkl
#pragma mark - **************3.0.14版本新增 微信支付相关接口 旧接口废弃***************

- (id)getDataFromJson:(NSString *)jsonStr{
    
    
    
    NSError *error = nil;

    NSData *jsonData= [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                     
                                                    options:NSJSONReadingMutableContainers
                     
                                                      error:&error];

    if (jsonObject != nil && error == nil){
        return jsonObject;
    }else{
        // 解析錯誤
        return nil;
    }
    
}
-(void) returnJsonWithName:(NSString *)name Object:(id)obj{

    NSString *result=[obj JSONFragment];
    NSString *jsonStr = [NSString stringWithFormat:@"if(uexWeiXin.%@ != null){uexWeiXin.%@('%@');}",name,name,result];
    

    [meBrwView stringByEvaluatingJavaScriptFromString:jsonStr];
}


#pragma mark - 生成预支付订单


-(void)getPrepayId:(NSMutableArray *)inArgument{
    if([inArgument count]<1) return;
    id dataDict=[self getDataFromJson:inArgument[0]];
    if(![dataDict isKindOfClass:[NSDictionary class]]) return;
    NSMutableString *sendXML=[NSMutableString string];
    NSArray *keys = [dataDict allKeys];
    [sendXML appendString:@"<xml>\n"];
    for (NSString *categoryId in keys) {
        [sendXML appendFormat:@"<%@>%@</%@>\n", categoryId, [dataDict objectForKey:categoryId],categoryId];
    }
     [sendXML appendFormat:@"</xml>"];
     NSData *res = [EUExWeiXin httpSend:@"https://api.mch.weixin.qq.com/pay/unifiedorder" method:@"POST" data:sendXML];
    XMLHelper *xml  = [[XMLHelper alloc] autorelease];
    
    //开始解析
    [xml startParse:res];
    
    NSMutableDictionary *resultDict = [xml getDict];

    [self returnJsonWithName:@"cbGetPrepayId" Object:resultDict];

}
#pragma mark - 发起支付
-(void)startPay:(NSMutableArray *)inArgument{
    if([inArgument count]<1) return;
    id dataDict=[self getDataFromJson:inArgument[0]];
    if(![dataDict isKindOfClass:[NSDictionary class]]) return;
    
    
    NSMutableString *stamp  = [dataDict objectForKey:@"timestamp"];
    
    //调起微信支付
    PayReq* req             = [[[PayReq alloc] init]autorelease];
    
 
    req.openID              = [dataDict objectForKey:@"appid"];
    req.partnerId           = [dataDict objectForKey:@"partnerid"];
    req.prepayId            = [dataDict objectForKey:@"prepayid"];
    req.nonceStr            = [dataDict objectForKey:@"noncestr"];
    req.timeStamp           = stamp.intValue;
    req.package             = [dataDict objectForKey:@"package"];
    req.sign                = [dataDict objectForKey:@"sign"];

    
    [WXApi sendReq:req];
     
   
}




#pragma mark -



//http 请求
+(NSData *) httpSend:(NSString *)url method:(NSString *)method data:(NSString *)data
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5];
    //设置提交方式
    [request setHTTPMethod:method];
    //设置数据类型
    [request addValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    //设置编码
    [request setValue:@"UTF-8" forHTTPHeaderField:@"charset"];
    //如果是POST
    [request setHTTPBody:[data dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSError *error;
    //将请求的url数据放到NSData对象中
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
    return response;
    //return [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
}

//*************************************************************

#pragma mark -
#pragma mark - requestFuctions

//异步get
-(void)getDataAsynchronous:(NSString *)appid andSecret:(NSString*)secret{
    NSString *str = [NSString stringWithFormat:@"https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=%@&secret=%@",appid,secret];
    NSURL *url = [NSURL URLWithString:str];
    NSMutableURLRequest *requests = [[NSMutableURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
    [requests setHTTPMethod:@"GET"];
    [requests setTimeoutInterval:60000];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:requests delegate:self];
    //    [requests release];
}
#pragma mark -
#pragma mark - Asynchronous delegate

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response{
    if (recivedData){
        recivedData = nil;
    }else{
        recivedData = [[NSMutableData alloc] initWithCapacity:1];
    }
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [recivedData appendData:data];
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *reciveStr = [[NSString alloc] initWithData:recivedData encoding:NSASCIIStringEncoding];
    NSURL *connUrl = connection.currentRequest.URL;
    NSString *strUrl = [connUrl absoluteString];
    NSRange range = [strUrl rangeOfString:@"&appid="];
    if (7 == range.length) {
        //获取token的请求
        if (reciveStr) {
            NSMutableDictionary *dict = [reciveStr JSONValue];
            NSString *access_token = [dict objectForKey:@"access_token"];
            [[NSUserDefaults standardUserDefaults] setObject:access_token forKey:@"uexWeiXin_access_token"];
        }
        [self jsSuccessWithName:@"uexWeiXin.cbGetAccessToken" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:reciveStr];
    }else {
        range = [strUrl rangeOfString:@"?access_token="];
        if (14 == range.length) {
            //生产预支付订单的请求
            [self jsSuccessWithName:@"uexWeiXin.cbGenerateAdvanceOrder" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:reciveStr];
            [self jsSuccessWithName:@"uexWeiXin.cbGeneratePrepayID" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:reciveStr];
        }
    }
    [connection release];
    if (recivedData) {
        recivedData = nil;
    }
    [reciveStr release];
}
//网络请求过程中，出现任何错误（断网，连接超时等）会进入此方法
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSURL *connUrl = connection.currentRequest.URL;
    NSString *strUrl = [connUrl absoluteString];
    NSRange range = [strUrl rangeOfString:@"&appid="];
    if (7 == range.length) {
        NSString *maxApiVer = @"获取access_token失败";
        [self jsSuccessWithName:@"uexWeiXin.cbGetAccessToken" opId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT strData:maxApiVer];
    }else {
        range = [strUrl rangeOfString:@"?access_token="];
        if (14 == range.length) {
            NSString *maxApiVer = @"生成预付订单失败";
            [self jsSuccessWithName:@"uexWeiXin.cbGenerateAdvanceOrder" opId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT strData:maxApiVer];
            [self jsSuccessWithName:@"uexWeiXin.cbGeneratePrepayID" opId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT strData:maxApiVer];
        }
    }
    [connection release];
}
#pragma mark -
#pragma mark - 微信分享
-(void)registerApp:(NSMutableArray *)inArguments{
    NSString *appid = [inArguments objectAtIndex:0];
    self.appID = appid;
    BOOL status = [WXApi registerApp:appid];
    if (status) {
        [self jsSuccessWithName:@"uexWeiXin.cbRegisterApp" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
    }else{
        [self jsSuccessWithName:@"uexWeiXin.cbRegisterApp" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
    }
}
-(void)isWXAppInstalled:(NSMutableArray *)inArguments{
    BOOL isInstalled = [WXApi isWXAppInstalled];
    if (isInstalled) {
        [self jsSuccessWithName:@"uexWeiXin.cbIsWXAppInstalled" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
    }else{
        [self jsSuccessWithName:@"uexWeiXin.cbIsWXAppInstalled" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
    }
}
-(void)isWXAppSupportApi:(NSMutableArray *)inArguments{
    BOOL isSupport = [WXApi isWXAppSupportApi];
    if (isSupport) {
        [self jsSuccessWithName:@"uexWeiXin.cbIsWXAppSupportApi" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
    }else{
        [self jsSuccessWithName:@"uexWeiXin.cbIsWXAppSupportApi" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
    }
}
-(void)getApiVersion:(NSMutableArray *)inArguments{
    NSString *sdkVer = [WXApi getApiVersion];
    [self jsSuccessWithName:@"uexWeiXin.cbGetApiVersion" opId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT strData:sdkVer];
}

-(void)getWXAppInstallUrl:(NSMutableArray *)inArguments{
    NSString *installUrl = [WXApi getWXAppInstallUrl];
    [self jsSuccessWithName:@"uexWeiXin.cbGetWXAppInstallUrl" opId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT strData:installUrl];
}
-(void)openWXApp:(NSMutableArray *)inArguments{
    BOOL canOpen = [WXApi openWXApp];
    if (canOpen) {
        [self jsSuccessWithName:@"uexWeiXin.cbOpenWXApp" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
    }else{
        [self jsSuccessWithName:@"uexWeiXin.cbOpenWXApp" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
    }
}
//********************************微信授权登录*********************
#pragma mark -- 微信登录授权
- (void)weiXinLogin:(NSMutableArray *)inArguments {
    
    if (inArguments.count >0) {
        SendAuthReq* req =[[SendAuthReq alloc ] init];
        req.scope = [inArguments objectAtIndex:0];
        if (inArguments.count >1) {
            req.state = [inArguments objectAtIndex:1];
        }
        BOOL suc =  [WXApi sendReq:req];
    }else {
        return;
    }
}

#pragma mark -- 获取AccessToken
- (void)getWeiXinLoginAccessToken:(NSMutableArray *)inArguments {
    if (inArguments.count>1) {
        weixinSecret = [inArguments objectAtIndex:0];
        grant_type = [inArguments objectAtIndex:1];
    }
    
    [self getAccess_token];
}
- (void)getAccess_token {
    
    NSString *url =[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=%@",self.appID,weixinSecret,_wxCode,grant_type];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *zoneUrl = [NSURL URLWithString:url];
        NSString *zoneStr = [NSString stringWithContentsOfURL:zoneUrl encoding:NSUTF8StringEncoding error:nil];
        NSData *data = [zoneStr dataUsingEncoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                self.access_tokenDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                [self performSelector:@selector(cbGetWXLoginAccessToken) withObject:self afterDelay:0.5];
            }
        });
    });
}

- (void)cbGetWXLoginAccessToken {
    
    NSString *access_tokenJson =[NSString stringWithFormat:@"%@",[self.access_tokenDict JSONFragment]];
    // NSLog(@"access_tokenJson------>>%@",access_tokenJson);
    
    [self jsSuccessWithName:@"uexWeiXin.cbGetWeiXinLoginAccessToken"opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:access_tokenJson];
}

#pragma  mark -- 检验access_token是否有效
- (void)getWeiXinLoginCheckAccessToken:(NSMutableArray *)inArguments{
    
    if (inArguments.count >1) {
        NSString *access_token = [inArguments objectAtIndex:0];
        NSString *openid = [inArguments objectAtIndex:1];
        NSString *url =[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/auth?access_token=%@&openid=%@",access_token,openid];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *zoneUrl = [NSURL URLWithString:url];
            NSString *zoneStr = [NSString stringWithContentsOfURL:zoneUrl encoding:NSUTF8StringEncoding error:nil];
            NSData *data = [zoneStr dataUsingEncoding:NSUTF8StringEncoding];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (data) {
                    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                    self.WXCheckAccessTokenErrcode = [dict objectForKey:@"errcode"];
                    
                    [self performSelector:@selector(cbGetWXLoginCheckAccessToken) withObject:self afterDelay:0.5];
                }
            });
            
        });
    }
}
- (void)cbGetWXLoginCheckAccessToken {
    if(self.WXCheckAccessTokenErrcode == 0){
        [self jsSuccessWithName:@"uexWeiXin.cbGetWeiXinLoginCheckAccessToken"  opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
    }else{
        [self jsSuccessWithName:@"uexWeiXin.cbGetWeiXinLoginCheckAccessToken"  opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFALSE];
    }
    
}

#pragma mark -- 刷新RefreshAccessToken
- (void)getWeiXinLoginRefreshAccessToken:(NSMutableArray *)inArguments{
    
    if (inArguments.count >1) {
        NSString *grantType  = [inArguments objectAtIndex:0];
        NSString *refresh_token = [inArguments objectAtIndex:1];
        
        NSString *url =[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/refresh_token?appid=%@&grant_type=%@&refresh_token=%@",self.appID,grantType,refresh_token];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *zoneUrl = [NSURL URLWithString:url];
            NSString *zoneStr = [NSString stringWithContentsOfURL:zoneUrl encoding:NSUTF8StringEncoding error:nil];
            NSData *data = [zoneStr dataUsingEncoding:NSUTF8StringEncoding];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (data) {
                    self.refreshAccessTokenDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                    //NSLog(@"------>>>>%@", self.refreshAccessTokenDict);
                    [self performSelector:@selector(cbGetWXLoginRefreshAccessToken) withObject:self afterDelay:0.5];
                }
            });
            
        });
    }
}

- (void) cbGetWXLoginRefreshAccessToken {
    [self jsSuccessWithName:@"uexWeiXin.cbGetWeiXinLoginRefreshAccessToken" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:[self.refreshAccessTokenDict JSONFragment]];
}

#pragma mark -- 获取个人信息
- (void)getWeiXinLoginUnionID:(NSMutableArray *)inArguments {
    
    if (inArguments.count >1) {
        NSString *access_token = [inArguments objectAtIndex:0];
        NSString *openid = [inArguments objectAtIndex:1];
        [self getUserInfo:access_token openID:openid];
    }else{
        return;
    }
}
- (void)getUserInfo:(NSString *)accesstoken openID:(NSString *)openid {
    
    NSString *url =[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?access_token=%@&openid=%@",accesstoken,openid];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *zoneUrl = [NSURL URLWithString:url];
        NSString *zoneStr = [NSString stringWithContentsOfURL:zoneUrl encoding:NSUTF8StringEncoding error:nil];
        NSData *data = [zoneStr dataUsingEncoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                self.userInfoDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                // NSLog(@"self.userInfoDict------>>>>%@", self.userInfoDict);
                [self performSelector:@selector(cbGetWXLoginUnionID) withObject:self afterDelay:0.5];
            }
        });
        
    });
}

- (void)cbGetWXLoginUnionID {
    [self jsSuccessWithName:@"uexWeiXin.cbGetWeiXinLoginUnionID"opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:[self.userInfoDict JSONFragment]];
}

-(void)sendTextContent:(NSMutableArray *)inArguments{
    // 0 会话
    // 1 场景
    SendMessageToWXReq* req = [[[SendMessageToWXReq alloc] init]autorelease];
    req.bText = YES;
    req.text = [inArguments objectAtIndex:1];
    req.scene = [[inArguments objectAtIndex:0] intValue];
    currentSelected = WXTextContent;
    [WXApi sendReq:req];
}

- (void) sendImageContent:(NSMutableArray *)inArguments{
    int scene = [[inArguments objectAtIndex:0] intValue];
    //本地,url
    //32K
    NSString *thumbImgPath = [inArguments objectAtIndex:1];
    NSString *realImgPath = [self absPath:[inArguments objectAtIndex:2]];
    
    WXMediaMessage *message = [WXMediaMessage message];
    if (![thumbImgPath hasPrefix:@"http"]) {
        thumbImgPath = [self absPath:thumbImgPath];
        UIImage * imgTemp =[UIImage imageWithContentsOfFile:thumbImgPath];
        [message setThumbImage:imgTemp];
    }
    else {
        NSURL * imgURL=[NSURL URLWithString:thumbImgPath];
        NSData *imageData=[NSData dataWithContentsOfURL:imgURL];
        [message setThumbData:imageData];
    }
    if ([[inArguments objectAtIndex:2]length]!=0) {
        WXImageObject *ext = [WXImageObject object];
        if ([realImgPath hasPrefix:@"http"]){
            NSURL * imgURL=[NSURL URLWithString:realImgPath];
            NSData *imageData=[NSData dataWithContentsOfURL:imgURL];
            [ext setImageData:imageData];
        }else{
            NSData * dataImage=[NSData dataWithContentsOfFile:realImgPath];
            [ext setImageData:dataImage];
        }
        message.mediaObject  = ext;
    }else{
        WXWebpageObject * ext = [WXWebpageObject object];
        NSString * url = [inArguments objectAtIndex:3];
        [ext setWebpageUrl:url];
        message.mediaObject = ext;
    }
    if ([inArguments count] > 4) {
        NSString * title =  [inArguments objectAtIndex:4];
        [message setTitle:title];
    }
    if ([inArguments count] > 5) {
        NSString * descrip =  [inArguments objectAtIndex:5];
        [message setDescription:descrip];
    }
    SendMessageToWXReq *req = [[[SendMessageToWXReq alloc] init]autorelease];
    req.bText = NO;
    req.message = message;
    req.scene = scene;
   [WXApi sendReq:req];
    currentSelected = WXPic;
}
/////////////////新增接口//////////////////////////////
-(void)shareTextContent:(NSMutableArray *)inArguments{
    
    NSString *jsonData = nil;
    if ([inArguments count] > 0) {
        jsonData = [inArguments objectAtIndex:0];
    }
    
    NSMutableDictionary *jsonDataDict = [jsonData JSONValue];
    int scene ;
    NSString *text = nil;
    
    scene = [[jsonDataDict objectForKey:@"scene"] intValue];
    text = [jsonDataDict objectForKey:@"text"];

    SendMessageToWXReq* req = [[[SendMessageToWXReq alloc] init]autorelease];
    req.bText = YES;
    req.text = text;
    req.scene = scene;
    currentSelected = WXText;
    [WXApi sendReq:req];
}

- (void)shareLinkContent:(NSMutableArray *)inArguments{
    
    NSString *jsonData = nil;

    if ([inArguments count] > 0) {
      jsonData = [inArguments objectAtIndex:0];
    }
    
    NSMutableDictionary *jsonDataDict = [jsonData JSONValue];
    int scene ;
    NSString *thumbImg = nil;
    NSString *wedpageUrl = nil;
    NSString *title =nil;
    NSString *description =nil;
    
    scene = [[jsonDataDict objectForKey:@"scene"] intValue];
    thumbImg = [jsonDataDict objectForKey:@"thumbImg"];
    wedpageUrl = [jsonDataDict objectForKey:@"wedpageUrl"];
    title = [jsonDataDict objectForKey:@"title"];
    description = [jsonDataDict objectForKey:@"description"];
    
    WXMediaMessage *message = [WXMediaMessage message];
    //本地,url
    //32
    if (![thumbImg hasPrefix:@"http"]) {
        thumbImg = [self absPath:thumbImg];
        UIImage * imgTemp = [UIImage imageWithContentsOfFile:thumbImg];
        [message setThumbImage:imgTemp];
    }
    else {
        
        NSURL *imgURL = [NSURL URLWithString:thumbImg];
        NSData *imageData = [NSData dataWithContentsOfURL:imgURL];
        [message setThumbData:imageData];
    }
        [message setTitle:title];
        [message setDescription:description];
        WXWebpageObject * ext = [WXWebpageObject object];
        [ext setWebpageUrl:wedpageUrl];
        message.mediaObject = ext;
    
    SendMessageToWXReq *req = [[[SendMessageToWXReq alloc] init]autorelease];
    req.bText = NO;
    req.message = message;
    req.scene = scene;
    [WXApi sendReq:req];
    currentSelected = WXLink;
}

- (void)shareImageContent:(NSMutableArray *)inArguments {
    NSString *jsonData = nil;
    if ([inArguments count] > 0) {
        jsonData = [inArguments objectAtIndex:0];
    }
    
    NSMutableDictionary *jsonDataDict = [jsonData JSONValue];
    int scene ;
    NSString *thumbImg = nil;
    NSString *image = nil;
    scene = [[jsonDataDict objectForKey:@"scene"] intValue];
    thumbImg = [jsonDataDict objectForKey:@"thumbImg"];
    thumbImg = [self absPath:thumbImg];
    image = [jsonDataDict objectForKey:@"image"];
    image = [self absPath:image];
    //32K
    WXMediaMessage *message = [WXMediaMessage message];
    
    if ([image length]!=0) {
        WXImageObject *ext = [WXImageObject object];
        NSData *imageData = [self getImageDataByPath:image];
        NSData *thumbImageData = [self getImageDataByPath:thumbImg];
        //缩略图     //32K
        [message setThumbImage:[UIImage imageWithData:thumbImageData]];
        //大图   //大小不能超过10M
        [ext setImageData:imageData];
        // UIImage* image = [UIImage imageWithData:ext.imageData];
        // ext.imageData = UIImagePNGRepresentation(image);
        message.title = @"微信";
        message.mediaObject  = ext;
        SendMessageToWXReq *req = [[[SendMessageToWXReq alloc] init]autorelease];
        req.bText = NO;
        req.message = message;
        req.scene = scene;
        [WXApi sendReq:req];
        currentSelected = WXPhoto;
    }
}

-(NSData *)getImageDataByPath:(NSString *)imagePath {
    
    NSData *imageData = nil;
    if ([imagePath hasPrefix:@"http"]) {
       NSURL *imagePathURL = [NSURL URLWithString:imagePath];
       imageData = [NSData dataWithContentsOfURL:imagePathURL];
        
    } else {
        
      imageData = [NSData dataWithContentsOfFile:imagePath];
    }
    return imageData;
}














#pragma mark -
#pragma mark - private




- (void)parseURL:(NSURL *)url application:(UIApplication *)application {
    [WXApi handleOpenURL:url delegate:self];
} 



- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [WXApi handleOpenURL:url delegate:self];
}





-(void)onResp:(BaseResp *)resp {
    WXRespErrCode = resp.errCode;
    
    if ([resp isKindOfClass:[PayResp class]]) {
        
        
        
        PayResp *response = (PayResp *)resp;
        
        
        if (response.errStr) {
            self.cbPayStr = [NSString stringWithFormat:@"{\"errCode\":\"%d\",\"errStr\":\"%@\"}",response.errCode, response.errStr];
        }else{
            self.cbPayStr = [NSString stringWithFormat:@"{\"errCode\":\"%d\",\"errStr\":\"\"}",response.errCode];
        }
        [self performSelector:@selector(cbPay) withObject:self afterDelay:1.0];
        
    } else if ([resp isKindOfClass:[SendMessageToWXResp class]]) {
          //延迟回调
        [self performSelector:@selector(cbWXShare) withObject:self afterDelay:1.0];
    }
    else if([resp isKindOfClass:[SendAuthResp class]]) {
        SendAuthResp *authResp  = (SendAuthResp *)resp;
        self.wxCode = authResp.code;
        [self performSelector:@selector(cbWeiXinLogin) withObject:self afterDelay:1.0];
        
    }
}
- (void)cbWeiXinLogin {
    
    [self jsSuccessWithName:@"uexWeiXin.cbWeiXinLogin" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:WXRespErrCode];
}

-(void)cbPay{
    [self jsSuccessWithName:@"uexWeiXin.cbGotoPay" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:self.cbPayStr];
    [self jsSuccessWithName:@"uexWeiXin.cbSendPay" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:self.cbPayStr];
    NSString *cbStr=[NSString stringWithFormat:@"if(uexWeiXin.cbStartPay!=null){uexWeiXin.cbStartPay('%@');}",self.cbPayStr];
    [meBrwView stringByEvaluatingJavaScriptFromString:cbStr];
    //[self jsSuccessWithName:@"uexWeiXin.cbStartPay" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:self.cbPayStr];
}

-(void)cbWXShare{
     switch (currentSelected) {
        case WXTextContent:
          [self jsSuccessWithName:@"uexWeiXin.cbSendTextContent" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:WXRespErrCode];
        break;
        case WXPic:
          [self jsSuccessWithName:@"uexWeiXin.cbSendImageContent" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:WXRespErrCode];
        break;
         ////新增/////
        case WXPhoto:
          //[self jsSuccessWithName:@"uexWeiXin.cbShareImageContent" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:WXRespErrCode];
         {
             NSString *jsString = [NSString stringWithFormat:@"uexWeiXin.cbShareImageContent(\"%d\");",WXRespErrCode];
             [self.meBrwView stringByEvaluatingJavaScriptFromString:jsString];
         }

         break;
         case WXLink:
          // [self jsSuccessWithName:@"uexWeiXin.cbShareLinkContent" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:WXRespErrCode];
         {
             NSString *jsString = [NSString stringWithFormat:@"uexWeiXin.cbShareLinkContent(\"%d\");",WXRespErrCode];
             [self.meBrwView stringByEvaluatingJavaScriptFromString:jsString];
         }

         break;
         case WXText:
          //[self jsSuccessWithName:@"uexWeiXin.cbShareTextContent" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:WXRespErrCode];
         {
             NSString *jsString = [NSString stringWithFormat:@"uexWeiXin.cbShareTextContent(\"%d\");",WXRespErrCode];
             [self.meBrwView stringByEvaluatingJavaScriptFromString:jsString];
         }
         break;
             
        default:
        break;
    }
}






@end
