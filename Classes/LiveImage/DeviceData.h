//
//  DeviceData.h
//  HypnoTime
//
//  Created by Yen Jonathan on 2011/4/14.
/*
 * Copyright c 2010 SerComm Corporation. 
 * All Rights Reserved. 
 *
 * SerComm Corporation reserves the right to make changes to this document without notice. 
 * SerComm Corporation makes no warranty, representation or guarantee regarding the suitability 
 * of its products for any particular purpose. SerComm Corporation assumes no liability arising 
 * out of the application or use of any product or circuit. SerComm Corporation specifically 
 * disclaims any and all liability, including without limitation consequential or incidental 
 * damages; neither does it convey any license under its patent rights, nor the rights of others.
 */

#import <UIKit/UIKit.h>

#define DEVICE_FEATURE_PAN_TILT									0x01
#define DEVICE_FEATURE_LED										0x02

@interface DeviceData : NSObject 
{
	NSString *title;
	NSString *IP;	// device IP(use for P2P mode)
	int portNum;
	
	//UIImage *snapshot;	
	NSString *authenticationName;
	NSString *authenticationPassword;
	NSString *authenticationToken;
	
	NSString *relayIP;	// relay server IP(use for relay server mode)
	int relayPort;
	NSString *deviceExtIP;
	NSString *deviceExtPort;
	
	BOOL dirtyFlag;
	
	NSString *deviceKey;
	int extensionFeatures;
	
	int playType;
	int modelNameID;
}

@property(nonatomic, retain) NSString *title;
@property(nonatomic, retain) NSString *IP; 
@property(nonatomic, assign) int portNum;
//@property(nonatomic, retain) UIImage *snapshot;
@property(nonatomic, retain) NSString *authenticationName;
@property(nonatomic, retain) NSString *authenticationPassword;
@property(nonatomic, retain) NSString *authenticationToken;
@property(nonatomic, assign) BOOL dirtyFlag;
@property(nonatomic, copy) NSString *deviceKey;
@property(nonatomic, assign) int extensionFeatures;

@property(nonatomic, retain) NSString *relayIP;
@property(nonatomic, retain) NSString *deviceExtIP;
@property(nonatomic, retain) NSString *deviceExtPort;
@property(nonatomic, assign) int relayPort;
@property(nonatomic, assign) int playType;
@property(nonatomic, assign) int modelNameID;

+(id)deviceDataCreationWthAssignedIndex:(NSInteger)index;
-(BOOL)isAttributesChanged:(DeviceData*)newDevice;

@end
