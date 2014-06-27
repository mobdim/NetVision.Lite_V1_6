//
//  DeviceData.m
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

#import "DeviceData.h"
#import "ConstantDef.h"
#import "ModelNames.h"

@implementation DeviceData

@synthesize title;
@synthesize IP;
@synthesize portNum;
//@synthesize snapshot;
@synthesize authenticationPassword;
@synthesize authenticationName;
@synthesize authenticationToken;
@synthesize dirtyFlag;
@synthesize deviceKey;
@synthesize extensionFeatures;
@synthesize relayIP;
@synthesize relayPort;
@synthesize deviceExtIP;
@synthesize deviceExtPort;
@synthesize playType;
@synthesize modelNameID;

+(id)deviceDataCreationWthAssignedIndex:(NSInteger)index
{
	DeviceData *newDevice = [[self alloc] init];
	
	NSString *str = [NSString stringWithFormat:@"192.168.1.%d", index];
	[newDevice setIP:str];
	[newDevice setPortNum:80];
	str = @"New Device";
	[newDevice setTitle:str];
	[newDevice setDirtyFlag:YES];
	
	[newDevice setRelayIP:@" "];
	[newDevice setRelayPort:80];
	[newDevice setDeviceExtIP:@" "];
	[newDevice setDeviceExtPort:@" "];
	[newDevice setExtensionFeatures:DEVICE_EXTENSION_PT|DEVICE_EXTENSION_STREAM_TYPE_MJPEG|DEVICE_EXTENSION_STREAM_TYPE_MPEG4];
	[newDevice setPlayType:IMAGE_CODEC_MJPEG];
	[newDevice setModelNameID:MODEL_NAME_DONTCARE];
	// create a global unique device key
	CFUUIDRef uniqueKey = CFUUIDCreate(kCFAllocatorDefault);
	CFStringRef uniqueStr = CFUUIDCreateString(kCFAllocatorDefault, uniqueKey);
	NSLog(@"deviceDataCreationWthAssignedIndex...key: %@...", (NSString*)uniqueStr);
	[newDevice setDeviceKey:(NSString*)uniqueStr];
	
	CFRelease(uniqueStr);
	CFRelease(uniqueKey);
	
	return [newDevice autorelease];	
	
}

// return value:
//   YES - if anyone of the title, IP, port number, user name or password changed or
//		   if it is a newly created device
//         The authentication token changed is not a kind of attribute changed.
//   NO -  non of the attributes changed. 
-(BOOL)isAttributesChanged:(DeviceData*)newDevice
{
	// check the title
	if([[newDevice title] caseInsensitiveCompare:title] != NSOrderedSame)
	{
		[self setDirtyFlag:YES];
		goto attributesCheckExit;
	}
	
	// check IP
	if([[newDevice IP] caseInsensitiveCompare:IP] != NSOrderedSame)
	{
		[self setDirtyFlag:YES];
		goto attributesCheckExit;
	}
	
	// check port number
	if([newDevice portNum] != portNum)
	{
		[self setDirtyFlag:YES];
		goto attributesCheckExit;		
	}
	
	// check user name
	if([[newDevice authenticationName] compare:authenticationName] != NSOrderedSame)
	{
		[self setDirtyFlag:YES];
		goto attributesCheckExit;
	}
	
	// check password
	if([[newDevice authenticationPassword] compare:authenticationPassword] != NSOrderedSame)
	{
		[self setDirtyFlag:YES];
		goto attributesCheckExit;
	}	
	
	// check stream type
	if([newDevice playType] != [self playType])
	{
		[self setDirtyFlag:YES];
		goto attributesCheckExit;
	}		
	
  attributesCheckExit:
	return dirtyFlag;
}

-(void)dealloc
{
	[title release];
	[IP release];
	//[snapshot release];
	[authenticationName release];
	[authenticationPassword release];	
	[authenticationToken release];	
	[deviceKey release];
	
	[super dealloc];	
}

@end
