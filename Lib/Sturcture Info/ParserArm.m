//
//  ParserArm.m
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

#import "ParserArm.h"


@implementation ParserArm

- (id) init {
	//NSLog(@"ParserArm init\n");
	if ((self = [super init]) == nil)
		return nil;
	
	arm = nil;
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
	
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if([currentElement isEqualToString:@"status"] ) {
		if(arm != nil)
			[arm release];
		arm = [[NSString alloc] initWithString:string];
	}
	
	
	
}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName {
	
	if(currentElement != nil) {
		[currentElement release];
		currentElement = nil;
	}
}
- (void) dealloc {
	//NSLog(@"ParserArm dealloc\n");
	[arm release];
	arm  = nil;
	[currentElement release];
	currentElement = nil;
	
	[super dealloc];
}

- (id) getArm {
	
	return arm;
}

@end
