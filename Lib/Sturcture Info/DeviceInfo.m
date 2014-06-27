//
//  DeviceInfoV2.m
//  TerraUI
//
//  Created by ISBU on 公元2011/12/12.
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

#import "DeviceInfo.h"


@implementation DeviceInfo

@synthesize ID;
@synthesize tz;
@synthesize type;
@synthesize mac;
@synthesize name;
@synthesize internal;
@synthesize external;
@synthesize relay;
@synthesize vpns;
@synthesize username;
@synthesize password;
@synthesize status;
@synthesize beacon;
@synthesize objList;

- (id) init {
	//NSLog(@"DeviceInfo init\n");
	if ((self = [super init]) == nil)
		return nil;
	
	ID       = nil;
	tz       = nil;
	type     = nil;
	mac	     = nil;
	name     = nil;
	internal = nil;
	external = nil;
	relay    = nil;
	vpns     = nil;
	username = nil;
	password = nil;
	status   = nil;
	beacon   = nil;
	
	
	objList  = nil;
		
	return self;
}


- (void) dealloc {
	//NSLog(@"DeviceInfo dealloc\n");
	[ID       release];
	[tz       release];
	[type     release];
	[mac      release];
	[name     release];
	[internal release];
	[external release];
	[relay    release];
	[vpns     release];
	[username release];
	[password release];
	[status   release];
	[beacon   release];
	
	[objList  release];
	
	ID       = nil;
	tz       = nil;
	type     = nil;
	mac	     = nil;
	name     = nil;
	internal = nil;
	external = nil;
	relay    = nil;
	vpns     = nil;
	username = nil;
	password = nil;
	status   = nil;
	beacon   = nil;
	
	objList  = nil;
	
	[super dealloc];
	
}
	
@end
