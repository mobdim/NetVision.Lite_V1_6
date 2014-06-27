//
//  DyBuffer.m
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

#import "DyBuffer.h"
//static int bucnt = 0;

@implementation DyBuffer

@synthesize _myid;

- (id) init 
{
	
	if ((self = [super init]) == nil)
		return nil;

	_buf_cond = [[NSCondition alloc] init];
	_buf_cnt  = 0;
	_frame_head_ptr = _frame_last_ptr = NULL;
	//_myid = ++bucnt;
	
	return self;
}


-(void)CleanFrameOnList
{
	unsigned int pts;
	UIImage* im;
	while([self GetFrameOnList:&im withPTS:&pts] == 0)
		[im release];
}

-(int)PutFrameOnList:(UIImage*) pf withPTS:(unsigned int) pts {

	if(_buf_cnt > _max_buf_cnt)
	{
		_full = YES;
		//NSLog(@"wait..buffer full..(%d)\n",_myid);
		[NSThread sleepForTimeInterval:0.5]; //this wait maybe safe...bug?
	}
	
	if(_buf_cnt > _max_buf_cnt)
	{
		[_buf_cond lock];
		[_buf_cond waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:3]];
		[_buf_cond unlock];
		
		if(_buf_cnt > _max_buf_cnt)
		{
			NSLog(@"wait fail!(%d)\n",_myid);
			return -1;
		}
	}
	

	[_buf_cond lock];
	
	FrameList *newfp = malloc(sizeof (FrameList));
		
	newfp->frame_ptr = pf;
	newfp->pts = pts;
		
	int error = 0;
	if(_buf_cnt <= 0 || _frame_last_ptr == NULL)
		_frame_head_ptr = _frame_last_ptr = newfp;
	else 
	{
		if(_frame_last_ptr)
		{
			_frame_last_ptr->list_ptr = newfp;
			_frame_last_ptr = _frame_last_ptr->list_ptr;
		}
		else 
		{
			error = 1;
		}

	}
	
	if(!error)
		_buf_cnt++;
	//NSLog(@"Put >>buf cnt = %d(%d)\n",_buf_cnt,_myid);
    [_buf_cond unlock];
	
	
	return 0;
}

-(int) GetFrameOnList:(UIImage**) pf withPTS:(unsigned int*) pts{
	
	
	
	if(pf == NULL)
		return -1;
	
	if(_buf_cnt <= 0 || !_frame_head_ptr)
	{
		_frame_head_ptr = _frame_last_ptr = NULL;
		_buf_cnt = 0;
		return -1;
	}
	
	[_buf_cond lock];
	
	if(_frame_head_ptr) 
	{
		FrameList *fp = _frame_head_ptr;
			
		*pf = fp->frame_ptr;
		*pts = fp->pts;
			
		_frame_head_ptr = _frame_head_ptr->list_ptr;
			
		free(fp);
	}
	
	
	_buf_cnt--;
	_full = NO;
	//NSLog(@"Get >>buf cnt = %d(%d)\n",_buf_cnt,_myid);
	[_buf_cond signal];
	[_buf_cond unlock];
	
	
	

	return 0;
}
-(void) SetMaxBuf:(int)cnt
{
	_max_buf_cnt = cnt;
}
-(BOOL) GetFull
{
	return _full;
}
-(void) dealloc
{
	[_buf_cond release];
	//bucnt--;
	[super dealloc];
}
@end
