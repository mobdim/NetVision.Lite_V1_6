//
//  MjpegWrapper.h
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


@protocol MjpegFrameDataTransferProtocol;

@interface MjpegWrapper : NSObject {

	BOOL paused;
	BOOL terminated;
	id <MjpegFrameDataTransferProtocol> delegate;
	int streamingStatus;
	int frames;	
	
	int frate;
	int time_base;
	int myid;
	
	NSThread *stream_t;
	
	BOOL isFirstDraw;
	int pre_pts;
	int64_t start_time;

}

@property(nonatomic, retain) NSThread *stream_t;
@property(nonatomic, assign) BOOL paused;
@property(nonatomic, assign) BOOL terminated;
@property(nonatomic, assign) int streamingStatus;
@property(nonatomic, assign) id <MjpegFrameDataTransferProtocol> delegate;
@property(nonatomic, assign) int frames;

-(void)launchStreaming:(NSString*)urlString;
-(void)streamDownloadThread:(NSString*)urlString;
-(void)forwardStatus:(int)respondCode;
-(void)forwardImage:(UIImage*)img;
-(void)forwardImageResolution:(int)width height:(int)height;
-(BOOL)askFocalMode;
-(int) viewportTag;

//-(int) PutFrameOnList:(UIImage*)  pf withPTS:(unsigned int)  pts;
//-(int) GetFrameOnList:(UIImage**) pf withPTS:(unsigned int*) pts;
-(void)PlayView:(id) data;
-(void)DrawView:(UIImage*)img PTS:(int)pts;
//-(void)CleanFrameOnList;
@end


/*
 Protocol for frame data transfer
 */
@protocol MjpegFrameDataTransferProtocol <NSObject>

@required
// retrieve the decoded frame: push mode
-(void)decompressedMjpegFrame:(MjpegWrapper*)decoder withImage:(UIImage*)image;
// image resolution information
-(void)informMjpegImageResolution:(MjpegWrapper*)decoder withWidth:(int)width withHeight:(int)height;
// determine if the audio data need to be played
-(BOOL)needPlayMjpegAudio:(MjpegWrapper*)decoder;
// status notification
-(void)streamingMjpegStatus:(MjpegWrapper*)decoder code:(int)code;
-(int)associatedMjpegViewportTag:(MjpegWrapper*)decoder;

@end
