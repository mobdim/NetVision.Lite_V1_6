//
//  UserDefDevList.h
//  TerraUI
//
//  Created by Shell on 2011/4/25.
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


@interface UserDefDevice : NSObject <NSCoding>
{
	NSString *cameraName;
	NSString *IPAddr;
	NSString *UserName;
	NSString *Password;
	NSString *PortNum;
	
	BOOL panTiltAbility;
	BOOL ledAbility;
	int modelNameID;
	int extensionAbilities;
	int  playType;
}

@property (nonatomic ,retain) NSString *cameraName;
@property (nonatomic ,retain) NSString *IPAddr;
@property (nonatomic ,retain) NSString *UserName;
@property (nonatomic ,retain) NSString *Password;
@property (nonatomic ,retain) NSString *PortNum;
@property (assign) BOOL panTiltAbility;
@property (assign) BOOL ledAbility;
@property (assign) int  playType;
@property (assign) int  modelNameID;
@property (assign) int  extensionAbilities;



+(int)resolveExtensionAbility:(int)model;
- (id)initWithDeviceName:(NSString*)name DeviceIP:(NSString*)deviceIp UserName:(NSString*)uname Password:(NSString*)pw PortNum:(NSString*)port PanTilt:(BOOL)pt LED:(BOOL)led PlayType:(int)type;



@end
