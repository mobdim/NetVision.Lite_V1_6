//
//  checkData.m
//  TerraUI
//
//  Created by Shell on 2011/3/7.
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

#import "checkData.h"


@implementation checkData

-(BOOL)checkIPAddress:(NSString*)ip
{
	
	NSString *urlRegEx =
	@"(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)";
	//@"(\d{1,2}|2[1234]\d|25[12345])\.(\d{1,2}|2[1234]\d|25[12345])\.(\d{1,2}|2[1234]\d|25[12345])\.(\d{1,2}|2[1234]\d|25[12345])";
	NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx]; 
	return [urlTest evaluateWithObject:ip];

}

- (BOOL)checkClipInfoDuration:(NSString*)duration
{
	BOOL error = NO;
	if ([duration length]== 29) 
	{
		NSArray *durationArray = [duration componentsSeparatedByString:@","];
		if ([durationArray count] == 2) 
		{
			for (NSString *date in durationArray) 
			{
				if ([date length] == 14)
					error = YES;
				else 
				{
					error = NO;
					break;
				}

			}
		}
	}
	return error;
}

- (BOOL)checkDateFormat:(NSString*)date
{
	if ([date length] == 14)
		return YES;
	else
		return NO;

}
@end
