/*
 *  ffmpegStructureDef.h
 *  HypnoTime
 *
 *  Created by Yen Jonathan on 2011/5/5.
 *
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


#import <AudioToolbox/AudioQueue.h>
//#import "libavcodec/audioconvert.h"
#import "libavformat/avformat.h"
#import "libavdevice/avdevice.h"
#import "MP4API.h"
#import "libavcodec/avcodec.h"
#import "libswscale/swscale.h"

#define FRAME_Y											256
#define FRAME_X											256
#define MAX_AUDIOQ_SIZE									131072	// 128K //262144		//256K
#define MAX_VIDEOQ_SIZE									262144	// 256K //524288		//512K
#define VIDEO_PICTURE_QUEUE_SIZE						3		//	10
#define AUDIO_PLAY_QUEUE_SIZE							16384	// 16K
#define AUDIO_PLAY_QUEUE_NUM							3

typedef struct PacketQueue 
{
	AVPacketList *first_pkt;
	AVPacketList *last_pkt;
	int packets;
	int size;
	// multi thread, need mutex
	NSLock *lock;
} PacketQueue;

typedef struct PictureQueue 
{
	double pts;
	AVPicture pict;
} PictureQueue;

typedef struct MessEngine
{
	/*
	 stream info, ffmpeg use
	 */
	AVFormatContext  *pFormatCtx;
	/*
	 decode, video, audio thread quit....
	 */
	int audioThreadExist;
	int videoThreadExist;
	int displayThreadExist;
	int decoderThreadReload;
	int decodeStop;
	int pauseStream;
	double decodeTimeout;
	int need_drop_frame;
	/*
	 record video stream index
	 */
	int	videoStreamIndex;
	AVStream *videoStream;
	/*
	 packet queue for video stream
	 */
	PacketQueue	videoQueue;
	/*
	 pts of last decoded video frame / predicted pts of next decoded frame
	 */
	double videoClock; 
	double frameTimer;
	double lastFramePTS;
	double lastFrameDelay;
	/*
	 picture queue for display video frame
	 */
	NSTimer *videoRefreshTimer;
	BOOL firstImageShowed;
	PictureQueue pictureQueue[VIDEO_PICTURE_QUEUE_SIZE];
	int pictQueueSize;
	int pictQueueRI;
	int pictQueueWI;
	NSLock *pictQueueLock;
	NSCondition *pictQueueCondition;
	
	/*
	 record audio stream index
	 */
	int audioStreamIndex;
	AVStream *audioStream;
	/*
	 packet queue for audio stream
	 */
	PacketQueue	audioQueue;
	/*
	 pts of last decoded audio frame / predicted pts of next decoded frame
	 */
#if 1
	double audioClock;
	DECLARE_ALIGNED(16,uint8_t,audioSamples1[(AVCODEC_MAX_AUDIO_FRAME_SIZE * 3) / 2]);
	DECLARE_ALIGNED(16,uint8_t,audioSamples2[(AVCODEC_MAX_AUDIO_FRAME_SIZE * 3) / 2]);
#endif
	uint8_t *audioSamples;
	int audioFrameSize;
	AVAudioConvert *audioConvert;
	/*
	 Used for audio play
	 */
	AudioQueueRef audioPlayQueue;
	AudioQueueBufferRef audioQueueBuf[AUDIO_PLAY_QUEUE_NUM];
	
	/*
	 used for recoording
	 */
	int MDATFd;
	int MP4Fd;
	int FramesInfoFd;
	FrameInfo frames;
	int lastFrameDTS;
	BOOL recordingFirstFrame;
	BOOL copyFinished;
	
} MessEngine;
