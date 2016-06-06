//
//  EUExWeiXin.h
//  WBPlam
//
//  Created by Xu Leilei on 13-3-5.
//  Copyright (c) 2013年 zywx. All rights reserved.
//


#import "WXApi.h"



@interface EUExWeiXin : EUExBase{
    NSMutableData * recivedData;
}

@property (nonatomic,strong) NSString * appID;
@property (nonatomic,strong) NSString * cbPayStr;
@property (nonatomic,strong) NSString *WXCheckAccessTokenErrcode;
@property (nonatomic,strong) NSMutableDictionary *access_tokenDict;
@property (nonatomic,strong) NSMutableDictionary *refreshAccessTokenDict;
@property (nonatomic,strong) NSMutableDictionary *userInfoDict;
@end
