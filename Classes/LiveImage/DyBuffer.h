//
//  DyBuffer.h
//  NetVision Lite
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

typedef struct _FrameList {
	UIImage* frame_ptr;
	unsigned int     pts;
	
	struct _FrameList* list_ptr;
	
}FrameList;


@interface DyBuffer : NSObject {

	FrameList* _frame_head_ptr;
	FrameList* _frame_last_ptr;
	
	NSCondition* _buf_cond;
	
	int _max_buf_cnt;
	int _buf_cnt;
	
	int _myid;
	
	BOOL _full;
}

@property (nonatomic, assign) int _myid;

-(int) PutFrameOnList:(UIImage*)  pf withPTS:(unsigned int)  pts;
-(int) GetFrameOnList:(UIImage**) pf withPTS:(unsigned int*) pts;
-(void)CleanFrameOnList;

-(void)SetMaxBuf:(int)cnt;

-(BOOL)GetFull;
@end
