//
//  deviceProperties.m
//  TerraUI
//
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

#import "deviceProperties.h"


@implementation deviceProperties

@synthesize Name;
@synthesize ip;
@synthesize deviceType;
@synthesize selectStatus,deviceID;

- (void) dealloc {
	//NSLog(@"deviceProperties dealloc\n");
	[ip release];
	[Name release];
	[deviceID release];
	[super dealloc];
}


- (id)initWithDeviceName:(NSString*)name DeviceIP:(NSString*)deviceIp Type:(NSInteger)t devID:(NSString*)DeviceID
{
	self = [super init];
	if (self) {
		Name = [[NSString alloc] initWithString:name];
		ip = [[NSString alloc] initWithString:deviceIp];
		deviceType = t;
		selectStatus = NO;
		deviceID = [[NSString alloc] initWithString:DeviceID];
	}
	return self;
	
}//end of init 
@end
