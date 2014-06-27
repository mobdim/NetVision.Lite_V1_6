//
//  UserDefDevList.m
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

#import "UserDefDevList.h"
#import "ModelNames.h"
#import "ConstantDef.h"


@implementation UserDefDevice
@synthesize cameraName,IPAddr,UserName,Password,PortNum,panTiltAbility,ledAbility,playType;
@synthesize modelNameID, extensionAbilities;

+(int)resolveExtensionAbility:(int)model
{
	int val = DEVICE_EXTENSION_STREAM_TYPE_MJPEG|DEVICE_EXTENSION_STREAM_TYPE_MPEG4;;
	switch(model)
	{
		case MODEL_NAME_RC4021:
		case MODEL_NAME_RC8021:
			val = DEVICE_EXTENSION_STREAM_TYPE_MJPEG|DEVICE_EXTENSION_STREAM_TYPE_MPEG4;
			break;
		case MODEL_NAME_RC8061:
			val = DEVICE_EXTENSION_PT|DEVICE_EXTENSION_LED_W|DEVICE_EXTENSION_IO|DEVICE_EXTENSION_STREAM_TYPE_MJPEG|DEVICE_EXTENSION_STREAM_TYPE_MPEG4;
			break;
		case MODEL_NAME_RC8221:
			val = DEVICE_EXTENSION_DNS|DEVICE_EXTENSION_LED_IR|DEVICE_EXTENSION_IO|DEVICE_EXTENSION_STREAM_TYPE_H264|DEVICE_EXTENSION_STREAM_TYPE_MJPEG|DEVICE_EXTENSION_STREAM_TYPE_MPEG4;
			break;			
		case MODEL_NAME_OC810:
		case MODEL_NAME_OC821:			
			val = DEVICE_EXTENSION_DNS|DEVICE_EXTENSION_LED_IR|DEVICE_EXTENSION_STREAM_TYPE_H264|DEVICE_EXTENSION_STREAM_TYPE_MJPEG|DEVICE_EXTENSION_STREAM_TYPE_MPEG4;
			break;	
		case MODEL_NAME_iCam:
			val = DEVICE_EXTENSION_LED_IR|DEVICE_EXTENSION_STREAM_TYPE_H264|DEVICE_EXTENSION_STREAM_TYPE_MJPEG|DEVICE_EXTENSION_STREAM_TYPE_MPEG4;
			break;	
		case MODEL_NAME_DC402:
			val = DEVICE_EXTENSION_DNS|DEVICE_EXTENSION_LED_IR|DEVICE_EXTENSION_IO|DEVICE_EXTENSION_STREAM_TYPE_MJPEG|DEVICE_EXTENSION_STREAM_TYPE_MPEG4;
			break;
		case MODEL_NAME_DC421:
		case MODEL_NAME_RC8120:	
			val = DEVICE_EXTENSION_STREAM_TYPE_MJPEG|DEVICE_EXTENSION_STREAM_TYPE_H264|DEVICE_EXTENSION_STREAM_TYPE_MPEG4;
			break;	
		case MODEL_NAME_NV812D:
			val = DEVICE_EXTENSION_RS485|DEVICE_EXTENSION_IO|DEVICE_EXTENSION_STREAM_TYPE_H264|DEVICE_EXTENSION_STREAM_TYPE_MJPEG|DEVICE_EXTENSION_STREAM_TYPE_MPEG4;
			break;	
		case MODEL_NAME_NV412A:
			val = DEVICE_EXTENSION_RS485|DEVICE_EXTENSION_IO|DEVICE_EXTENSION_STREAM_TYPE_MJPEG|DEVICE_EXTENSION_STREAM_TYPE_MPEG4;
			break;
		case MODEL_NAME_NV842:
			val = DEVICE_EXTENSION_RS485|DEVICE_EXTENSION_IO|DEVICE_EXTENSION_STREAM_TYPE_H264|DEVICE_EXTENSION_STREAM_TYPE_MJPEG|DEVICE_EXTENSION_STREAM_TYPE_MPEG4;
			break;			
		default:
			val = DEVICE_EXTENSION_PT|DEVICE_EXTENSION_LED_IR|DEVICE_EXTENSION_STREAM_TYPE_MJPEG|DEVICE_EXTENSION_STREAM_TYPE_MPEG4|DEVICE_EXTENSION_STREAM_TYPE_H264;
			break;		
	}
	
	return val;
}

#pragma mark -
#pragma mark init
- (id)initWithDeviceName:(NSString*)name 
				DeviceIP:(NSString*)deviceIp 
				UserName:(NSString*)uname 
				Password:(NSString*)pw
				 PortNum:(NSString*)port
				 PanTilt:(BOOL)pt
					 LED:(BOOL)led
				PlayType:(int) type
{
	self = [super init];
	if (self) 
	{
		cameraName = [[NSString alloc] initWithString:name];
		IPAddr     = [[NSString alloc] initWithString:deviceIp];
		UserName   = [[NSString alloc] initWithString:uname];
		Password   = [[NSString alloc] initWithString:pw];
		PortNum    = [[NSString alloc] initWithString:port];
		panTiltAbility = pt;
		ledAbility = led;
		playType   = type;
	}
	return self;
	
}//end of init 

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super init]) 
	{
		self.cameraName = [aDecoder decodeObjectForKey:@"cameraName"];
		self.IPAddr		= [aDecoder decodeObjectForKey:@"IPAddr"];
		self.UserName	= [aDecoder decodeObjectForKey:@"UserName"];
		self.Password	= [aDecoder decodeObjectForKey:@"Password"];
		self.PortNum	= [aDecoder decodeObjectForKey:@"PortNum"];
		if([((NSString*)[aDecoder decodeObjectForKey:@"PanTilt"]) isEqualToString:@"0"])
			self.panTiltAbility = NO;
		else
			self.panTiltAbility = YES;
		if([((NSString*)[aDecoder decodeObjectForKey:@"LED"]) isEqualToString:@"0"])
			self.ledAbility = NO;
		else
			self.ledAbility = YES;
		
		NSLog(@"initWithCoder...beforeRetrieving streamType...");
		NSString *tmp = (NSString*) [aDecoder decodeObjectForKey:@"PlayType"];
		NSLog(@"initWithCoder...afterRetrieving streamType: %@...", tmp);
		
	    if([tmp isEqualToString:@"1"])
			self.playType = IMAGE_CODEC_MPEG4;
		else if([tmp isEqualToString:@"2"])
			self.playType = IMAGE_CODEC_H264;
		else if([tmp isEqualToString:@"11"])
			self.playType = IMAGE_CODEC_CH1;
		else if([tmp isEqualToString:@"12"])
			self.playType = IMAGE_CODEC_CH2;
		else if([tmp isEqualToString:@"13"])
			self.playType = IMAGE_CODEC_CH3;
		else if([tmp isEqualToString:@"14"])
			self.playType = IMAGE_CODEC_CH4;		
		else 
			self.playType = IMAGE_CODEC_MJPEG;
		
		NSLog(@"initWithCoder...modelName retrieving...");
		NSString *mid = [aDecoder decodeObjectForKey:@"ModelName"];
		if(mid == nil)
			self.modelNameID = MODEL_NAME_DONTCARE;
		else
			self.modelNameID = atoi([mid UTF8String]);
		NSLog(@"modelName ID: %d", self.modelNameID);
		self.extensionAbilities = [UserDefDevice resolveExtensionAbility:self.modelNameID];
		
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:cameraName forKey:@"cameraName"];
	[aCoder encodeObject:IPAddr		forKey:@"IPAddr"];
	[aCoder encodeObject:UserName	forKey:@"UserName"];
	[aCoder encodeObject:Password	forKey:@"Password"];
	[aCoder encodeObject:PortNum    forKey:@"PortNum"];
	[aCoder encodeObject:PortNum    forKey:@"PortNum"];
	if(self.panTiltAbility == YES)
		[aCoder encodeObject:@"1"    forKey:@"PanTilt"];
	else
		[aCoder encodeObject:@"0"    forKey:@"PanTilt"];
	if(self.ledAbility == YES)
		[aCoder encodeObject:@"1"    forKey:@"LED"];
	else
		[aCoder encodeObject:@"0"    forKey:@"LED"];	
	
	if(self.playType == IMAGE_CODEC_MPEG4)
		[aCoder encodeObject:@"1"    forKey:@"PlayType"];
	else if(self.playType == IMAGE_CODEC_H264)
		[aCoder encodeObject:@"2"    forKey:@"PlayType"];
	else if(self.playType == IMAGE_CODEC_CH1)
		[aCoder encodeObject:@"11"    forKey:@"PlayType"];	
	else if(self.playType == IMAGE_CODEC_CH2)
		[aCoder encodeObject:@"12"    forKey:@"PlayType"];	
	else if(self.playType == IMAGE_CODEC_CH3)
		[aCoder encodeObject:@"13"    forKey:@"PlayType"];	
	else if(self.playType == IMAGE_CODEC_CH4)
		[aCoder encodeObject:@"14"    forKey:@"PlayType"];		
	else 
		[aCoder encodeObject:@"0"    forKey:@"PlayType"];
	
	NSLog(@"encodeWithCoder...streamType: %d ...", self.playType);
	NSLog(@"encodeWithCoder...modelName: %d ...", self.modelNameID);
	NSString *mid = [NSString stringWithFormat:@"%d", self.modelNameID];
	NSLog(@"encodeWithCoder...text form modelName: %@ ...", mid);
	[aCoder encodeObject:mid    forKey:@"ModelName"];
	
}



#pragma mark -
#pragma mark dealloc
- (void) dealloc {
	[cameraName release];
	[IPAddr		release];
	[UserName	release];
	[Password	release];
	[PortNum	release];
	
	[super dealloc];
}

@end
