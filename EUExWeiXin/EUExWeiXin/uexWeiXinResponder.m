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
            [self callbackWithFunction:@"cbGotoPay" object:dict cbType:UEX_CALLBACK_DATATYPE_JSON FunctionRef:self.func];
            [self callbackWithFunction:@"cbSendPay" object:dict cbType:UEX_CALLBACK_DATATYPE_JSON FunctionRef:self.func];
            [self callbackWithFunction:@"cbStartPay" object:dict cbType:UEX_CALLBACK_NEW_FORMAT FunctionRef:self.func];
        });

        
    } else if ([resp isKindOfClass:[SendMessageToWXResp class]]) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), globalQueue, ^{
            [self cbWXShare:errorCode];
        });
        

    }
    else if([resp isKindOfClass:[SendAuthResp class]]) {
        SendAuthResp *authResp  = (SendAuthResp *)resp;
        self.loginCode=authResp.code;
        NSMutableDictionary *result=[NSMutableDictionary dictionary];
        [result setValue:authResp.code forKey:@"code"];
        [result setValue:authResp.state forKey:@"state"];
        [result setValue:authResp.country forKey:@"country"];
        [result setValue:authResp.lang forKey:@"language"];
        [result setValue:@(authResp.errCode) forKey:@"errCode"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), globalQueue, ^{
            [self callbackWithFunction:@"cbLogin" object:result cbType:UEX_CALLBACK_NEW_FORMAT FunctionRef:self.func];
            [self callbackWithFunction:@"cbWeiXinLogin" object:@(errorCode) cbType:UEX_CALLBACK_DATATYPE_INT FunctionRef:self.func];
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
            [self callbackWithFunction:@"cbSendTextContent" object:code cbType:UEX_CALLBACK_DATATYPE_INT FunctionRef:self.func];
            break;
        }
        case uexWeiXinShareTypePicture: {
            [self callbackWithFunction:@"cbSendImageContent" object:code cbType:UEX_CALLBACK_DATATYPE_INT FunctionRef:self.func];
            break;
        }
        case uexWeiXinShareTypePhoto: {
            [self callbackWithFunction:@"cbShareImageContent" object:code cbType:UEX_CALLBACK_NEW_FORMAT FunctionRef:self.func];
            break;
        }
        case uexWeiXinShareTypeLink: {
            [self callbackWithFunction:@"cbShareLinkContent" object:code cbType:UEX_CALLBACK_NEW_FORMAT FunctionRef:self.func];
            break;
        }
        case uexWeiXinShareTypeText: {
            [self callbackWithFunction:@"cbShareTextContent" object:code cbType:UEX_CALLBACK_NEW_FORMAT FunctionRef:self.func];
            break;
        }
        case uexWeiXinShareTypeVideo: {
            [self callbackWithFunction:@"cbShareVideoContent" object:code cbType:UEX_CALLBACK_NEW_FORMAT FunctionRef:self.func];
            break;
        }
        case uexWeiXinShareTypeMusic: {
            [self callbackWithFunction:@"cbShareMusicContent" object:code cbType:UEX_CALLBACK_NEW_FORMAT FunctionRef:self.func];
            break;
        }
    }
}


#pragma mark - callback



- (void)callbackWithFunction:(NSString *)func object:(id)obj cbType:(NSInteger)type FunctionRef:(ACJSFunctionRef*)fun{
    NSString *cbDataString=nil;
    id cbDataJson = nil;
    if ([obj isKindOfClass:[NSString class]] ) {
        cbDataString=obj;
        cbDataJson = [obj JSONValue];
    }else if([obj isKindOfClass:[NSNumber class]]){
        cbDataString = obj;
        cbDataJson = obj;
    }else{
        cbDataString=[obj JSONFragment];
        cbDataJson = obj;
    }
    if(!cbDataString || !cbDataJson){
        return;
    }
    
    NSString *JSONString;
    JSONString=[NSString stringWithFormat:@"uexWeiXin.%@",func];
   
    switch (type) {
        case 0:
        case 1:
        case 2:{
            ///JSONString=[NSString stringWithFormat:@"if (uexWeiXin.%@ != null){uexWeiXin.%@(0,%ld,'%@');}",func,func,(long)type,cbData];
             [self.specifiedReceiver?:self.receiver callbackWithFunctionKeyPath:JSONString arguments:ACArgsPack(@0,@(type),cbDataString)];
            [fun executeWithArguments:ACArgsPack(cbDataJson)];
           
            break;
        }
        default:{
            //JSONString=[NSString stringWithFormat:@"if (uexWeiXin.%@ != null){uexWeiXin.%@('%@');}",func,func,cbData];
            
             [self.specifiedReceiver?:self.receiver callbackWithFunctionKeyPath:JSONString arguments:ACArgsPack(cbDataString)];
            [fun executeWithArguments:ACArgsPack(cbDataJson)];
            break;
        }
    }
    //[EUtility brwView:self.specifiedReceiver?:self.receiver evaluateScript:JSONString];
     self.func = nil;
}


@end
