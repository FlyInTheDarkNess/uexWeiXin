/**
 *
 *	@file   	: uexWeiXinResponder.m  in EUExWeiXin
 *
 *	@author 	: CeriNo 
 * 
 *	@date   	: Created on 15/12/30.
 *
 *	@copyright 	: 2015 The AppCan Open Source Project.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "uexWeiXinResponder.h"
#import "JSON.h"
#import "EUtility.h"
#import "EUExBaseDefine.h"

#define UEX_CALLBACK_NEW_FORMAT	-1


@implementation uexWeiXinResponder




+ (instancetype)sharedResponder{
    static uexWeiXinResponder *responder=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        responder=[[self alloc] init];
    });
    return responder;
}





- (void) onResp:(BaseResp*)resp{
    int errorCode = resp.errCode;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dispatch_queue_t globalQueue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    if ([resp isKindOfClass:[PayResp class]]) {
        
        
        
        PayResp *response = (PayResp *)resp;
        [dict setValue:@(errorCode) forKey:@"errCode"];
        if(response.errStr){
            [dict setValue:response.errStr forKey:@"errStr"];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), globalQueue, ^{
            [self callbackWithFunction:@"cbGotoPay" object:dict cbType:UEX_CALLBACK_DATATYPE_JSON];
            [self callbackWithFunction:@"cbSendPay" object:dict cbType:UEX_CALLBACK_DATATYPE_JSON];
            [self callbackWithFunction:@"cbStartPay" object:dict cbType:UEX_CALLBACK_NEW_FORMAT];
        });

        
    } else if ([resp isKindOfClass:[SendMessageToWXResp class]]) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), globalQueue, ^{
            [self cbWXShare:errorCode];
        });
        

    }
    else if([resp isKindOfClass:[SendAuthResp class]]) {
        SendAuthResp *authResp  = (SendAuthResp *)resp;
        NSMutableDictionary *result=[NSMutableDictionary dictionary];
        [result setValue:authResp.code forKey:@"code"];
        [result setValue:authResp.state forKey:@"state"];
        [result setValue:authResp.country forKey:@"country"];
        [result setValue:authResp.lang forKey:@"language"];
        [result setValue:@(authResp.errCode) forKey:@"errCode"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), globalQueue, ^{
            [self callbackWithFunction:@"cbLogin" object:result cbType:UEX_CALLBACK_NEW_FORMAT];
            [self callbackWithFunction:@"cbWeiXinLogin" object:@(errorCode) cbType:UEX_CALLBACK_DATATYPE_INT];
        });
        

    }

}




-(void)cbWXShare:(int)errorCode{
    NSNumber *code=@(errorCode);
    switch (self.currentShareType) {
        case uexWeiXinShareTypeUnknown: {
            break;
        }
        case uexWeiXinShareTypeTextContent: {
            [self callbackWithFunction:@"cbSendTextContent" object:code cbType:UEX_CALLBACK_DATATYPE_INT];
            break;
        }
        case uexWeiXinShareTypePicture: {
            [self callbackWithFunction:@"cbSendImageContent" object:code cbType:UEX_CALLBACK_DATATYPE_INT];
            break;
        }
        case uexWeiXinShareTypePhoto: {
            [self callbackWithFunction:@"cbShareImageContent" object:code cbType:UEX_CALLBACK_NEW_FORMAT];
            break;
        }
        case uexWeiXinShareTypeLink: {
            [self callbackWithFunction:@"cbShareLinkContent" object:code cbType:UEX_CALLBACK_NEW_FORMAT];
            break;
        }
        case uexWeiXinShareTypeText: {
            [self callbackWithFunction:@"cbShareTextContent" object:code cbType:UEX_CALLBACK_NEW_FORMAT];
            break;
        }
    }
}


#pragma mark - callback



- (void)callbackWithFunction:(NSString *)func object:(id)obj cbType:(NSInteger)type{
    NSString *cbData=nil;
    if ([obj isKindOfClass:[NSString class]] ) {
        cbData=obj;
    }else if([obj isKindOfClass:[NSNumber class]]){
        cbData=[obj stringValue];
    }else{
        cbData=[obj JSONValue];
    }
    if(!cbData){
        return;
    }
    
    NSString *JSONString;
    
    switch (type) {
        case 0:
        case 1:
        case 2:{
            JSONString=[NSString stringWithFormat:@"if (uexWeiXin.%@ != null){uexWeiXin.%@(0,%ld,'%@');}",func,func,(long)type,cbData];
            break;
        }
        default:{
            JSONString=[NSString stringWithFormat:@"if (uexWeiXin.%@ != null){uexWeiXin.%@('%@');}",func,func,cbData];
            break;
        }
    }
    
    [EUtility brwView:self.specifiedReceiver?:self.receiver evaluateScript:JSONString];
}


@end
