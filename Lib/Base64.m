//
//  Base64.m
//  TerraUI
//
//  Created by ISBU  Nash on 公元2011/04/13.
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

#import "Base64.h"

static char base64Table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

NSString * Base64Encoder(NSData* bytes) {
	
	int len = bytes.length;
	int index = 0;
	const unsigned char *data = bytes.bytes;
	unsigned char * output = malloc(len*2);
	
	for(int i=0;i<len;i+=3) {
		const unsigned char *p = (data +i);
		output[index++] = base64Table[((*p) >> 2)];
		output[index++] = base64Table[(((*p)& 0x03) << 4) + ((*(p+1)) >> 4)];
		output[index++] = ((i + 1) < len)?base64Table[(((*(p+1)) & 0x0f) << 2) + ((*(p+2)) >> 6)] : '=';
	    output[index++] = ((i + 2) < len)?base64Table[((*(p+2)) & 0x3f)] : '=';
	}
	
	NSData *resoult = [[NSData alloc] initWithBytes:output length:index];
	NSString *ret = [[[NSString alloc] initWithData:resoult
										   encoding:NSASCIIStringEncoding] autorelease];
	free(output);
	[resoult release];
	return ret;
}
