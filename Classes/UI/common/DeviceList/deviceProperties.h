//
//  deviceProperties.h
//  TerraUI
//  device struct
//  Created by Shell on 2011/1/12.
/*
 * Copyright © 2010 SerComm Corporation. 
 * All Rights Reserved. 
 *
 * SerComm Corporation reserves the right to make changes to this document without notice. 
 * SerComm Corporation makes no warranty, representation or guarantee regarding the suitability 
 * of its products for any particular purpose. SerComm Corporation assumes no liability arising 
 * out of the application or use of any product or circuit. SerComm Corporation specifically 
 * disclaims any and all liability, including without limitation consequential or incidental 
 * damages; neither does it convey any license under its patent rights, nor the rights of others.
 */

#import <Foundation/Foundation.h>


@interface deviceProperties : NSObject {
	NSString *Name;
	NSString *ip;
	NSInteger deviceType;
	Boolean selectStatus;
	NSString *deviceID;
}
- (id)initWithDeviceName:(NSString*)name DeviceIP:(NSString*)deviceIp Type:(NSInteger)t devID:(NSString*)DeviceID;
@property (nonatomic , retain) NSString *Name;
@property (nonatomic , retain) NSString *ip;
@property (nonatomic )  NSInteger deviceType;
@property (nonatomic ) Boolean selectStatus;
@property (nonatomic , retain) NSString *deviceID;
@end
