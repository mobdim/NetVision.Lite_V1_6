//
//  UserDefDevList.m
//  TerraUI
//
//  Created by Shell on 2011/4/25.
//  Copyright 2011 Sercomm. All rights reserved.
//

#import "UserDefDevList.h"


@implementation UserDefDevList
@synthesize cameraName,IPAddr,UserName,Password;
#pragma mark -
#pragma mark init
- (id)initWithDeviceName:(NSString*)name DeviceIP:(NSString*)deviceIp UserName:(NSString*)uname Password:(NSString*)pw
{
	self = [super init];
	if (self) 
	{
		cameraName = [[NSString alloc] initWithString:name];
		IPAddr = [[NSString alloc] initWithString:deviceIp];
		UserName = [[NSString alloc] initWithString:uname];
		Password = [[NSString alloc] initWithString:pw];
	}
	return self;
	
}//end of init 

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super init]) 
	{
		self.cameraName = [aDecoder decodeObjectForKey:@"cameraName"];
		self.IPAddr = [aDecoder decodeObjectForKey:@"IPAddr"];
		self.UserName = [aDecoder decodeObjectForKey:@"UserName"];
		self.Password = [aDecoder decodeObjectForKey:@"Password"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:cameraName forKey:@"cameraName"];
	[aCoder encodeObject:IPAddr forKey:@"IPAddr"];
	[aCoder encodeObject:UserName forKey:@"UserName"];
	[aCoder encodeObject:Password forKey:@"Password"];
	
}

#pragma mark -
#pragma mark dealloc
- (void) dealloc {
	[cameraName release];
	[IPAddr release];
	[UserName release];
	[Password release];
	[super dealloc];
}

@end
