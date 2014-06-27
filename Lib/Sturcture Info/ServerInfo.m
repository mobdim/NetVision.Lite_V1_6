//
//  ServerInfo.m
//  TerraUI
//
//  Created by ISBU Joseph Huang on 2011/2/14.
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

#import "ServerInfo.h"

@implementation ServerInfo

@synthesize serverIP;
@synthesize serverPort;
@synthesize serverAccountName;
@synthesize serverPassword;
@synthesize protocol;


- (id)initWithServerIP:(NSString*)serverIp 
				  Port:(int)port
			  Username:(NSString *)userName
			  Password:(NSString *)password
			  Protocol:(protocolType)protocol_
{	
	self.serverIP = serverIp;
	self.serverPort = port;
	self.serverAccountName = userName;
	self.serverPassword = password;
	self.protocol = protocol_;
	
	return self;
	
}//end of init 

- (void) dealloc {
	//NSLog(@"ServerInfo dealloc\n");
	[serverIP release];
	[serverAccountName release];
	[serverPassword release];
	[super dealloc];
}

@end
