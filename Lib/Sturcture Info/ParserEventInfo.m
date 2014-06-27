//
//  ParserEventInfo.m
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

#import "ParserEventInfo.h"


@implementation ParserEventInfo




- (id) init {
	//NSLog(@"ParserEventInfo init\n");
	if ((self = [super init]) == nil)
		return nil;
	isOtherTag = NO;
	eventList = [[NSMutableArray alloc] init];
	currentElement = nil;

	return self;
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
	attributes:(NSDictionary *)attributeDict {
	
	if(currentElement != nil) {
		[currentElement release];
		currentElement = nil;
	}
	currentElement = [[NSString alloc] initWithString:elementName];
	
	 //NSLog(@"Ele :%@\n",elementName);
	
	if([elementName isEqualToString:@"event"]) 
		eventInfo = [[EventInfo alloc] init];
	else if([elementName isEqualToString:@"others"])
	   isOtherTag = YES;
	 
}	

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
									  namespaceURI:(NSString *)namespaceURI 
									 qualifiedName:(NSString *)qName {
	if(currentElement != nil) {
		[currentElement release];
		currentElement = nil;
	}
	
	if([elementName isEqualToString:@"event"]) {
		[eventList addObject:eventInfo];
		[eventInfo release];
		eventInfo = nil;
	}
	else if([elementName isEqualToString:@"others"])	
		isOtherTag = NO;
	
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	
	if(eventInfo == nil)
		return;
	
	NSString *info = [[NSString alloc] initWithString:string];
	
	if([currentElement isEqualToString:@"id"] && isOtherTag)
		eventInfo.triggerDeviceID = info;
	else if([currentElement isEqualToString:@"id"])
		eventInfo.ID = info;
	else if([currentElement isEqualToString:@"dev_name"])
		eventInfo.dev_name = info;
	else if([currentElement isEqualToString:@"time"])
		eventInfo.time = info;
	else if([currentElement isEqualToString:@"type"])
		eventInfo.type = info;
	else if([currentElement isEqualToString:@"where"])
		eventInfo.where = info;
	else if([currentElement isEqualToString:@"status"])
		eventInfo.status = info;
	else if([currentElement isEqualToString:@"onlooker_clips"])
		eventInfo.onlooker_clips = info;
	else if([currentElement isEqualToString:@"source"])
		eventInfo.source = info;
	else if([currentElement isEqualToString:@"link"])
		eventInfo.link = info;
	else if([currentElement isEqualToString:@"duration"])
		eventInfo.duration = info;
			
	
	[info release];
	 
}
	   
- (void) dealloc {
	
	//NSLog(@"ParserEventInfo dealloc\n");
	[eventList removeAllObjects];
	[eventList release];
	eventList = nil;
	
	[currentElement release];
	currentElement = nil;

	[super dealloc];
}

- (id) getEventList {
	
	NSMutableArray *ret = [[eventList mutableCopy] autorelease];
	[eventList removeAllObjects];
	[eventList release];
	eventList = nil;
	return ret;
}


@end
