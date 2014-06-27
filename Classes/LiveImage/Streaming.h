//
//  Streaming.h
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
#import "ffmpegWrapper.h"
#import "MjpegWrapper.h"

typedef struct imageAttributesDef
{
	int codec;
	int width;
	int height;
} imageAttributesDef;

@protocol StreamingProtocol;

@interface Streaming : NSObject <FrameDataTransferProtocol,MjpegFrameDataTransferProtocol>
{
	// Streaming object uses this tag to match its associated viewport and deviceDada
	// the value of opTag minus one is the index number of the associated DeviceData object in 
	// DeviceData cache
	int opTag;
	
	// streaming operation status
	int opStatus;
	
	// image attributes
	imageAttributesDef imageAttributes;
	UIImage *snapshotImage;
	BOOL snapshotRequest;
	
	// ffmpeg wrapper
	ffmpegWrapper *ffmpeg;
	int continuousRetryErrorCount;
	
	// run mode
	int runMode;	// server/P2P mode
	
	// delegate
	id <StreamingProtocol> delegate;
	//Mjpeg wrapper
	MjpegWrapper *mjpeg;
	
	BOOL connectionRetryEnabled;
	int svnMappingStreamType;
}

@property(nonatomic, assign) int opTag;
@property(nonatomic, assign) int opStatus;
@property(nonatomic, assign) imageAttributesDef imageAttributes;
@property(nonatomic, retain) UIImage *snapshotImage;
@property(nonatomic, assign) BOOL snapshotRequest;
@property(nonatomic, retain) ffmpegWrapper *ffmpeg;
@property(nonatomic, assign) int continuousRetryErrorCount;
@property(nonatomic, assign) int runMode;
@property(nonatomic, assign) id <StreamingProtocol> delegate;
@property(nonatomic, retain) MjpegWrapper *mjpeg;
@property(nonatomic, assign) BOOL connectionRetryEnabled;
@property(nonatomic, assign) int svnMappingStreamType;

// initialization
+(id)initWithTag:(int)tag withMode:(int)mode withType:(int)type;

// streaming operation
// Let all the streaming status are feedback from lower layer library module(ffmpeg)
-(void)play;
-(void)pause;
-(void)stop;
-(void)doStreamingRetry;

// snapshot image treatment
// mark snapshot request
-(void)doSnapshot:(BOOL)fromSnapshotRequest;
//parameter:
// YES: user snapshot request
// NO: auto device image retrieving for ImageCache
-(void)captureSnapshotImage:(BOOL)fromSnapshotRequest;

// retrieve the frame from decoder output and convert the frame into an UIImage object
-(UIImage*)retrieveFrameImage;

// compose streaming url
-(NSString*)composeURL;

// forward/retrieve data to/from delegate
-(void)forwardStatus;
-(void)forwardImage:(UIImage*)img;
-(BOOL)askFocalMode;

// for video server with specified channel url, we need further query for real stream type
-(int)verifyStreamType:(int)channel;

@end


/*
 Protocol for frame frame display
 */
@protocol StreamingProtocol <NSObject>

@required
-(void)feedNewImage:(Streaming*)streamingObj newImage:(UIImage*)img;
-(BOOL)isFocalMode:(Streaming*)streamingObj;
-(void)streamingStatusChanged:(Streaming*)streamingObj code:(int)code;

@end
