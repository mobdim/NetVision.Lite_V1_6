//
//  ObjectCluster.m
//  TerraUI
//
//  Created by Shell on 2011/3/26.
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

#import "ObjectCluster.h"


@implementation ObjectCluster


@synthesize index;
@synthesize name;
@synthesize enable; 
@synthesize node_id; 
@synthesize type; 
@synthesize category; 
@synthesize connectivity;
@synthesize state;
@synthesize current_Value; 
@synthesize allow_values; 
@synthesize beacon;


- (id) init {
	//NSLog(@"ObjecCluster init\n");
	if ((self = [super init]) == nil)
		return nil;
	
	index         = nil;	//object/index
	name          = nil;		//object/name
	enable        = nil;	//object/enable
	node_id       = nil;	//object/node_id
	type          = nil;		//object/type
	category      = nil;	//object/category
	connectivity  = nil;	//object/connectivity
	state         = nil;		//object/state
	allow_values  = nil;		//object/allowed_values
	current_Value = nil;	//object/current_value
		
	return self;
}

- (void) dealloc {
	//NSLog(@"ObjecCluster dealloc\n");
	
	[index         release];	//object/index
	[name          release];		//object/name
	[enable        release];	//object/enable
	[node_id       release];	//object/node_id
	[type          release];		//object/type
	[category      release];	//object/category
	[connectivity  release];	//object/connectivity
	[state         release];		//object/state
	[allow_values  release];		//object/allowed_values
	[current_Value release];	//object/current_value
	[beacon        release];
	
	
	index         = nil;	//object/index
	name          = nil;		//object/name
	enable        = nil;	//object/enable
	node_id       = nil;	//object/node_id
	type          = nil;		//object/type
	category      = nil;	//object/category
	connectivity  = nil;	//object/connectivity
	state         = nil;		//object/state
	allow_values  = nil;		//object/allowed_values
	current_Value = nil;	//object/current_value
	beacon        = nil;
	
	[super dealloc];
}


@end
