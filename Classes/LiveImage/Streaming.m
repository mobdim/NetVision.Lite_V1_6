//
//  Streaming.m
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

#import "Streaming.h"
#import "DeviceData.h"
#import "DeviceCache.h"
#import "ImageCache.h"
#import "ConstantDef.h"
#import "Viewport.h"
#import "TerraUIAppDelegate.h"

@implementation Streaming

@synthesize opTag;
@synthesize opStatus;
@synthesize snapshotImage;
@synthesize snapshotRequest;
@synthesize imageAttributes;
@synthesize ffmpeg;
@synthesize continuousRetryErrorCount;
@synthesize runMode;
@synthesize delegate;
@synthesize mjpeg;
@synthesize connectionRetryEnabled;
@synthesize svnMappingStreamType;

+(id)initWithTag:(int)tag withMode:(int)mode withType:(int)type
{
	Streaming *obj = [[self alloc] init];
	[obj setOpTag:tag];
	imageAttributesDef attr;
	attr = [obj imageAttributes];
	//nash
	if(type == 1)
		attr.codec = IMAGE_CODEC_MPEG4;
	else
		attr.codec = IMAGE_CODEC_MJPEG; // default
	
	attr.width = 320;
	attr.height = 240;
	[obj setImageAttributes:attr];
	[obj setSnapshotImage:nil];
	[obj setSnapshotRequest:NO];
	[obj setConnectionRetryEnabled:YES];
	[obj setOpStatus:DEVICE_STATUS_OFFLINE];

	[obj setContinuousRetryErrorCount:0];
	ffmpegWrapper* fwr = [[ffmpegWrapper alloc] init];
	[obj setFfmpeg:fwr];
	[[obj ffmpeg] setDelegate:self];
	[fwr release];

	MjpegWrapper* mwr = [[MjpegWrapper alloc] init];
	[obj setMjpeg:mwr];
	[[obj mjpeg] setDelegate:self];
	[mwr release];
	
	[obj setRunMode:mode];
	[obj setSvnMappingStreamType:IMAGE_CODEC_MJPEG];

	return [obj autorelease];
}

// parameter:
//  fromSnapshotRequest - YES: user snapshot request
//						- NO: auto device image retrieving for ImageCache
-(void)captureSnapshotImage:(BOOL)fromSnapshotRequest
{	
	//NSLog(@"Streaming...captureSnapshotImage..1");
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	UIImage *image;
	if(fromSnapshotRequest)
	{
		image = [self retrieveFrameImage];
		UIImageWriteToSavedPhotosAlbum(image, self, nil, nil); 
		//NSLog(@"Streaming...captureSnapshotImage..2");
	} 
	else 
	{
		image = [self retrieveFrameImage];
		// locate the position in ImageCache
		NSString *key = [[DeviceCache sharedDeviceCache] keyAtIndex:[self opTag]-1];
		[[ImageCache sharedImageCache] setImage:image forKey:key];
		//NSLog(@"Streaming...captureSnapshotImage..3");
	}
	
	[pool release];	
}

-(void)doSnapshot:(BOOL)fromSnapshotRequest
{
	NSLog(@"Streaming: set doSnapshot flag");
	[self setSnapshotRequest:fromSnapshotRequest];	
}

-(UIImage*)retrieveFrameImage
{
	if([self snapshotImage] != nil)
		return [self snapshotImage];
	
	int width = [self imageAttributes].width;
	int height = [self imageAttributes].height;
    NSInteger myDataLength = width * height * 4;
	unsigned char *buffer = (unsigned char*)malloc(myDataLength);
	 	
    // make data provider with data.
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, myDataLength, NULL);
	
    // prepare the ingredients
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * width;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
	
    // make the cgimage
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);	
    // output the uiimage
    UIImage *theImage = [UIImage imageWithCGImage:imageRef];
	
	//nash for leak
	CGColorSpaceRelease(colorSpaceRef);
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	free(buffer);
    return theImage;	
}

-(NSString*)composeURL
{
	NSLog(@"Streaming: enter composeURL...opTag: %d", [self opTag]);
	NSLog(@"application mode: %d", [self runMode]);
	DeviceData *dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:[self opTag]-1];
	//imageAttributesDef attr;
	//attr = [self imageAttributes];	
	NSString *url;
	if([self runMode] == RUN_SERVER_MODE)
	{
		if(imageAttributes.codec == IMAGE_CODEC_MPEG4)
		{
			url = [NSString stringWithFormat:@"rtsp://%@:%d/img/video.sav?video=MPEG4&beacon=%@&http",
				   [dev relayIP],
				   [dev relayPort],
				   [dev authenticationToken]];

		}
		else if(imageAttributes.codec == IMAGE_CODEC_MJPEG)
		{
			url = [NSString stringWithFormat:@"rtsp://%@:%d/img/video.sav?video=MJPEG&beacon=%@",
				   [dev relayIP],
				   [dev relayPort],
				   [dev authenticationToken]];			
		}
		else
		{
			url = [NSString stringWithFormat:@"rtsp://%@:%d/img/video.sav?video=MJPEG&beacon=%@",
				   [dev relayIP],
				   [dev relayPort],
				   [dev authenticationToken]];				
		}
	}
	else
	{
		if(imageAttributes.codec == IMAGE_CODEC_MPEG4)
		{
			url = [NSString stringWithFormat:@"rtsp://%@:%@@%@:%d/img/video.sav?video=MPEG4&http",
				   [dev authenticationName],
				   [dev authenticationPassword],
				   [dev IP],
				   [dev portNum]];	
		}
		else if(imageAttributes.codec == IMAGE_CODEC_MJPEG)
		{
			url = [NSString stringWithFormat:@"rtsp://%@:%@@%@:%d/img/video.sav?video=MJPEG",
				   [dev authenticationName],
				   [dev authenticationPassword],
				   [dev IP],
				   [dev portNum]];				
		}
		else if(imageAttributes.codec == IMAGE_CODEC_H264)
		{
			url = [NSString stringWithFormat:@"rtsp://%@:%@@%@:%d/img/video.sav?video=H264&http",
				   [dev authenticationName],
				   [dev authenticationPassword],
				   [dev IP],
				   [dev portNum]];				
		}
		else
		{
			if(imageAttributes.codec == IMAGE_CODEC_CH1)
			{					
				url = [NSString stringWithFormat:@"rtsp://%@:%@@%@:%d/img/video.sav?channel=1&http",
					   [dev authenticationName],
					   [dev authenticationPassword],
					   [dev IP],
					   [dev portNum]];				
			}
			else if(imageAttributes.codec == IMAGE_CODEC_CH2)
			{
				url = [NSString stringWithFormat:@"rtsp://%@:%@@%@:%d/img/video.sav?channel=2&http",
					   [dev authenticationName],
					   [dev authenticationPassword],
					   [dev IP],
					   [dev portNum]];				
			}
			else if(imageAttributes.codec == IMAGE_CODEC_CH3)
			{
				url = [NSString stringWithFormat:@"rtsp://%@:%@@%@:%d/img/video.sav?channel=3&http",
					   [dev authenticationName],
					   [dev authenticationPassword],
					   [dev IP],
					   [dev portNum]];				
			}	
			else if(imageAttributes.codec == IMAGE_CODEC_CH4)
			{
				url = [NSString stringWithFormat:@"rtsp://%@:%@@%@:%d/img/video.sav?channel=4&http",
					   [dev authenticationName],
					   [dev authenticationPassword],
					   [dev IP],
					   [dev portNum]];				
			}		
			else
			{
				url = [NSString stringWithFormat:@"rtsp://%@:%@@%@:%d/img/video.sav?video=MJPEG",
					   [dev authenticationName],
					   [dev authenticationPassword],
					   [dev IP],
					   [dev portNum]];		
			}
		}
	}
	NSLog(@"Viewport Tag: %d url: %@", [self opTag], url);
	return url;
}

-(int)verifyStreamType:(int)channel
{
	// 
	DeviceData *dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:[self opTag]-1];
	NSString *cgi = [NSString stringWithFormat:@"http://%@:%d/util/query.cgi",
					[dev IP],
					[dev portNum]];	
	
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];	
	if(appDelegate == nil)
		return IMAGE_CODEC_MPEG4;
	
	NSURL *url = [[NSURL alloc] initWithString:cgi];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:url];
	[request setTimeoutInterval:2.0];
	int retryCount = 0;
	
	NSHTTPURLResponse *response;
	NSError *errorCode = nil;
	
  retryCGI:
	NSLog(@"verifyStreamType...query util: %@", cgi);
	NSData *data = [NSURLConnection sendSynchronousRequest:request 
									returningResponse:&response 
												error:&errorCode];
	
	//NSError *error = nil;
	//NSData *data = [[appDelegate dataCenter] syncHttpsRequest:cgi errorCode:&error];
	
	if(data == nil)
	{
		if(++retryCount < 5)
			goto retryCGI;
		
		NSLog(@"verifyStreamType...query util cgi response: nil...default to MPEG4");
		return IMAGE_CODEC_MPEG4;
	}

	NSString *contents = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	NSLog(@"verifyStreamType...query util cgi response: %@", contents);
	
	// let's filter the channel related stream type
	NSRange range;
	switch(channel)
	{
		case IMAGE_CODEC_CH1:
			range = [contents rangeOfString:@"mpeg4_resolution="];
			if(range.length != 0)
				return IMAGE_CODEC_MPEG4;
			range = [contents rangeOfString:@"mjpeg_resolution="];	
			if(range.length != 0)
				return IMAGE_CODEC_MJPEG;	
			range = [contents rangeOfString:@"h264_resolution="];	
			if(range.length != 0)
				return IMAGE_CODEC_H264;
			break;
		case IMAGE_CODEC_CH2:
			range = [contents rangeOfString:@"mpeg4_resolution2"];
			if(range.length != 0)
				return IMAGE_CODEC_MPEG4;
			range = [contents rangeOfString:@"mjpeg_resolution2"];	
			if(range.length != 0)
				return IMAGE_CODEC_MJPEG;	
			range = [contents rangeOfString:@"h264_resolution2"];	
			if(range.length != 0)
				return IMAGE_CODEC_H264;
			break;			
		case IMAGE_CODEC_CH3:
			range = [contents rangeOfString:@"mpeg4_resolution3"];
			if(range.length != 0)
				return IMAGE_CODEC_MPEG4;
			range = [contents rangeOfString:@"mjpeg_resolution3"];	
			if(range.length != 0)
				return IMAGE_CODEC_MJPEG;	
			range = [contents rangeOfString:@"h264_resolution3"];	
			if(range.length != 0)
				return IMAGE_CODEC_H264;
			break;				
		case IMAGE_CODEC_CH4:
			range = [contents rangeOfString:@"mpeg4_resolution4"];
			if(range.length != 0)
				return IMAGE_CODEC_MPEG4;
			range = [contents rangeOfString:@"mjpeg_resolution4"];	
			if(range.length != 0)
				return IMAGE_CODEC_MJPEG;	
			range = [contents rangeOfString:@"h264_resolution4"];	
			if(range.length != 0)
				return IMAGE_CODEC_H264;
			break;			
	}

	return IMAGE_CODEC_MPEG4;
}


-(void)forwardStatus
{
	if([delegate respondsToSelector:@selector(streamingStatusChanged:code:)])		
	   [delegate streamingStatusChanged:self code:[self opStatus]];
}
	   
-(void)forwardImage:(UIImage*)img
{
	if([delegate respondsToSelector:@selector(feedNewImage:newImage:)])		
	   [delegate feedNewImage:self newImage:img];		   
}
	   
-(BOOL)askFocalMode
{
	if([delegate respondsToSelector:@selector(isFocalMode:)])		
	   return [delegate isFocalMode:self];	
	   
	   return NO;
}

-(void)play
{	
	NSLog(@"enter play...viewport:%d  ...1", [self opTag]);
	@synchronized(self)
	{	
		//NSLog(@"enter play...tag: %d", [self opTag]);
		[ffmpeg setDelegate:self];
		[mjpeg setDelegate:self];
	
		// if no device associated, do nothing 
		if([self opTag] > [[DeviceCache sharedDeviceCache] totalDeviceNumber])
		{
			[self setOpStatus:DEVICE_STATUS_NO_DEVICE_ASSOCIATED];
			[self forwardStatus];	
			goto endPlay;
		}
		
		//TerraUIAppDelegate *appDelegate = (TerraUIAppDelegate *)[[UIApplication sharedApplication] delegate];
		//[self setRunMode:[[appDelegate dataCenter] getMobileMode]];
		// check current op status:
		// if in paused mode, issue play command to resume the streaming
		//if([self opStatus] == DEVICE_STATUS_PAUSED)
		//{
		//	// resume the streaming
		//	[[self ffmpeg] setPaused:NO];
		//
		//	// successful resume
		//	//don't set the status here. Let ffmpeg feedback the streaming status
		//	goto endPlay;
		//}
	
		// if in stop mode, issue session setup command to start the streaming
		//if(([self opStatus] == DEVICE_STATUS_STOPPED)
		//	|| ([self opStatus] == DEVICE_STATUS_OFFLINE)
		//   || ([self opStatus] == DEVICE_STATUS_PREPARE_FOR_ONLINE))	
		if([self opStatus] != DEVICE_STATUS_ONLINE)
		{
			// get desired stream type
			DeviceData *dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:[self opTag]-1];
			int streamType = [dev playType];
			//NSLog(@"in play device: %d codec: %d", [self opTag], streamType);

			NSLog(@"in play set imageAttribute codec: %d", streamType);
			if(streamType == IMAGE_CODEC_MPEG4)
				imageAttributes.codec = IMAGE_CODEC_MPEG4;
			else if(streamType == IMAGE_CODEC_MJPEG)
				imageAttributes.codec = IMAGE_CODEC_MJPEG;
			else if(streamType == IMAGE_CODEC_H264)
				imageAttributes.codec = IMAGE_CODEC_H264;
			else if(streamType == IMAGE_CODEC_CH1)
				imageAttributes.codec = IMAGE_CODEC_CH1;	
			else if(streamType == IMAGE_CODEC_CH2)
				imageAttributes.codec = IMAGE_CODEC_CH2;
			else if(streamType == IMAGE_CODEC_CH3)
				imageAttributes.codec = IMAGE_CODEC_CH3;
			else if(streamType == IMAGE_CODEC_CH4)
				imageAttributes.codec = IMAGE_CODEC_CH4;			
			else
				imageAttributes.codec = IMAGE_CODEC_MJPEG;

			//NSLog(@"in play after set imageAttribute codec: %d", imageAttributes.codec);
				
			if([self opStatus] == DEVICE_STATUS_PAUSED)
			{
				 if(imageAttributes.codec == IMAGE_CODEC_MJPEG)
					 [[self mjpeg]  setPaused:NO];
				 else
					 [[self ffmpeg] setPaused:NO]; //- nash				
			}
			
			// in order to have a quick response to show the prepare for streaming indicator
			[self setOpStatus:DEVICE_STATUS_PREPARE_FOR_ONLINE];
			//NSLog(@"in play...forward status start...");
			[self forwardStatus];
			//NSLog(@"in play...forward status end...");
		
			// currently, we use ffmpeg wrapper for mpeg4/h264 streaming
			if((imageAttributes.codec == IMAGE_CODEC_MPEG4) || (imageAttributes.codec == IMAGE_CODEC_H264))
			{
				// prepare the required streaming url
				[[self ffmpeg] setTerminated:NO];
				NSString *url = [self composeURL];		
				NSLog(@"Streaming: play...viewport %d...opStatus:%d with ffmpeg", [self opTag], [self opStatus]);
				[ffmpeg launchStreaming:url];
				//don't set the status here. Let ffmpeg feedback the streaming status
			}
			// motion jpeg server push streaming
			else if(imageAttributes.codec == IMAGE_CODEC_MJPEG)
			{
				[[self mjpeg] setTerminated:NO];
				NSString *url = [self composeURL];	
				NSLog(@"Streaming: play...viewport %d...opStatus:%d with mjpeg", [self opTag], [self opStatus]);
				[mjpeg launchStreaming:url];	
			}
			// assume channel streaming
			else 
			{
				// prepare the required streaming url
				// for video server with specified channel url, we need further query for real stream type
				[self setSvnMappingStreamType:[self verifyStreamType:imageAttributes.codec]];				
				if([self svnMappingStreamType] != IMAGE_CODEC_MJPEG)
				{
					[[self ffmpeg] setTerminated:NO];
					NSString *url = [self composeURL];			
					[ffmpeg launchStreaming:url];
				}
				else
				{
					[[self mjpeg] setTerminated:NO];
					NSString *url = [self composeURL];			
					[mjpeg launchStreaming:url];					
				}
				//[[self mjpeg] setTerminated:NO];
				//NSString *url = [self composeURL];			
				//[mjpeg launchStreaming:url];
				
			}	
		}
	}
 endPlay:		
	// we might need to consider the situation that quick switching between
	// liveView's viewWillDisappear and viewWillAppear.
	// If we back to viewWillAppear, the streaming module might not be ready due to
	// previous stop caused by viewWillDisappear. In this situation, we will miss
	// the chance to launch streaming since the opStatus is not back to 
	// 'DEVICE_STATUS_STOPPED' state.
		
	return;
	 
}

-(void)pause
{
	NSLog(@"Streaming: pause...viewport: %d", [self opTag]);
	@synchronized(self)
	{
		[ffmpeg setDelegate:self];
		[mjpeg setDelegate:self];
		// if no device associated, do nothing 
		if([self opTag] > [[DeviceCache sharedDeviceCache] totalDeviceNumber])
		{
			[self setOpTag:DEVICE_STATUS_NO_DEVICE_ASSOCIATED];
			[self forwardStatus];
			return;
		}	
	
		if(imageAttributes.codec != IMAGE_CODEC_MJPEG)
		{
			if([[self ffmpeg] streamingStatus] == STREAM_SESSION_STATUS_PLAY)
				[[self ffmpeg] setPaused:YES];
		}
		else
		{
			if([[self mjpeg] streamingStatus] == STREAM_SESSION_STATUS_PLAY)
				[[self mjpeg] setPaused:YES];
		}
	}
}

-(void)stop
{
	NSLog(@"Streaming: stop...viewport: %d", [self opTag]);
	@synchronized(self)
	{
		[ffmpeg setDelegate:self];
		[mjpeg setDelegate:self];
		// if no device associated, do nothing 
		if([self opTag] > [[DeviceCache sharedDeviceCache] totalDeviceNumber])
		{
			[self setOpStatus:DEVICE_STATUS_NO_DEVICE_ASSOCIATED];
			[self forwardStatus];
			return;
		}
	
		NSLog(@"Streaming: viewport: %d...setTerminated flag...", [self opTag]);
		NSLog(@"Streaming: viewport: %d...codecType: %d...", [self opTag], imageAttributes.codec);
		
		if((imageAttributes.codec == IMAGE_CODEC_CH1) || (imageAttributes.codec == IMAGE_CODEC_CH2) 
		   || (imageAttributes.codec == IMAGE_CODEC_CH3) || (imageAttributes.codec == IMAGE_CODEC_CH4))
		{
			if([self svnMappingStreamType] != IMAGE_CODEC_MJPEG)
			{
				NSLog(@"Streaming: viewport: %d...stop ffmpeg download thread in NV842 case...", [self opTag]);
				[[self ffmpeg] setTerminated:YES]; //- nash
				[[[self ffmpeg] stream_t] cancel];				
			}
			else
			{
				NSLog(@"Streaming: viewport: %d...stop motion-jpeg download thread in NV842 case...", [self opTag]);
				[[self mjpeg] setTerminated:YES];
				[[[self mjpeg] stream_t] cancel];				
			}
		}
		else
		{
			if(imageAttributes.codec != IMAGE_CODEC_MJPEG)
			{
				NSLog(@"Streaming: viewport: %d...stop ffmpeg download thread...", [self opTag]);
				[[self ffmpeg] setTerminated:YES]; //- nash
				[[[self ffmpeg] stream_t] cancel];
			}
			else 
			{
				NSLog(@"Streaming: viewport: %d...stop motion-jpeg download thread...", [self opTag]);
				[[self mjpeg] setTerminated:YES];
				[[[self mjpeg] stream_t] cancel];								
			}
		}

	}
}


-(void)doStreamingRetry
{
	// check to see if we do need to do connection retry since it might be the case that
	// we receive invalide data while leaving the live view page
	if([self connectionRetryEnabled] == YES)
	{
		continuousRetryErrorCount++;	
		NSLog(@"do streaming retry...viewport: %d retry time: %d", [self opTag], continuousRetryErrorCount);
		
		[self play];
	}
	else
		continuousRetryErrorCount = 0;
}

-(void)dealloc
{
	[ffmpeg release];
	[mjpeg release];
	[snapshotImage release];
	
	[super dealloc];
}

#pragma mark FrameDataTransferProtocol methods
-(void)decompressedFrame:(ffmpegWrapper*)decoder withImage:(UIImage*)image
{
	if(decoder != [self ffmpeg])
		return;
	
	if([self snapshotRequest] == YES)
	{
		[self setSnapshotImage:image];
		[self setSnapshotRequest:NO];
		[self captureSnapshotImage:YES];		
	}
	
	// pass the UIImage object to associated viewport
	[self forwardImage:image];
}

-(void)informImageResolution:(ffmpegWrapper*)decoder withWidth:(int)width withHeight:(int)height
{
	if(decoder != [self ffmpeg])
		return;
	
	imageAttributes.width = width;
	imageAttributes.height = height;
}

-(BOOL)needPlayAudio:(ffmpegWrapper*)decoder
{
	if(decoder != [self ffmpeg])
		return NO;
	
	return [self askFocalMode];
	
}

-(void)streamingStatus:(ffmpegWrapper*)decoder code:(int)code
{
	//NSLog(@"Streaming: enter streamingStatus...");
	if(decoder != [self ffmpeg])
		return;
	
	[self setOpStatus:code];
	//NSLog(@"Streaming: pass the status code to Viewport...code:%d", code);
	[self forwardStatus];
}

-(int)associatedViewportTag:(ffmpegWrapper*)decoder
{
	if(decoder != [self ffmpeg])
		return 0;	
	
	return [self opTag];
}

#pragma mark MjpegFrameDataTransferProtocol methods

// retrieve the decoded frame: push mode
-(void)decompressedMjpegFrame:(MjpegWrapper*)decoder withImage:(UIImage*)image
{
	if(decoder != [self mjpeg])
		return;
	
	if([self snapshotRequest] == YES)
	{
		[self setSnapshotImage:image];
		[self setSnapshotRequest:NO];
		[self captureSnapshotImage:YES];		
	}
	
	// pass the UIImage object to associated viewport
	[self forwardImage:image];
}
// image resolution information
-(void)informMjpegImageResolution:(MjpegWrapper*)decoder withWidth:(int)width withHeight:(int)height
{
	if(decoder != [self mjpeg])
		return;
	
	imageAttributes.width = width;
	imageAttributes.height = height;
	
}
// determine if the audio data need to be played
-(BOOL)needPlayMjpegAudio:(MjpegWrapper*)decoder
{
	if(decoder != [self mjpeg])
		return NO;
	
	return [self askFocalMode];
	
}
// status notification
-(void)streamingMjpegStatus:(MjpegWrapper*)decoder code:(int)code
{
	//NSLog(@"Streaming: enter streamingStatus...");
	if(decoder != [self mjpeg])
		return;
	
	[self setOpStatus:code];
	//NSLog(@"Streaming: pass the status code to Viewport...code:%d", code);
	[self forwardStatus];
}
-(int)associatedMjpegViewportTag:(MjpegWrapper*)decoder
{
	if(decoder != [self mjpeg])
		return 0;	
	
	return [self opTag];
	
}

@end
