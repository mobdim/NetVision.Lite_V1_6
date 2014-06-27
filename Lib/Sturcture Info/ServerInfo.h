//
//  ServerInfo.h
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

#import <Foundation/Foundation.h>


//define the protocol type
typedef enum _protocolType
{
	HTTP,
	HTTPS
}protocolType;



@interface ServerInfo : NSObject
{
	NSString *serverIP;
	int serverPort;
	NSString *serverAccountName; 
	NSString *serverPassword;
	protocolType protocol;
}


@property (nonatomic, readwrite, retain) NSString *serverIP;
@property (nonatomic, readwrite, retain) NSString *serverAccountName;
@property (nonatomic, readwrite, retain) NSString *serverPassword;
@property (readwrite) int	serverPort;
@property (readwrite) protocolType protocol;


- (id)initWithServerIP:(NSString*)serverIp 
				  Port:(int)port
			  Username:(NSString *)userName
			  Password:(NSString *)password
			  Protocol:(protocolType)protocol_;

@end
