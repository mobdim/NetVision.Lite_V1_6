//
//  ffmpegWrapper.h
//  HypnoTime
//
//  Created by Yen Jonathan on 2011/4/22.
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

#import <UIKit/UIKit.h>
#import "ffmpegStructureDef.h"


@protocol FrameDataTransferProtocol;

@interface ffmpegWrapper : NSObject 
{
	BOOL paused;
	BOOL terminated;
	int streamingStatus;
	id <FrameDataTransferProtocol> delegate;
	
	//AVPacket flush_packet;	
	MessEngine me;
	//int bytesReceive;
	int frames;	
	
	NSThread *stream_t;
	BOOL noMoreTearDownRequired;
}
@property(nonatomic, retain) NSThread *stream_t;
@property(nonatomic, assign) BOOL paused;
@property(nonatomic, assign) BOOL terminated;
@property(nonatomic, assign) int streamingStatus;
@property(nonatomic, assign) id <FrameDataTransferProtocol> delegate;
@property(nonatomic, assign) MessEngine me;
//@property(nonatomic, assign) int bytesReceive;
@property(nonatomic, assign) int frames;
@property(nonatomic, assign) BOOL noMoreTearDownRequired;

-(void)launchStreaming:(NSString*)urlString;
// This thread is in charge of the following tasks:
//	1.	session setup
//	2.	stream download - packets receiving(including both video and audio)
//	3.	packets assembling for frame preparation
//	4.	queue the frames
-(void)streamDownloadThread:(NSString*)urlString;
// This thread is in charge of the following tasks:
//	1.	dequeue the frames
//	2.	forward the frames to viewport for displaying
-(void)frameOutputThread;

// forward/retrieve data to/from delegate
-(void)forwardStatus:(int)respondCode;
-(void)forwardImage:(UIImage*)img;
-(void)forwardImageResolution:(int)with height:(int)height;
-(BOOL)askFocalMode;

// packet/frame treatment
-(void)structInit;
-(void)packetQueueInit:(PacketQueue*)q;
-(BOOL)packetQueuePut:(PacketQueue*)q withPacket:(AVPacket*)pkt;
-(BOOL)packetQueueGet:(PacketQueue*)q withPacket:(AVPacket*)pkt;
-(void)packetQueueFlush:(PacketQueue*)q;

-(double)getFramePTS:(AVFrame *)src_frame withPTS:(double)pts;
-(double)computeFrameDelay:(double)currFramePTS;
-(UIImage*)imageFromAVPicture:(AVPicture*)pict withWidth:(int)width withHeight:(int)height;

-(int)decodeAudioFrame;
-(void)fillAudioQueue:(AudioQueueBufferRef)outBuffer withQueue:(AudioQueueRef)queue;
-(void)audioProcessThread;
-(BOOL)streamOpen:(int)streamIndex;

-(void)cleanOccupiedResource;

-(void)ffDecode:(NSString*)urlString;
-(int)filterErrCode:(int)errSource;

@end


/*
 Protocol for frame data transfer
 */
@protocol FrameDataTransferProtocol <NSObject>

@required
// retrieve the decoded frame: push mode
-(void)decompressedFrame:(ffmpegWrapper*)decoder withImage:(UIImage*)image;
// image resolution information
-(void)informImageResolution:(ffmpegWrapper*)decoder withWidth:(int)width withHeight:(int)height;
// determine if the audio data need to be played
-(BOOL)needPlayAudio:(ffmpegWrapper*)decoder;
// status notification
-(void)streamingStatus:(ffmpegWrapper*)decoder code:(int)code;
-(int)associatedViewportTag:(ffmpegWrapper*)decoder;

@end

