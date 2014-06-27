//
//  ObjectCluster.h
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

#import <Foundation/Foundation.h>


@interface ObjectCluster : NSObject {
	NSString *index;	//object/index
	NSString *name;		//object/name
	NSString *enable;	//object/enable
	NSString *node_id;	//object/node_id
	NSString *type;		//object/type
	NSString *category;	//object/category
	NSString *connectivity;	//object/connectivity
	NSString *state;		//object/state
	NSString *allow_values;		//object/allowed_values
	NSString *current_Value;	//object/current_value
	NSString *beacon;
}
@property (nonatomic,retain) NSString *index;	//object/index
@property (nonatomic,retain) NSString *name;		//object/name
@property (nonatomic,retain) NSString *enable;	//object/enable
@property (nonatomic,retain) NSString *node_id;	//object/node_id
@property (nonatomic,retain) NSString *type;		//object/type
@property (nonatomic,retain) NSString *category;	//object/category
@property (nonatomic,retain) NSString *connectivity;	//object/connectivity
@property (nonatomic,retain) NSString *state;		//object/state
@property (nonatomic,retain) NSString *current_Value;	//object/current_value
@property (nonatomic,retain) NSString *allow_values;		//object/allowed_values

@property (nonatomic,retain) NSString *beacon;


@end

