//
//  ParserObj.h
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

#import <Foundation/Foundation.h>
#import "DeviceInfo.h"
#import "ObjectCluster.h"

@interface ParserObj : NSObject <NSXMLParserDelegate>{
	
	NSString *currentElement;
	
	BOOL isObjListTag;

	
	ObjectCluster *objInfo;
	NSMutableArray *objList;
	NSString *beacon;
	
	
	DeviceInfo *devInfo;
	NSMutableArray *devList;
	
	BOOL isViewerTag;

}
@property (nonatomic,retain) NSString *beacon;
- (id) getDevWithObjList;
@end
