//
//  ffmpegWrapper.m
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

#import <unistd.h>
#import <QuartzCore/QuartzCore.h>
#import "ffmpegWrapper.h"
#import "Streaming.h"
#import "ConstantDef.h"
#import "Viewport.h"


void AudioQueueCallback(void* inUserData, AudioQueueRef outAQ, AudioQueueBufferRef outBuffer)
{	
	if(inUserData != NULL)
	{
		[(ffmpegWrapper*)inUserData fillAudioQueue: outBuffer withQueue: outAQ];
	}
	else
	{
		memset(outBuffer->mAudioData, 0, outBuffer->mAudioDataBytesCapacity);
		outBuffer->mAudioDataByteSize = outBuffer->mAudioDataBytesCapacity;
		AudioQueueEnqueueBuffer(outAQ, outBuffer, 0, NULL);	
	}
}

// test

static MessEngine *meGlobal = NULL;
static int decode_interrupt_cb(void)
{
    return (meGlobal && meGlobal->decodeStop);
}
//

@implementation ffmpegWrapper

@synthesize paused;
@synthesize terminated;
@synthesize streamingStatus;
@synthesize delegate;
@synthesize me;
//@synthesize bytesReceive;
@synthesize frames;
@synthesize stream_t;
@synthesize noMoreTearDownRequired;

-(id)init
{
	self = [super init];
	if(!self)
		return nil;
	
	[self setPaused:NO];
	[self setTerminated:NO];
	[self setStreamingStatus:STREAM_SESSION_STATUS_STOP];
	stream_t = NULL;
	[self setNoMoreTearDownRequired:NO];
	
	return self;
}

-(void)forwardStatus:(int)respondCode
{
	if([delegate respondsToSelector:@selector(streamingStatus:code:)])		
	   [delegate streamingStatus:self code:respondCode];	
}

-(void)forwardImage:(UIImage*)img
{
	if([delegate respondsToSelector:@selector(decompressedFrame:withImage:)])
	{
		//NSLog(@"hand over the image...");
	   [delegate decompressedFrame:self withImage:img];
	}
}

-(void)forwardImageResolution:(int)width height:(int)height
{
	if([delegate respondsToSelector:@selector(informImageResolution:withWidth:withHeight:)])
	{	
		[delegate informImageResolution:self withWidth:width withHeight:height];
	}
}

-(BOOL)askFocalMode
{
	if([delegate respondsToSelector:@selector(needPlayAudio:)])
	   return [delegate needPlayAudio:self];
	   
	   return NO;
}

-(int)viewportTag
{
	if([delegate respondsToSelector:@selector(associatedViewportTag:)])		
		return [delegate associatedViewportTag:self];	
	
	return 0;	
}

-(int)filterErrCode:(int)errSource
{
	int errCode = 0;
	switch(errSource)
	{
		case -1:
			errCode = DEVICE_STATUS_POOR_NETWORK_CONDITION;
			break;
		case -5:
			errCode = DEVICE_STATUS_SESSION_FAILURE;
			break;
		case -22:
			errCode = DEVICE_STATUS_SESSION_RX_DATA_CORRUPTION;
			break;
		case DEVICE_STATUS_SESSION_NOT_AVAILABLE:
		case DEVICE_STATUS_AUTHENTICATION_ERROR:
		case DEVICE_STATUS_BAD_REQUEST:								
		case DEVICE_STATUS_REQUEST_FORBIDDEN:
		case DEVICE_STATUS_SERVICE_NOT_FOUND:
		case DEVICE_STATUS_REQUEST_FORMAT_ERROR:
		case DEVICE_STATUS_REQUEST_TIMEOUT:
		case DEVICE_STATUS_INTERNAL_SERVER_ERROR:
		case DEVICE_STATUS_SERVER_NO_SERVICE:
		case DEVICE_STATUS_SERVICE_TIMEOUT:
		case DEVICE_STATUS_HTTP_VERSION_ERROR:						
			errCode = errSource;
			break;
		case -DEVICE_STATUS_SESSION_NOT_AVAILABLE:
		case -DEVICE_STATUS_AUTHENTICATION_ERROR:
		case -DEVICE_STATUS_BAD_REQUEST:								
		case -DEVICE_STATUS_REQUEST_FORBIDDEN:
		case -DEVICE_STATUS_SERVICE_NOT_FOUND:
		case -DEVICE_STATUS_REQUEST_FORMAT_ERROR:
		case -DEVICE_STATUS_REQUEST_TIMEOUT:
		case -DEVICE_STATUS_INTERNAL_SERVER_ERROR:
		case -DEVICE_STATUS_SERVER_NO_SERVICE:
		case -DEVICE_STATUS_SERVICE_TIMEOUT:
		case -DEVICE_STATUS_HTTP_VERSION_ERROR:						
			errCode = -errSource;
			break;			
		default:
			//if(errCode < 0)
				errCode = DEVICE_STATUS_SESSION_FAILURE;
			break;
	}
	
	return errCode;
}

-(void)ffDecode:(NSString*)urlString {
	
	av_register_all();	
	const char *url = [urlString UTF8String];	
	NSLog(@"Nash ffDecode!");
	//start decode
	int                ret;
	int                video_stream = -1;
	int                i;
	int                numbytes;
	uint8_t            *frameBuffer;
	AVFormatContext    *ic = nil;
	AVFormatParameters params, *ap = &params;
	AVCodecContext     *enc;
	AVCodec	           *dec;
	AVFrame            *pFrame;
	AVFrame            *pFrameRGB;
	AVPacket           packet;
	int                frameFinished;
	struct SwsContext  *img_convert_ctx = NULL;
	int errCode = 0;
	
	Streaming *stream = (Streaming *)delegate;
	Viewport *vw      = (Viewport *) [stream delegate];
	
	//int audio_stream = -1;	
	// structure initialization
	//[self structInit];			
	memset(ap,0,sizeof(params));
	
	NSLog(@"enter av_open_input_file...");
	ret = av_open_input_file(&ic, url, 0, 0, ap);
	
	if(ret !=0 || [[NSThread currentThread] isCancelled]) {
		//open rtsp error
		NSLog(@"av_open_input_file error! errCode: %d  viewport: %d", ret, [(Streaming*)delegate opTag]);							
		errCode = [self filterErrCode:ret];
		
		goto ffDecodeExit;
	}
	
	if(ic == nil || [[NSThread currentThread] isCancelled]) {
		NSLog(@"ic error! viewport: %d ", [(Streaming*)delegate opTag]);
		errCode = DEVICE_STATUS_SESSION_FAILURE;
		
		goto ffDecodeExit;
	}
	
	NSLog(@"enter av_find_stream_info...");	
	ret = av_find_stream_info(ic);
	
	//if(!ret) {
	if(ret < 0 || [[NSThread currentThread] isCancelled]) {	
		//find stream error
		NSLog(@"av_find_stream_info error! viewport: %d ", [(Streaming*)delegate opTag]);
		errCode = DEVICE_STATUS_SESSION_FAILURE;
		av_close_input_file(ic);
		goto ffDecodeExit;
	}
	
	
	//dump_format(ic, 0, url, 0);
	
	//find video stream
	NSLog(@"filter video stream...");
	for(i= 0; i< (int)ic->nb_streams ; i++) {
		if(ic->streams[i]->codec->codec_type == CODEC_TYPE_VIDEO) {
			video_stream = i;
			break;
		}
	}
	
	if(video_stream < 0 || [[NSThread currentThread] isCancelled]) {
		NSLog(@"can't find video_stream! viewport: %d", [(Streaming*)delegate opTag]);
		av_close_input_file(ic);
		errCode = DEVICE_STATUS_SESSION_FAILURE;
		goto ffDecodeExit;
	}
	
	enc = ic->streams[video_stream]->codec;
	dec = avcodec_find_decoder(enc->codec_id);
	
	if(dec == NULL || [[NSThread currentThread] isCancelled]) {
		NSLog(@"can't find decoder! viewport: %d", [(Streaming*)delegate opTag]);
		errCode = DEVICE_STATUS_SESSION_FAILURE;
		av_close_input_file(ic);
		goto ffDecodeExit;		
	}
	
	if(avcodec_open(enc, dec) < 0 || [[NSThread currentThread] isCancelled]) {
		NSLog(@"avcodec_open error viewport: %d", [(Streaming*)delegate opTag]);
		avcodec_close(enc);
		errCode = DEVICE_STATUS_SESSION_FAILURE;
		av_close_input_file(ic);
		goto ffDecodeExit;	
	}
	
	// audio treatment
	// Find the first audio stream
	/*
	NSLog(@"filter audio stream info...");
	for(i= 0; i< (int)ic->nb_streams ; i++) {
		if(ic->streams[i]->codec->codec_type == CODEC_TYPE_AUDIO) {
			audio_stream = i;
			break;
		}
	}
	
	if(audio_stream < 0) {
		NSLog(@"can't find audio_stream! error");
		av_close_input_file(ic);
		errCode = DEVICE_STATUS_SESSION_FAILURE;
		
		goto ffDecodeExit;
	}	

	NSLog(@"create audio stream procession thread...");
	if ([self streamOpen:audio_stream] == NO)
	{
		NSLog(@"Fail to open audio stream");
		av_close_input_file(ic);
		errCode = DEVICE_STATUS_SESSION_FAILURE;
		
		goto ffDecodeExit;
	}
	*/
	//
	
	// since we have obtained the image resolution, 
	// remember to inform the associated streaming object of the image info
	[self forwardImageResolution:enc->width height:enc->height];	
	
	double now_time = (double)av_gettime();
	
	NSLog(@"Nash first time = %f",now_time);
	
	pFrame    = avcodec_alloc_frame();
	pFrameRGB = avcodec_alloc_frame();
	
	numbytes = avpicture_get_size( PIX_FMT_RGB24, enc->width, enc->height);
	
	frameBuffer = (uint8_t*)av_malloc(numbytes);
	
	avpicture_fill((AVPicture *) pFrameRGB,frameBuffer,PIX_FMT_RGB24,enc->width, enc->height);
	
	[self setStreamingStatus:STREAM_SESSION_STATUS_PLAY];
	[self forwardStatus:DEVICE_STATUS_ONLINE];
	
	//BOOL  needToTreatAudio = [self askFocalMode];
	BOOL terminatedDueToDataRxError = NO;
	NSLog(@"enter stream download loop...");
	//while([self terminated] == NO) {
	while(![[NSThread currentThread] isCancelled]) {	
		
		if(av_read_frame(ic, &packet) < 0 )
		{
			NSLog(@"packet received error!!!! viewport: %d", [(Streaming*)delegate opTag]);
			terminatedDueToDataRxError = YES;
			break;
		}
		
		if(packet.stream_index != video_stream)
		{
			av_free_packet(&packet);
			continue;
		}
		
		/*
		if(packet.stream_index == audio_stream)
		{
			NSLog(@"audio frame received...");
			if(audio_stream < 0)
				av_free_packet(&packet);
			// if buffer full, drop the packet
			else if(me.audioQueue.size > MAX_AUDIOQ_SIZE)
				av_free_packet(&packet);
			else
			{
				// check to see if we need to treat audio Rx data
				if(needToTreatAudio == YES)
				{
					AudioQueueStart([self me].audioPlayQueue, NULL);
					[self packetQueuePut: &me.audioQueue withPacket:&packet];			
				}
				else 
				{
					AudioQueuePause(me.audioPlayQueue);
					av_free_packet(&packet);
				}
			}
			continue;
		}
		*/
		
		avcodec_decode_video2(enc, pFrame, &frameFinished, &packet);
		
		if(frameFinished) {
			img_convert_ctx = sws_getCachedContext(img_convert_ctx,
												   enc->width, enc->height,
												   enc->pix_fmt,
												   enc->width, enc->height,
												   PIX_FMT_RGB24, SWS_FAST_BILINEAR, NULL, NULL, NULL);
			
			if (img_convert_ctx != NULL) {
				sws_scale(img_convert_ctx, pFrame->data, pFrame->linesize,
						  0, enc->height, pFrameRGB->data, pFrameRGB->linesize);
			}
			
			
			AVPicture *pict = (AVPicture *)pFrameRGB;
			
			//NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];	
			CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
			CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pict->data[0], pict->linesize[0]*enc->height,kCFAllocatorNull);
			CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			CGImageRef cgImage = CGImageCreate(enc->width, 
											   enc->height, 
											   8, 
											   24, 
											   pict->linesize[0], 
											   colorSpace, 
											   bitmapInfo, 
											   provider, 
											   NULL, 
											   NO, 
											   kCGRenderingIntentDefault);
			CGColorSpaceRelease(colorSpace);
			CGDataProviderRelease(provider);
			CFRelease(data);
			//[[vw layer] performSelectorOnMainThread:@selector(setContents:)withObject:(id)cgImage waitUntilDone:NO];
			
			
			NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
			UIImage *im= [UIImage imageWithCGImage:cgImage];
			
			[[vw layer] performSelectorOnMainThread:@selector(setContents:)withObject:(id)im.CGImage waitUntilDone:NO];
			
			if([stream snapshotRequest] == YES)
			{
				[stream setSnapshotImage:im];
				[stream setSnapshotRequest:NO];
				[stream captureSnapshotImage:YES];		
			}
			
			[vw updateViewportSnapshot:im];							
			
			CGImageRelease(cgImage);
			[apool release];			
			
			//usleep(5000);
			//NSLog(@"output one frame...");
		}
		
		av_free_packet(&packet);
		
		//NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
		//UIImage *im = [UIImage imageNamed:@"clock.png"];
		//[[vw layer] performSelectorOnMainThread:@selector(setContents:)withObject:(id)im.CGImage waitUntilDone:NO];
		//[apool release];
		
	}
	
	av_free(pFrame);
	av_free(pFrameRGB);
	avcodec_close(enc);
		
	if (img_convert_ctx) 
	{
		NSLog(@"free img_convert_ctx...");
		sws_freeContext(img_convert_ctx);
		img_convert_ctx = NULL;
	}
	NSLog(@"close ...av_close_input_file...start...");
	av_close_input_file(ic);	
	NSLog(@"close ...av_close_input_file...end...");
	
	[self setStreamingStatus:STREAM_SESSION_STATUS_STOP];
	if(terminatedDueToDataRxError == YES)
		[self forwardStatus:DEVICE_STATUS_DATA_RX_ERROR_AFTER_SESSION_SETUP];
	else
		[self forwardStatus:DEVICE_STATUS_STOPPED];
	[self setNoMoreTearDownRequired:YES];
	
	return;
	
  ffDecodeExit:
	[self setNoMoreTearDownRequired:YES];
	[self setStreamingStatus:STREAM_SESSION_STATUS_STOP];
	[self forwardStatus:errCode];	
	
}

-(void)launchStreaming:(NSString*)urlString
{	
	//NSLog(@"enter launchStreaming...ffmpeg");
	// if there is already an session ready or session setup ongoing, do nothing
	if(([self streamingStatus] == STREAM_SESSION_STATUS_SETUP_ONGOING)
	   || ([self streamingStatus] == STREAM_SESSION_STATUS_PLAY))
	{
		if([self streamingStatus] == STREAM_SESSION_STATUS_PLAY)
			[self forwardStatus:DEVICE_STATUS_PREPARE_FOR_ONLINE];
		if([self streamingStatus] == STREAM_SESSION_STATUS_PLAY)
			[self forwardStatus:DEVICE_STATUS_ONLINE];
		
		NSLog(@"On going return...MPEG-4\n");
		return;
	}
	
	// launch the download thread
	[self setStreamingStatus:STREAM_SESSION_STATUS_SETUP_ONGOING];
	[self forwardStatus:DEVICE_STATUS_PREPARE_FOR_ONLINE];
	
	NSLog(@"Viewport: %d create streamDownloadThread start", [self viewportTag]);
	//[NSThread detachNewThreadSelector:@selector(streamDownloadThread:) toTarget:self withObject:urlString];		
	stream_t = [[NSThread alloc] initWithTarget:self selector:@selector(streamDownloadThread:) object:urlString];
	[stream_t setThreadPriority:1.0];
	[stream_t start];
	
	NSLog(@"Viewport: %d create streamDownloadThread done", [self viewportTag]);
}


-(void)streamDownloadThread:(NSString*)urlString
{
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
	//NSLog(@"enter streamDownloadThread...");
	
	[self ffDecode:urlString];
	
	[pool release];

	return;	
}




/*
-(void)streamDownloadThread:(NSString*)urlString
{
	// Auto release pool
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];			
	
	NSLog(@"enter streamDownloadThread...");	
	
	avcodec_register_all();
	avdevice_register_all();
	av_register_all();	
	
	//[NSThread sleepForTimeInterval:1.0];
	BOOL beginPacketReceived = YES;
	const char *url = [urlString UTF8String];
	int errCode = 0;
    AVPacket pkt1, *packet = &pkt1; // nash
	AVCodecContext *codecCtx;
	AVCodec *codec;	
	
	// test only
	double t = CACurrentMediaTime();
	while(1)
	{
		if((CACurrentMediaTime() - t) >= 4)
			break;
		
		usleep(5000);
	}

	[self setStreamingStatus:STREAM_SESSION_STATUS_STOP];
	[self forwardStatus:DEVICE_STATUS_STOPPED];
	
	NSLog(@"exit download thread");
	
	[pool release];
	return;
	//	
	
	// structure initialization
	[self structInit];
	
	// session setup - open a sesion with given url
	url_set_interrupt_cb(decode_interrupt_cb);
	int videoIndex=-1, audioIndex=-1;	
	AVFormatContext *pFormatCtx = NULL;
    AVFormatParameters params, *ap;
	ap = &params;
	memset(ap, 0, sizeof(*ap));	
    ap->width = FRAME_RESOLUTION_WIDTH_DEFAULT;
    ap->height= FRAME_RESOLUTION_HEIGHT_DEFAULT;
    ap->time_base= (AVRational){1, 25};
    ap->pix_fmt = PIX_FMT_NONE;
	
	NSLog(@"URL length: %d", strlen(url));
	NSLog(@"av_open_input_file...");
	errCode = av_open_input_file(&pFormatCtx, url, 0, 0, ap);
	if (errCode != 0)
	{
		NSLog(@"Error: av_open_input_file() = %d",errCode);	
		beginPacketReceived = NO;
		goto streamDownloadErrorExit;
	}
	NSLog(@"av_open_input_file...return code: %d", errCode);
	
	me.pFormatCtx = pFormatCtx;	
	// session setup - retrieve stream information
	NSLog(@"av_find_stream_info...");
	errCode = av_find_stream_info(pFormatCtx);	
	if (errCode < 0)
	{
		NSLog(@"Error: av_find_stream_info() = %d",errCode);
		beginPacketReceived = NO;
		goto streamDownloadErrorExit;
	}
	NSLog(@"av_find_stream_info...return code: %d", errCode);
	// reset errCode here
	errCode = 0;
	// session setup - filter the audio/video stream if there is any 
	// to initialize the structure
	// Find the first video stream
	NSLog(@"filter video stream info...");
	for(int i=0; i<pFormatCtx->nb_streams; i++)
	{
		if(pFormatCtx->streams[i]->codec->codec_type == CODEC_TYPE_VIDEO) 
		{
			videoIndex = i;	
			codecCtx = pFormatCtx->streams[videoIndex]->codec;
			codec = avcodec_find_decoder(codecCtx->codec_id);
			if(!codec || (avcodec_open(codecCtx, codec) < 0)) 
			{		
				NSLog(@"Error: av decoder not found.");
				errCode = DEVICE_STATUS_DECODER_NOT_FOUND;
				beginPacketReceived = NO;
				goto streamDownloadErrorExit;
			}
				
			// since we have obtained the image resolution, 
			// remember to inform the associated streaming object of the image info
			[self forwardImageResolution:codecCtx->width height:codecCtx->height];
			me.videoStreamIndex = videoIndex;
			me.videoStream = pFormatCtx->streams[videoIndex];			
			me.frameTimer = (double)av_gettime()/1000000.0;			
			me.pictQueueLock = [[NSLock alloc] init];
			me.pictQueueCondition = [[NSCondition alloc] init];			
			[self packetQueueInit: &me.videoQueue];
			me.videoQueue.lock = [[NSLock alloc] init];
			me.videoThreadExist = 1;									
			break;
		}
	}
	
	// Find the first audio stream
	NSLog(@"filter audio stream info...");
	for(int i=0; i<me.pFormatCtx->nb_streams; i++)
	{
		if(me.pFormatCtx->streams[i]->codec->codec_type == CODEC_TYPE_AUDIO) 
		{
			audioIndex = i;
			break;
		}
	}
		
	// if there is an audio stream, we need to create a thread for audio treatment since
	// we will apply the 'RUN-MODE-LOOP' in our case
	if(audioIndex >= 0) 
	{
		// if we have successful video stream, then open the audio process thread
		if(videoIndex >= 0)
		{
			NSLog(@"we have audio, let's create a thread for audio stream processing");
			//TODO, fail the audio codec, still need to process?????
			if ([self streamOpen:audioIndex] == NO)
			{
				//NSLog(@"audioIndex wrong");
				NSLog(@"Fail to open audio stream");
				errCode = DEVICE_STATUS_SESSION_FAILURE;
			}
		}
		else 
			audioIndex = -1;
	}
	
	// if we didn't find a valid video or audio stream, then we fail to
	// setup the streaming session
	if(audioIndex == -1 && videoIndex == -1)
	{
		NSLog(@"No stream opened...streaming session setup failure.");
		errCode = DEVICE_STATUS_SESSION_FAILURE;
	}	
		
	// if session setup fail, issue the status then return
	if(errCode != 0)
	{
		beginPacketReceived = NO;
		goto streamDownloadErrorExit;
	}
	
	// if succeseful session setup, let's create an frame display thread
	me.MDATFd = -1;
	me.MP4Fd = -1;
	me.FramesInfoFd = -1;
	me.copyFinished = YES;	
	[self setTerminated:NO];
	
	NSLog(@"create a frame display thread...");
	[NSThread detachNewThreadSelector:@selector(frameOutputThread) toTarget:self withObject:nil];
	me.displayThreadExist = 1;
		
	//BOOL needToTreatAudio = [(Streaming*)[self delegate] needPlayAudio:self];
	BOOL  needToTreatAudio = [self askFocalMode];
	// nash AVPacket pkt1, *packet = &pkt1;
	// successful session creation, let's go into packet receiving state
	// prepare for packet receiving
	int frameFinished;
	AVFrame *pFrame;
	struct SwsContext *img_convert_ctx = NULL;		
	double pts;
	// nash int len;
	double time_base;
	pFrame = avcodec_alloc_frame();
	double refT;
	
	for (int i=0;i < VIDEO_PICTURE_QUEUE_SIZE; i++)
	{
		//avpicture_alloc(&me.pictureQueue[i].pict, PIX_FMT_RGB24, me.videoStream->codec->width, me.videoStream->codec->height);
		avpicture_alloc(&me.pictureQueue[i].pict, PIX_FMT_RGB24, codecCtx->width, codecCtx->height);
	}	
	NSLog(@"go into packet receiving and processing loop...");
	while([self terminated] == NO)
	{
		//---------------
		// if buffer full
		//---------------
		if(me.audioQueue.size > MAX_AUDIOQ_SIZE || me.videoQueue.size > MAX_VIDEOQ_SIZE)
		{
			usleep(2000);	// 2 ms
			continue;
		}	
		
		//----------
		// if paused
		//----------
		if([self paused] == YES)
		{
			if([self streamingStatus] != STREAM_SESSION_STATUS_PAUSED)
			{
				[self setStreamingStatus:STREAM_SESSION_STATUS_PAUSED];
				[self forwardStatus:DEVICE_STATUS_STOPPED];
			}
			
			[NSThread sleepForTimeInterval:1.0];	// 1 sec
			continue;
		}
		else 
		{
			// if recover from 'paused'
			if([self streamingStatus] == STREAM_SESSION_STATUS_PAUSED)	
			{
				[self setStreamingStatus:STREAM_SESSION_STATUS_PLAY];
				[self forwardStatus:DEVICE_STATUS_ONLINE];			
			}
			if([self streamingStatus] == STREAM_SESSION_STATUS_SETUP_ONGOING)
			{
				[self setStreamingStatus:STREAM_SESSION_STATUS_PLAY];
				[self forwardStatus:DEVICE_STATUS_ONLINE];				
			}
		}		
		
		//--------------------------------
		// read a packet from input stream
		//--------------------------------
		if((errCode = av_read_frame(me.pFormatCtx, packet)) < 0) 
		{
			//NSLog(@"read frame fail, ret= %d viewerID: %d\n", ret, [self viewerID]);			
			if(errCode == AVERROR_EOF || url_ferror(me.pFormatCtx->pb))
			{
				errCode = DEVICE_STATUS_STOPPED;
				[self setTerminated:YES];
				NSLog(@"read packet EOF");
				continue;
			}
			else
			{
				[self setTerminated:YES];
				errCode = DEVICE_STATUS_SESSION_RX_DATA_CORRUPTION;
				NSLog(@"read packet ERROR");
				continue;
			}
		}
		bytesReceive += packet->size;				

		//-----------------
		// queue the packet
		//-----------------
		if(packet->stream_index == me.videoStreamIndex) 
		{
			// queue the rx packet
			//NSLog(@"queue packet...");
			[self packetQueuePut: &me.videoQueue withPacket:packet];
			
		}
		// audio treatment
		else if(packet->stream_index == me.audioStreamIndex)
		{
			// check to see if we need to treat audio Rx data
			if(needToTreatAudio == YES)
			{
				AudioQueueStart([self me].audioPlayQueue, NULL);
				[self packetQueuePut: &me.audioQueue withPacket:packet];			
			}
			else 
			{
				AudioQueuePause(me.audioPlayQueue);
				av_free_packet(packet);
			}
		}
		else 
		{
			av_free_packet(packet);
		}
		
		//------------------------------------------------------------ 
		// dequeue the video packet
		// we let the audio packet dequeuing be done in another thread
		//------------------------------------------------------------		
		if(![self packetQueueGet: &me.videoQueue withPacket:packet]) 
		{
			// means we didn't get any packets
			//NSLog(@"can't get any video packets.\n");
			usleep(5000);	// 5 ms
			continue;
		}
		
		//NSLog(@"dequeue packet...");
		if(packet->data == flush_packet.data)
		{
            avcodec_flush_buffers(me.videoStream->codec);
            continue;
        }
		
		//----------------------------------
		// frame drop mechanism if necessary
		//----------------------------------
		if (me.videoStream->codec->codec_id == CODEC_ID_MPEG4)
		{
			//time_base = 0.033;
			time_base = 0.066;
		}
		else
		{
			time_base = av_q2d(me.videoStream->codec->time_base);
		}
		if (time_base*me.videoQueue.packets > 1.0 && me.videoQueue.size > MAX_VIDEOQ_SIZE/2)
		{
			me.lastFramePTS += av_q2d(me.videoStream->codec->time_base);
			//me.frameTimer += av_q2d(me.videoStream->codec->time_base);
			//NSLog(@"%f,%f,%f,%f\n", me.frameTimer, av_gettime()/1000000.0,av_q2d(me.videoStream->codec->time_base),time_base*me.videoQueue.packets);
			av_free_packet(packet);			
			me.need_drop_frame = 1;
			continue;
		}
		else
		{
			if (me.need_drop_frame)
			{
				NSLog(@"go into packet dropped...");
				//droping frame, and still a p-frame
				if (packet->flags == 0)
				{
					me.lastFramePTS += av_q2d(me.videoStream->codec->time_base);
					//me.frameTimer += av_q2d(me.videoStream->codec->time_base);
					
					av_free_packet(packet);
					continue;
				}
				else
				{
					me.need_drop_frame = 0;
				}
			}
		}
		
		//--------------
		// get frame pts
		//--------------
		me.videoStream->codec->reordered_opaque = packet->pts;
		// decode the video frame
		//NSLog(@"decode packet...");
		// nash len = avcodec_decode_video2(me.videoStream->codec, pFrame, &frameFinished, packet);		
		int len = avcodec_decode_video2(me.videoStream->codec, pFrame, &frameFinished, packet);
		if(len < 0)
		{
			NSLog(@"frame decode error: %d", len);
			av_free_packet(packet);
			continue;
		}
		
		// pts to be stored in reordered_opaque 
		if(packet->dts == AV_NOPTS_VALUE && pFrame->reordered_opaque && pFrame->reordered_opaque != AV_NOPTS_VALUE) 
		{
			pts = pFrame->reordered_opaque;
		} 
		else if(packet->dts != AV_NOPTS_VALUE) 
		{
			pts = packet->dts;
		} 
		else 
		{
			pts = 0;
		}		
		
		//--------------------------------------
		// check to see if frame assembling done
		//--------------------------------------
		pts *= av_q2d(me.videoStream->time_base);				
		if(frameFinished)
		{
			pts = [self getFramePTS:pFrame withPTS:pts];			
			PictureQueue *pv;			
			// wait until we have space for a new pic 
			[me.pictQueueCondition lock];
			while(me.pictQueueSize >= VIDEO_PICTURE_QUEUE_SIZE && ([self terminated] == NO)) 
			{
				[me.pictQueueCondition wait];
			}
			[me.pictQueueCondition unlock];
			
			if([self terminated] == YES)
			{
				av_free_packet(packet);
				break;
			}
			
			// windex is set to 0 initially
			// prepare the location to save the picture
			pv = &me.pictureQueue[me.pictQueueWI];
			pv->pts = pts;
			
			img_convert_ctx = sws_getCachedContext(img_convert_ctx,
												   me.videoStream->codec->width, me.videoStream->codec->height,
												   me.videoStream->codec->pix_fmt,
												   me.videoStream->codec->width, me.videoStream->codec->height,
												   PIX_FMT_RGB24, SWS_FAST_BILINEAR, NULL, NULL, NULL);
			// convert the frame to RGB
			if(img_convert_ctx != NULL) 
			{
				sws_scale(img_convert_ctx, pFrame->data, pFrame->linesize,
						  0, me.videoStream->codec->height, pv->pict.data, pv->pict.linesize);
			}
			else
			{
				NSLog(@"Cannot initialize the conversion context\n");
			}
			
			// now we inform our display thread that we have a pic ready 
			if(++me.pictQueueWI == VIDEO_PICTURE_QUEUE_SIZE) 
			{
				me.pictQueueWI = 0;
			}
			
			[me.pictQueueCondition lock];
			me.pictQueueSize++;
			[me.pictQueueCondition unlock];
			//NSLog(@"insert a decompressed frame...");
			[self setFrames:[self frames]+1];
		}
		
		// remember to free the packet
		av_free_packet(packet);
		
	}

	// no error but user terminated
	if(errCode == 0)
	{
		errCode = DEVICE_STATUS_STOPPED;
		goto streamDownloadExit;
	}
		 
  streamDownloadErrorExit:			
	// filter the error code
	switch(errCode)
	{
		case -1:
			errCode = DEVICE_STATUS_POOR_NETWORK_CONDITION;
			break;
		case -5:
			errCode = DEVICE_STATUS_SESSION_FAILURE;
			break;
		case -22:
			errCode = DEVICE_STATUS_SESSION_RX_DATA_CORRUPTION;
			break;
		case DEVICE_STATUS_SESSION_NOT_AVAILABLE:
		case DEVICE_STATUS_AUTHENTICATION_ERROR:				
			break;
		default:
			if(errCode < 0)
				errCode = DEVICE_STATUS_SESSION_FAILURE;
			break;
	}	
	
  streamDownloadExit:
	// wait display thread exit, then clean the cooupied resource
	refT = CACurrentMediaTime();
	while((me.displayThreadExist == 1) && ((CACurrentMediaTime()-refT) < TIME_PERIOD_MAX_THREAD_EXIT_TIMEOUT))
	{
		usleep(1000);
	}
	NSLog(@"wait display thread done");
	// free packets we didn't process if necessry
	if(beginPacketReceived == YES)
	{
		while([self packetQueueGet: &me.videoQueue withPacket:packet]) 
		{
			av_free_packet(packet);
		}	
		NSLog(@"remove queued packets done");
		
		// clean pictures
		for(int i=0;i < VIDEO_PICTURE_QUEUE_SIZE; i++)
		{
			avpicture_free(&me.pictureQueue[i].pict);
		}
		NSLog(@"remove queued picyures done");
	}
	
	me.pictQueueSize = 0;
	me.pictQueueRI = 0;
	me.pictQueueWI = 0;
	if(me.pictQueueLock)
	{
		[me.pictQueueLock release];
		me.pictQueueLock = nil;
		NSLog(@"release me.pictQueueLock done");
	}
	if(me.pictQueueCondition)
	{
		[me.pictQueueCondition  release];
		me.pictQueueCondition = nil;
		NSLog(@"release me.pictQueueCondition done");
	}
	
	if(img_convert_ctx)
	{
        sws_freeContext(img_convert_ctx);
		NSLog(@"release img_convert_ctx done");
	}	
	av_free(pFrame);
	NSLog(@"release pFrame done");
	me.videoThreadExist = 0;	
		
	// clean the occupied resource
	[self cleanOccupiedResource];

	// after completely exit, update the session status and feedback the streaming status
	// update the session status
	[self setStreamingStatus:STREAM_SESSION_STATUS_STOP];
	[self forwardStatus:errCode];
	
	NSLog(@"exit download thread");
	
	[pool release];	
}
*/

-(void)frameOutputThread
{
	NSLog(@"enter display thread");
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	me.firstImageShowed = NO;
	
	while([self terminated] == NO)
	{				
		if(me.pictQueueSize > 0) 
		{
			PictureQueue *pv;
			pv = &me.pictureQueue[me.pictQueueRI];
			//double actual_delay = [self computeFrameDelay: pv->pts];
			//NSLog(@"retrieve a decompressed frame...");			
			// we should delay to display, but in main thread do usleep will cause our program pause ??? enhace it to another thread
			//usleep(actual_delay*1000000);
			NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
			// convert the RGB frame to UIImage object 
			UIImage *image = [self imageFromAVPicture:&pv->pict 
											withWidth:me.videoStream->codec->width 
										   withHeight:me.videoStream->codec->height];
			
			// show the picture
			[self forwardImage:image];
			[apool release];

			// update queue for next picture! 
			if(++me.pictQueueRI == VIDEO_PICTURE_QUEUE_SIZE) 
			{
				me.pictQueueRI = 0;
			}
			
			[me.pictQueueCondition lock];
			me.pictQueueSize--;
			[me.pictQueueCondition signal];
			[me.pictQueueCondition unlock];
		}
		else
			usleep(5000);	// 5ms
	} 
	
	me.displayThreadExist = 0;
	NSLog(@"exit display thread");
	
	[pool release];		
}


-(UIImage*)imageFromAVPicture:(AVPicture*)pict withWidth:(int)width withHeight:(int)height
{
	//NSLog(@"convert decompressed frame into UIImage begin...");
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
	CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, 
												 pict->data[0], 
												 pict->linesize[0]*height,
												 kCFAllocatorNull);
	
	CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGImageRef cgImage = CGImageCreate(width, 
									   height, 
									   8, 
									   24, 
									   pict->linesize[0], 
									   colorSpace, 
									   bitmapInfo, 
									   provider, 
									   NULL, 
									   NO, 
									   kCGRenderingIntentDefault);
	
	UIImage *image = [UIImage imageWithCGImage:cgImage];
	
	CGColorSpaceRelease(colorSpace);	
	CGImageRelease(cgImage);
	CGDataProviderRelease(provider);
	CFRelease(data);
	
	return image;
}

-(void)structInit
{
	NSLog(@"enter structInit...");
	//memset(&me, 0, sizeof(me));
	me.pictQueueSize = 0;
	me.pictQueueRI = 0;
	me.pictQueueWI = 0;	
	me.displayThreadExist = 0;
	me.videoThreadExist = 0;
	me.audioThreadExist = 0;	
	me.decoderThreadReload = 0;
	me.pauseStream = 0;
	me.decodeStop = 1;
	me.videoStreamIndex = -1;
	me.audioStreamIndex = -1;	
	me.decodeTimeout = av_gettime();
	me.pFormatCtx = nil;
	me.videoQueue.lock = nil;
	me.audioQueue.lock = nil;
	me.videoStream = 0;
	me.audioStream = 0;
	me.pictQueueCondition = nil;
	me.pictQueueLock = nil;
	
	//av_init_packet(&flush_packet);
    //flush_packet.data= (uint8_t *)"FLUSH";
	
	NSLog(@"exit structInit...");
}

-(void)cleanOccupiedResource
{
	NSLog(@"enter cleanOccupiedResource...");
	double stopCommandRefT = av_gettime();
	//while(me.videoThreadExist || me.audioThreadExist || me.displayThreadExist)
	while(me.audioThreadExist || me.displayThreadExist)
	{		
		// wait at maximum 8 seconds for the display thread to stop
		if((av_gettime()-stopCommandRefT) > TIME_PERIOD_SESSION_BACK_TO_READY)
		{
			me.videoThreadExist = 0;
			me.audioThreadExist = 0;
			me.displayThreadExist = 0;
			break;	
		}	
		usleep(10000);
	}		
	NSLog(@"wait audio/display thread done");
	
	if(me.videoQueue.lock)
	{
		[me.videoQueue.lock release];
		me.videoQueue.lock = nil;
		NSLog(@"release me.videoQueue done");
	}
	if(me.audioQueue.lock)
	{
		[me.audioQueue.lock release];
		me.audioQueue.lock = nil;
		NSLog(@"release me.audioQueue done");
	}
	if(me.videoStream && me.videoStreamIndex >= 0)
	{
		avcodec_close(me.pFormatCtx->streams[me.videoStreamIndex]->codec);
		me.videoStream = 0;
		NSLog(@"close me.videoStream video codec done");
	}	
	if(me.audioStream && me.audioStreamIndex >= 0)
	{
		avcodec_close(me.pFormatCtx->streams[me.audioStreamIndex]->codec);
		me.audioStream = 0;
		NSLog(@"close me.audioStream audio codec done");
	}	
	
	if(me.pFormatCtx)
	{
		av_close_input_file(me.pFormatCtx);
		me.pFormatCtx = nil;
		NSLog(@"close me.pFormatCtx done");
	}
		
	NSLog(@"exit cleanOccupiedResource...");
}

- (void)packetQueueInit:(PacketQueue*)q 
{
	memset(q, 0, sizeof(PacketQueue));
}

- (BOOL)packetQueuePut:(PacketQueue*)q withPacket:(AVPacket*)pkt
{
	
	AVPacketList *pkt1;
	if(av_dup_packet(pkt) < 0) 
	{
		return NO;
	}
	pkt1 = av_malloc(sizeof(AVPacketList));
	if (!pkt1)
		return NO;
	
	pkt1->pkt = *pkt;
	pkt1->next = NULL;
	
	[q->lock lock];
	
	if (!q->last_pkt)
		q->first_pkt = pkt1;
	else
		q->last_pkt->next = pkt1;
	q->last_pkt = pkt1;
	q->packets++;
	q->size += pkt1->pkt.size + sizeof(*pkt1);
	
	[q->lock unlock];
	
	return YES;
}

- (void) packetQueueFlush:(PacketQueue*)q
{
    AVPacketList *pkt, *pkt1;
	
    [q->lock lock];
	
    for(pkt = q->first_pkt; pkt != NULL; pkt = pkt1) {
        pkt1 = pkt->next;
        av_free_packet(&pkt->pkt);
        av_freep(&pkt);
    }
    q->last_pkt = NULL;
    q->first_pkt = NULL;
    q->packets = 0;
	q->size = 0;
	
	[q->lock unlock];
}

- (BOOL)packetQueueGet:(PacketQueue*)q withPacket:(AVPacket*)pkt
{
	AVPacketList *pkt1;
	BOOL ret;
	
	[q->lock lock];
	
	pkt1 = q->first_pkt;
	if (pkt1) {
		q->first_pkt = pkt1->next;
		if (!q->first_pkt)
			q->last_pkt = NULL;
		q->packets--;
		q->size -= pkt1->pkt.size + sizeof(*pkt1);
		*pkt = pkt1->pkt;
		av_free(pkt1);
		ret = YES;
	} else {
		ret = NO;
	}
	
	[q->lock unlock];
	
	return ret;
}

#pragma mark frame timestamp treatment
-(double)getFramePTS:(AVFrame *)src_frame withPTS:(double)pts 
{	
	double frame_delay;
	
	if(pts != 0) 
	{
		// if we have pts, set video clock to it 
		me.videoClock = pts;
	} 
	else 
	{
		// if we aren't given a pts, set it to the clock 
		pts = me.videoClock;
	}
	
	// update the video clock
	frame_delay = av_q2d(me.videoStream->codec->time_base);
	// if we are repeating a frame, adjust clock accordingly 
	frame_delay += src_frame->repeat_pict * (frame_delay * 0.5);
	me.videoClock += frame_delay;
	
	return pts;
}

-(double)computeFrameDelay:(double)currFramePTS
{
    double actual_delay, delay;
	
	/* compute nominal delay */
	delay = (currFramePTS - me.lastFramePTS);
	if(delay <= 0 || delay >= 2.0) 
	{
		/* if incorrect delay, maybe caused by drop frame, we use previous one */
		delay = me.lastFrameDelay;
	} 
	else 
	{
		me.lastFrameDelay = delay;
	}
	me.lastFramePTS = currFramePTS;	
	me.frameTimer += delay;
	
	/* compute the REAL delay*/
	actual_delay = me.frameTimer - (av_gettime()/1000000.0);
	//fprintf(stderr, "aq=%d, vq=%d, pq = %d, currFramePTS = %f, delay=%f, actual_delay=%f\n", me.audioQueue.size ,me.videoQueue.size,me.pictQueueSize,currFramePTS, delay, actual_delay);
	
	if(actual_delay < 0.010)
	{
		/*TODO should skip picture*/
		actual_delay = 0.010;
	}
	
	return actual_delay;
}



#pragma mark audio treatment

-(BOOL)streamOpen:(int)streamIndex 
{	
	NSLog(@"enter audio thread creation...");
	AVFormatContext *pFormatCtx = me.pFormatCtx;
	AVCodecContext *codecCtx;
	AVCodec *codec;
	
	if(streamIndex < 0 || streamIndex >= pFormatCtx->nb_streams) 
	{
		return NO;
	}
	
	// Get a pointer to the codec context for the video stream
	codecCtx = pFormatCtx->streams[streamIndex]->codec;
	NSLog(@"avcodec_find_decoder");
	codec = avcodec_find_decoder(codecCtx->codec_id);
	if(!codec || (avcodec_open(codecCtx, codec) < 0)) 
	{		
		NSLog(@"Error: av(audio) decoder not found.");
		fprintf(stderr, "Unsupported codec! [index = %d]\n", streamIndex);
		return NO;
	}
	
	switch(codecCtx->codec_type) 
	{
		case CODEC_TYPE_AUDIO:			
			me.audioStreamIndex = streamIndex;
			me.audioStream = pFormatCtx->streams[streamIndex];			
			[self packetQueueInit: &me.audioQueue];
			me.audioQueue.lock = [[NSLock alloc] init];
			me.audioThreadExist = 1;
			[NSThread detachNewThreadSelector:@selector(audioProcessThread) toTarget:self withObject:nil];
			NSLog(@"audio thread on");
			break;
		/*	
		case CODEC_TYPE_VIDEO:			
			me.videoStreamIndex = streamIndex;
			me.videoStream = pFormatCtx->streams[streamIndex];			
			me.frameTimer = (double)av_gettime() / 1000000.0;			
			me.pictQueueLock = [[NSLock alloc] init];
			me.pictQueueCondition = [[NSCondition alloc] init];			
			[self packetQueueInit: &me.videoQueue];
			me.videoQueue.lock = [[NSLock alloc] init];
			
			//Alex for 4.0 test
			me.videoThreadExist = 1;
			NSLog(@"creat video process thread");
			[NSThread detachNewThreadSelector:@selector(videoProcessThread) toTarget:self withObject:nil];
			me.displayThreadExist = 1;
			NSLog(@"creat video display thread");
			[NSThread detachNewThreadSelector:@selector(videoDisplayThread) toTarget:self withObject:nil];
			
			break;
		*/
		default:
			if(codecCtx->codec_type != CODEC_TYPE_VIDEO)
				return NO;
			break;
	}
	NSLog(@"exit audio thread creation...");
	return YES;
}


- (void)audioProcessThread
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"enter audio process thread...");
	
	// Setup the audio device.
	AudioStreamBasicDescription deviceFormat;
	deviceFormat.mSampleRate = me.audioStream->codec->sample_rate; //44100; 
	deviceFormat.mFormatID = kAudioFormatLinearPCM;
	deviceFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;	
	deviceFormat.mBitsPerChannel = 16;
	deviceFormat.mChannelsPerFrame = me.audioStream->codec->channels;
	deviceFormat.mBytesPerFrame = deviceFormat.mBitsPerChannel*deviceFormat.mChannelsPerFrame/8;
	deviceFormat.mFramesPerPacket = 1;
	deviceFormat.mBytesPerPacket = deviceFormat.mFramesPerPacket*deviceFormat.mBytesPerFrame;
	deviceFormat.mReserved = 0;
	
	// Create a new output AudioQueue for the device.
	AudioQueueNewOutput(&deviceFormat, AudioQueueCallback, self,
						CFRunLoopGetCurrent(), kCFRunLoopCommonModes,
						0, &me.audioPlayQueue);
	
	// Allocate buffers for the AudioQueue, and pre-fill them.
	for (int i = 0; i < AUDIO_PLAY_QUEUE_NUM; ++i) {		
		if (AudioQueueAllocateBuffer(me.audioPlayQueue, AUDIO_PLAY_QUEUE_SIZE, &me.audioQueueBuf[i]) != noErr)
			break;
		AudioQueueCallback(NULL, me.audioPlayQueue, me.audioQueueBuf[i]);
	}
	
	AudioQueueStart(me.audioPlayQueue, NULL);
	//AudioQueueFlush(me.audioPlayQueue);
	
	do
	{
		CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.25, false);
	}while ([self terminated] == NO);
	
	AudioQueueStop(me.audioPlayQueue, TRUE);
	AudioQueueDispose(me.audioPlayQueue, TRUE);
	
	[me.audioQueue.lock release];
	me.audioThreadExist = 0;
	NSLog(@"exit audio process thread...");
	
	[pool release];
}



- (int)decodeAudioFrame
{
	AVPacket pkt1, *packet = &pkt1;
	AVPacket pkt2, *pkt_temp = &pkt2;
	int len1;
	
	while([self terminated] == NO)
	{					
		if(![self packetQueueGet: &me.audioQueue withPacket:packet]) 
		{
			continue;
		}	
		
		pkt_temp->data = packet->data;
		pkt_temp->size = packet->size;
		
		if(packet->pts != AV_NOPTS_VALUE) {
			me.audioClock = av_q2d(me.audioStream->time_base)*packet->pts;
		}
		
		while (pkt_temp->size > 0)
		{
			me.audioFrameSize = sizeof(me.audioSamples1);
			len1 = avcodec_decode_audio3(me.audioStream->codec, (int16_t *)me.audioSamples1, &(me.audioFrameSize), pkt_temp);
			if(len1 < 0) {
				/* if error, skip frame */
				pkt_temp->size = 0;
				break;
			}
			
			pkt_temp->data += len1;
			pkt_temp->size -= len1;
			
			if(me.audioFrameSize <= 0) 
			{
				/* No data yet, get more frames */
				continue;
			}		
			
			if (me.audioStream->codec->sample_fmt != SAMPLE_FMT_S16) {
                if (me.audioConvert)
                    av_audio_convert_free(me.audioConvert);
				
                me.audioConvert = av_audio_convert_alloc(SAMPLE_FMT_S16, 1,
                                                         me.audioStream->codec->sample_fmt, 1, NULL, 0);
                if (!me.audioConvert) {
                    fprintf(stderr, "Cannot convert %s sample format to %s sample format\n",
							avcodec_get_sample_fmt_name(me.audioStream->codec->sample_fmt),
							avcodec_get_sample_fmt_name(SAMPLE_FMT_S16));
					break;
                }
            }
			
            if (me.audioConvert) {
                const void *ibuf[6]= {me.audioSamples1};
                void *obuf[6]= {me.audioSamples2};
                int istride[6]= {av_get_bits_per_sample_format(me.audioStream->codec->sample_fmt)/8};
                int istride[6]= {av_get_bits_per_sample_fmt(me.audioStream->codec->sample_fmt)/8};
                int ostride[6]= {2};
                int len= me.audioFrameSize/istride[0];
                if (av_audio_convert(me.audioConvert, obuf, ostride, ibuf, istride, len)<0) {
                    fprintf(stderr, "av_audio_convert() failed\n");
                    break;
                }
                me.audioSamples = me.audioSamples2;
                /* TODO existing code assume that data_size equals framesize*channels*2
				 remove this legacy cruft */
                me.audioFrameSize= len*2;
            }
			else
			{
                me.audioSamples = me.audioSamples1;
            }
			
			//TODO audio/video sync
			int n = 2 * me.audioStream->codec->channels;
			me.audioClock += (double)me.audioFrameSize /
			(double)(n *me.audioStream->codec->sample_rate);
			
			av_free_packet(packet);
			
			return me.audioFrameSize;
		}		
	}	
	
	while([self packetQueueGet: &me.audioQueue withPacket:packet]) 
	{
		av_free_packet(packet);
	}
	
	return -1;
}

- (void)fillAudioQueue:(AudioQueueBufferRef)outBuffer withQueue:(AudioQueueRef)queue
{
	UInt32 bytes = outBuffer->mAudioDataBytesCapacity;
	void* pBuffer = outBuffer->mAudioData;
	
	while (bytes > 0)
	{
		if([self terminated] == YES) 
		{	
			return;
		}		
		
		if (bytes >= me.audioFrameSize)
		{
			if (me.audioFrameSize > 0)
			{
				memcpy(pBuffer, me.audioSamples, me.audioFrameSize);
				bytes -= me.audioFrameSize;
				pBuffer += me.audioFrameSize;
				me.audioFrameSize = 0;
			}
			else
			{
				if([self decodeAudioFrame] < 0)
				{
					//TODO, decode fail, Continue?
					continue;
				}
			}
		}
		else
		{
			memcpy(pBuffer, me.audioSamples, bytes);
			me.audioFrameSize -= bytes;
			memmove(me.audioSamples, me.audioSamples+bytes, me.audioFrameSize);
			break;
		}
	}
	
	outBuffer->mAudioDataByteSize = outBuffer->mAudioDataBytesCapacity;
	AudioQueueEnqueueBuffer(me.audioPlayQueue, outBuffer, 0, NULL);
}

-(void)dealloc
{

	[super dealloc];
}


@end
