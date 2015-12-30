//
//  EUExWeiXin.h
//  WBPlam
//
//  Created by Xu Leilei on 13-3-5.
//  Copyright (c) 2013年 zywx. All rights reserved.
//

#import "EUExBase.h"
#import "WXApi.h"



@interface EUExWeiXin : EUExBase{
    NSMutableData * recivedData;
}

@property (nonatomic,copy) NSString * appID;
@property (nonatomic,copy) NSString * cbPayStr;
@property (nonatomic,copy) NSString *wxCode;
@property (nonatomic,copy) NSString *WXCheckAccessTokenErrcode;
@property (nonatomic,retain) NSMutableDictionary *access_tokenDict;
@property (nonatomic,retain) NSMutableDictionary *refreshAccessTokenDict;
@property (nonatomic,retain) NSMutableDictionary *userInfoDict;
@end
