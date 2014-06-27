//
//  MjpegWrapper.m
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

#import <unistd.h>
#import <QuartzCore/QuartzCore.h>
#import "MjpegWrapper.h"
#import "Streaming.h"
#import "ConstantDef.h"
#import "Viewport.h"

#import <CFNetwork/CFNetwork.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h> 
#import <netdb.h>
#import <sys/time.h>
#import "RtpParser.h"
#import "Md5.h"
#import "Base64.h"
#import "DyBuffer.h"
#import "DeviceCache.h"
#import "DeviceData.h"
#import "TerraUIAppDelegate.h"

#define FRAMELISTDEFAULT  5

static NSString* mjpeg_lock =@"lock";

static void my_sleep(int s,int us)
{
	
	struct timeval tout;
	
	tout.tv_sec  = s;
	tout.tv_usec = us;
	
	select(0,NULL,NULL,NULL,&tout);
	
}

@implementation MjpegWrapper

@synthesize paused;
@synthesize terminated;
@synthesize streamingStatus;
@synthesize delegate;
@synthesize frames;
@synthesize stream_t;

static int cntt=0;
- (id) init 
{
	
	if ((self = [super init]) == nil)
		return nil;
	
	NSLog(@"MJPEG alloc count =%d\n",++cntt);
	myid = cntt;
	stream_t = NULL;
	return self;
}



-(void)DrawView:(UIImage*)img PTS:(int)pts
{
	Streaming *stream = (Streaming *)[self delegate];
	Viewport *vw      = (Viewport *) [stream delegate];
	
	double diff;
	struct timeval tv;	
	diff = 0.0;
	
	if(isFirstDraw)
	{
		pts = 0;
		isFirstDraw = NO;
	}
	
	if(pts == 0)
	{
		gettimeofday(&tv,NULL);
		start_time = (int64_t)tv.tv_sec*1000000+tv.tv_usec;
		pre_pts = 0;
	} 
	else if(pts > 0)
	{
		@synchronized(mjpeg_lock)
		{
			struct timeval tv2;
			gettimeofday(&tv2,NULL);
			
			int64_t now = (int64_t)tv2.tv_sec*1000000+tv2.tv_usec;
			double delta = (now - start_time);
			//double frame_time = (double)(pts) / (double)time_base;
			//double frame_time_pre = (double)(pre_pts) / (double)time_base;
			double cur_pts = (double)(pts - pre_pts) / (double)time_base;
			diff = (cur_pts *1000000 - delta);
			
			/*
			 NSLog(@"------------------------------- %d\n",myid);
			 NSLog(@"time base = .....%d\n",time_base);
			 NSLog(@"Pts =............%d\n",pts);
			 NSLog(@"pre_pts =........%d\n",pre_pts);
			 NSLog(@"frame_time =.....%f\n",frame_time);
			 NSLog(@"frame_time_pre = %f\n",frame_time_pre);
			 NSLog(@"start_time = ....%lld\n",start_time);
			 NSLog(@"now =............%lld\n",now);
			 NSLog(@"cur_pts =........%f\n",(cur_pts *1000000));
			 NSLog(@"delta =..........%f\n",delta);
			 NSLog(@"diff =...........%f\n",diff);
			 */
			start_time = now;
			pre_pts = pts;
		}		
	}
	
	if(diff>0)
	{
		if(diff > 10000.0)
		{
			diff -= 10000.0;
			if(![[NSThread currentThread] isCancelled])
			{
				if((diff) < 3000000)
				{
					//NSLog(@"sleep ..%f(%d)\n",diff,myid);
					my_sleep((diff/1000000),((int)diff % 1000000)); 
				}
				else 
				{
					NSLog(@"sleep too long..%f(%d)\n",diff);
					return;
				}
			}
			else 
				return;
		}
		
	}
	else 
	{
		if(diff > (double)(-2* 1000000) && diff < (double)(-1* 1000000))
		{
			NSLog(@"drop frame..%f(%d)\n",diff,myid);
			return;
		}
		else if(diff < (double)(-2* 1000000))
		{
			NSLog(@"delay over 2sec..%f(%d)\n",diff,myid);
		}
		
	}
	
	if(![[NSThread currentThread] isCancelled])
	{
		if(img && img.CGImage)
		{
			
			NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
			[[vw layer] performSelectorOnMainThread:@selector(setContents:)withObject:(id)img.CGImage waitUntilDone:NO];
			[apool release];
			//[img release];
		}
	}
	
}

-(void) PlayView:(id) data
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
	unsigned int pts;
	
	UIImage* im;
	DyBuffer *video_buf = (DyBuffer*)data;
	
		
	int ret;
	
	NSLog(@"PlayView start ---------------(%d)\n",myid);
	
	isFirstDraw = YES;
	
	while(![[NSThread currentThread] isCancelled])
	{
		
		im = nil;
		ret = [video_buf GetFrameOnList:&im withPTS:&pts];
		if(ret < 0) 
			continue;
	
		[self DrawView:im PTS:pts];
		[im release];
	
	}
	
	
	NSLog(@"PlayView end ---------------(%d)\n",myid);
	[video_buf CleanFrameOnList];
	//[NSThread exit];
	[pool release];
	
}
-(void)streamDownloadThread:(NSString*)urlString
{

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	Streaming *stream = (Streaming *)[self delegate];
	DeviceData *dev = [[DeviceCache sharedDeviceCache] deviceAtIndex:[stream opTag]-1];
	Viewport *vw      = (Viewport *) [stream delegate];
	int errCode = 0;
	
	if(!stream || !dev)
	{
		//[self setStreamingStatus:STREAM_SESSION_STATUS_STOP];
		//[self forwardStatus:DEVICE_STATUS_SESSION_FAILURE];	
		[self setStreamingStatus:STREAM_SESSION_STATUS_PLAY];
		[self forwardStatus:DEVICE_STATUS_ONLINE];
		[pool release];
		NSLog(@"streamDownloadThread MJPEG(%d) error urlString = %@\n",myid,urlString);
		return;
	}
	
	
	//NSLog(@"streamDownloadThread (%d) urlString = %@\n",myid,urlString);
	/*
	if(myid > 5)
	{
		//[self setStreamingStatus:STREAM_SESSION_STATUS_STOP];
		//[self forwardStatus:DEVICE_STATUS_SESSION_FAILURE];	
		[self setStreamingStatus:STREAM_SESSION_STATUS_PLAY];
		[self forwardStatus:DEVICE_STATUS_ONLINE];
		[pool release];
		return;
	}
	*/
	BOOL terminatedDueToDataRxError = NO;
	RtspClient  *rtsp_cm;
	RtspClient  *rtsp_rx;
	RtpParser   *rtp_parser;
    MjpegParser *jp_parser;
	//DyBuffer    *video_buf;
	//NSThread    *play_thread;
	
	
	
	
	NSLog(@"Nash streamDownloadThread ------------------------------ tag (%d) in(%d)\n",([stream opTag]-1),myid);
	int runMode = RUN_SERVER_MODE;
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication] delegate];	
	if(appDelegate != nil)	
		runMode = [[appDelegate dataCenter] getMobileMode];
	
	const char* addr;
	if(runMode == RUN_SERVER_MODE)
		addr = [[dev relayIP] UTF8String];
	else
		addr = [[dev IP] UTF8String];
	
	const char* auth_name = [[dev authenticationName] UTF8String];
	const char* auth_pw   = [[dev authenticationPassword] UTF8String]; 

	
	
	// add the becon if required
	NSString *authenticationToken = [NSString stringWithFormat:@"&beacon=%@", [dev authenticationToken]];
	int auth_port = [dev portNum];
	
	NSString *destinationURL;	
	
	NSString *fileURL = [NSString stringWithString:@"/img/video.sav?video=MJPEG"]; 
	if(runMode == RUN_SERVER_MODE)
		destinationURL = [NSString stringWithFormat:@"%@%@", fileURL, authenticationToken];
	else
		destinationURL = fileURL;
	
	char* url = (char*)[destinationURL UTF8String];
	NSLog(@"MJPEG..URL: %s", url);
	NSLog(@"Mjpeg : IP = %s,name = %s,pw = %s\n",addr,auth_name,auth_pw);
	//
	
	//char addr[] = "219.87.146.27";
	//char addr[] = "192.168.10.108";; // test
	char ck[33];
	char req_cmd[RT_CMD_LENGTH];
	
reDownload:
	errCode = 0;
	terminatedDueToDataRxError = NO;
	
	rtsp_cm    = [[RtspClient  alloc] init];
	rtsp_rx    = [[RtspClient  alloc] init];
	rtp_parser = [[RtpParser   alloc] init];
    jp_parser  = [[MjpegParser alloc] init];
	//video_buf  = [[DyBuffer    alloc] init];
	//[video_buf set_myid:myid]; 	
	
	
	NSLog(@"Nash start run MJPEG  connetion------------------------------(%d)\n",myid);
@synchronized(mjpeg_lock)
{	
	[RtspClient InitXsession:ck];
	[rtsp_cm SetXsession:ck];
	[rtsp_rx SetXsession:ck];
	[rtsp_cm SetUsername:(char*)auth_name Password:(char*)auth_pw];
	[rtsp_rx SetUsername:(char*)auth_name Password:(char*)auth_pw];
	[rtsp_cm SetPort:auth_port];
	[rtsp_rx SetPort:auth_port];
 	
	if(![rtsp_cm ConnectWithAddr:(char*)addr] || [[NSThread currentThread] isCancelled])
	{
		rterr("rtsp_cm ConnectWithAddr error\n");
		errCode = [rtsp_cm RetrieveErrCode];
		goto MjpegExit;
	}
	if(![rtsp_rx ConnectWithAddr:(char*)addr] || [[NSThread currentThread] isCancelled])
	{
		rterr("rtsp_rx ConnectWithAddr error\n");
		errCode = [rtsp_rx RetrieveErrCode];
		goto MjpegExit;
	}
}
	
	NSLog(@"Nash start run MJPEG  Get cmd------------------------------(%d)\n",myid);
	if(![rtsp_rx RequestWithCmd:RT_HTTP_GET Encode:NO Data:url] || [[NSThread currentThread] isCancelled]) 
	{
		rterr("rtsp_rx RequestWithCmd:RT_HTTP_GET Encode:NO Data:RT_REQ_FILE error\n");
		errCode = [rtsp_rx RetrieveErrCode];
		goto MjpegExit;
	}
	
	if(![rtsp_rx ResponseWithHttpCmd:RT_HTTP_GET RtspCmd:RT_RTSP_CUSTOM StreamType:RT_STREAM_VIDEO] || [[NSThread currentThread] isCancelled])
	{	
		rterr("rtsp_rx ResponseWithHttpCmd:RT_HTTP_GET RtspCmd:RT_RTSP_CUSTOM StreamType:RT_STREAM_VIDEO error\n");
		errCode = [rtsp_rx RetrieveErrCode];
		goto MjpegExit;
	}
		NSLog(@"Nash start run MJPEG post cmd------------------------------(%d)\n",myid);
	if(![rtsp_cm RequestWithCmd:RT_HTTP_POST Encode:NO Data:url] || [[NSThread currentThread] isCancelled])
	{
		rterr("rtsp_cm RequestWithCmd:RT_HTTP_GET Encode:NO Data:RT_REQ_FILE error\n");
		errCode = [rtsp_cm RetrieveErrCode];
		goto MjpegExit;
	}
	
	[rtsp_cm GenRtspCmd:RT_RTSP_DESCRIBE CmdStr:req_cmd StreamType:RT_STREAM_VIDEO Encode:NO];
	
	rtmsg("DESCRIBE req_cmd = %s\n",req_cmd);
	
	NSLog(@"Nash start run MJPEG  post describe cmd------------------------------(%d)\n",myid);
	if( ![rtsp_cm RequestWithCmd:RT_HTTP_POST Encode:YES Data:req_cmd] || [[NSThread currentThread] isCancelled]) 
	{
		rterr("rtsp_cm RequestWithCmd:RT_HTTP_POST Encode:YES Data:req_cmd error\n");
		errCode = [rtsp_cm RetrieveErrCode];
		goto MjpegExit;
	}
	
	if(![rtsp_rx ResponseWithHttpCmd:RT_HTTP_GET RtspCmd:RT_RTSP_DESCRIBE StreamType:RT_STREAM_VIDEO] || [[NSThread currentThread] isCancelled])
	{	
		rterr("rtsp_rx ResponseWithHttpCmd:RT_HTTP_GET RtspCmd:RT_RTSP_DESCRIBE StreamType:RT_STREAM_VIDEO error\n");
		errCode = [rtsp_rx RetrieveErrCode];
		goto MjpegExit;
	}
	

	[rtsp_cm SetAudioDesc:[rtsp_rx GetAudioDesc]];
	[rtsp_cm SetVideoDesc:[rtsp_rx GetVideoDesc]];
	

	// setup video
	NSLog(@"Nash start run MJPEG  set video------------------------------(%d)\n",myid);
	
	[rtsp_cm GenRtspCmd:RT_RTSP_SETUP CmdStr:req_cmd StreamType:RT_STREAM_VIDEO Encode:NO];
	rtmsg("SETUP req_cmd = %s\n",req_cmd);
	
		
	if(![rtsp_cm RequestWithCmd:RT_HTTP_POST Encode:YES Data:req_cmd] || [[NSThread currentThread] isCancelled])
	{
		rterr("rtsp_cm RequestWithCmd:RT_HTTP_POST Encode:YES Data:req_cmd error\n");
		errCode = [rtsp_cm RetrieveErrCode];
		goto MjpegExit;
	}
	

	if(![rtsp_rx ResponseWithHttpCmd:RT_HTTP_GET RtspCmd:RT_RTSP_SETUP StreamType:RT_STREAM_VIDEO] || [[NSThread currentThread] isCancelled])
	{	
		rterr("rtsp_rx ResponseWithHttpCmd:RT_HTTP_GET RtspCmd:RT_RTSP_SETUP StreamType:RT_STREAM_VIDEO error\n");
		errCode = [rtsp_rx RetrieveErrCode];
		goto MjpegExit;
	}

	/*
	// setup audio
	[rtsp_cm GenRtspCmd:RT_RTSP_SETUP CmdStr:req_cmd StreamType:RT_STREAM_AUDIO Encode:NO];
	
	rtmsg("SETUP req_cmd = %s\n",req_cmd);
	
	if(![rtsp_cm RequestWithCmd:RT_HTTP_POST Encode:YES Data:req_cmd])
	{
		rterr("rtsp_cm RequestWithCmd:RT_HTTP_POST Encode:YES Data:req_cmd error\n");
		goto MjpegExit;
	}
	if(![rtsp_rx ResponseWithHttpCmd:RT_HTTP_GET RtspCmd:RT_RTSP_SETUP StreamType:RT_STREAM_AUDIO])
	{
		rterr("rtsp_rx ResponseWithHttpCmd:RT_HTTP_GET RtspCmd:RT_RTSP_SETUP StreamType:RT_STREAM_AUDIO error\n");
		goto MjpegExit;
	}
	*/
	
	NSLog(@"Nash start run MJPEG  post play cmd------------------------------(%d)\n",myid);
	[rtsp_cm GenRtspCmd:RT_RTSP_PLAY CmdStr:req_cmd StreamType:RT_STREAM_VIDEO Encode:NO];
	rtmsg("SETUP req_cmd = %s\n",req_cmd);
	
	if(![rtsp_cm RequestWithCmd:RT_HTTP_POST Encode:YES Data:req_cmd] || [[NSThread currentThread] isCancelled])
	{
		rterr("rtsp_cm RequestWithCmd:RT_HTTP_POST Encode:YES Data:req_cmd error\n");
		errCode = [rtsp_cm RetrieveErrCode];
		goto MjpegExit;
	}
	if(![rtsp_rx ResponseWithHttpCmd:RT_HTTP_GET RtspCmd:RT_RTSP_PLAY StreamType:RT_STREAM_VIDEO] || [[NSThread currentThread] isCancelled])
	{
		rterr("rtsp_rx ResponseWithHttpCmd:RT_HTTP_GET RtspCmd:RT_RTSP_PLAY StreamType:RT_STREAM_VIDEO error\n");
		errCode = [rtsp_rx RetrieveErrCode];
		goto MjpegExit;
	}
	//[rtsp_rx DumpInfo];
	frate = [rtsp_rx GetMaxFrameRate];
	//frameBufCnt = frate /5; 
	time_base = [rtsp_rx GetTimeBase];
	
	//int bufcnt = frate /5;//auto buf count 0.2s	
	//[video_buf SetMaxBuf:((bufcnt>0)? bufcnt:1)];
	
	[rtp_parser SetChanelVideo:[rtsp_rx GetVideoInterleaved] Audio:[rtsp_rx GetAudioInterleaved]]; 
	

	//NSLog(@"Nash start run MJPEG  create playview------------------------------(%d)\n",myid);
	
			
	[self setTerminated:NO];
	[self setStreamingStatus:STREAM_SESSION_STATUS_PLAY];
	[self forwardStatus:DEVICE_STATUS_ONLINE];
	
	/*
	if(![[NSThread currentThread] isCancelled])
	{
		play_thread = [[NSThread alloc] initWithTarget:self selector:@selector(PlayView:) object:video_buf ];
		[play_thread setThreadPriority:0.9];
		[play_thread start];
	}
	*/
	
	//while([self terminated] == NO) 
	while(![[NSThread currentThread] isCancelled])
	{
		if([rtp_parser ParserPayload:rtsp_rx Parser:jp_parser])
		{
			
			int pp_len;
			unsigned char *jp = [jp_parser GetData:&pp_len];
			
			if(pp_len <= 0)
			{
				rterr("get jpeg length == 0, pass this frame...\n");
				continue;
			}
		
			NSData *ns_data = [[NSData alloc] initWithBytes:jp length:pp_len];	
			
			UIImage *im = [[UIImage alloc] initWithData:ns_data];
			
			if([stream snapshotRequest] == YES)
			{
				[stream setSnapshotImage:im];
				[stream setSnapshotRequest:NO];
				[stream captureSnapshotImage:YES];		
			}			
			[vw updateViewportSnapshot:im];		
			
			//[self DrawView:im PTS:[rtp_parser GetPts]];
			[self DrawView:im PTS:[rtp_parser GetPts]];
			[im release];
			/*
			int ret;
			ret = [video_buf PutFrameOnList:im withPTS:[rtp_parser GetPts]];

			if(ret <0)
			{
				NSLog(@"buffer full!--(%d)\n",myid);
				[video_buf CleanFrameOnList];
				ret = [video_buf PutFrameOnList:im withPTS:[rtp_parser GetPts]];
				if(ret <0)
				{
					NSLog(@"reset buf fail (%d)\n",myid);
					[im release];
				}
			}
			*/
			
			[ns_data release];
				
			//must clean parser data after play
			[jp_parser CleanData];
			
		}
		else 
		{
			if([rtsp_rx GetRecvError] >= RTP_MAX_ERROR)
			{
				if(![[NSThread currentThread] isCancelled])
				{
					
					NSLog(@"Nash re-run MJPEG-----------------------------(%d)\n",myid);
					terminatedDueToDataRxError = YES;
					//[play_thread cancel];
					errCode = DEVICE_STATUS_DATA_RX_ERROR_AFTER_SESSION_SETUP;
					goto MjpegExit;
				}
				else
				{
					NSLog(@"Nash MJPEG error-----------------------------(%d)\n",myid);
					//[play_thread cancel];
					errCode = DEVICE_STATUS_DATA_RX_ERROR_AFTER_SESSION_SETUP;
					goto MjpegExit;
				}
			}
		}
	}
	
	//[play_thread cancel];
	
	NSLog(@"Nash start run MJPEG  post teardown------------------------------(%d)\n",myid);
	[rtsp_cm GenRtspCmd:RT_RTSP_TEARDOWN CmdStr:req_cmd StreamType:RT_STREAM_VIDEO Encode:NO];
	rtdbg("TEARDOWN req_cmd = %s\n",req_cmd);
	
	if(![rtsp_cm RequestWithCmd:RT_HTTP_POST Encode:YES Data:req_cmd] || [[NSThread currentThread] isCancelled])
	{
		rterr("rtsp_cm RequestWithCmd:RT_HTTP_POST Encode:YES Data:req_cmd error\n");
		errCode = [rtsp_cm RetrieveErrCode];
		goto MjpegExit;
	}
	/*
	if(![rtsp_rx ResponseWithHttpCmd:RT_HTTP_GET RtspCmd:RT_RTSP_TEARDOWN StreamType:RT_STREAM_VIDEO])
	{	
		rterr("rtsp_rx ResponseWithHttpCmd:RT_HTTP_GET RtspCmd:RT_RTSP_TEARDOWN StreamType:RT_STREAM_VIDEO error\n");
		goto MjpegExit;
	}
	*/
MjpegExit:
	
	
	//[video_buf CleanFrameOnList];
	[jp_parser CleanData];
	
	
 
	[rtp_parser release];
    [jp_parser  release];
	
	[rtsp_cm CloseConnect];
	[rtsp_rx CloseConnect];
	
	[rtsp_cm release];
	[rtsp_rx release];
	
	//[video_buf release];
	NSLog(@"errCode: %d", errCode);
	if(terminatedDueToDataRxError == YES)
	{
		rterr("Has recv error -----reload all....\n");
		goto reDownload;
	}
	
	[self setStreamingStatus:STREAM_SESSION_STATUS_STOP];
	[self forwardStatus:errCode];	

	
	NSLog(@"Nash streamDownloadThread ------------------------------ out(%d)\n",myid);	
	
    [pool release];
	
	[NSThread exit];
}



-(int)viewportTag
{
	if([delegate respondsToSelector:@selector(associatedMjpegViewportTag:)])		
		return [delegate associatedMjpegViewportTag:self];	
	
	return 0;	
}
-(void)launchStreaming:(NSString*)urlString
{	
	NSLog(@"enter launchStreaming...mjpeg");
	// if there is already an session ready or session setup ongoing, do nothing

	if(([self streamingStatus] == STREAM_SESSION_STATUS_SETUP_ONGOING)
	   || ([self streamingStatus] == STREAM_SESSION_STATUS_PLAY))
	{
		if([self streamingStatus] == STREAM_SESSION_STATUS_PLAY)
			[self forwardStatus:DEVICE_STATUS_PREPARE_FOR_ONLINE];
		if([self streamingStatus] == STREAM_SESSION_STATUS_PLAY)
			[self forwardStatus:DEVICE_STATUS_ONLINE];
		
		NSLog(@"On going return...MJPEG\n");
		return;
	}
	
	// launch the download thread
	NSLog(@"Viewport: %d create streamDownloadThread done", [self viewportTag]);
	
	[self setStreamingStatus:STREAM_SESSION_STATUS_SETUP_ONGOING];
	[self forwardStatus:DEVICE_STATUS_PREPARE_FOR_ONLINE];
	
	//[NSThread detachNewThreadSelector:@selector(streamDownloadThread:) toTarget:self withObject:urlString];		
	stream_t = [[NSThread alloc] initWithTarget:self selector:@selector(streamDownloadThread:) object:urlString];
	[stream_t setThreadPriority:1.0];
	[stream_t start];
}

-(void)forwardStatus:(int)respondCode
{
	if([delegate respondsToSelector:@selector(streamingMjpegStatus:code:)])		
		[delegate streamingMjpegStatus:self code:respondCode];	
}

-(void)forwardImage:(UIImage*)img
{
	if([delegate respondsToSelector:@selector(decompressedMjpegFrame:withImage:)])
	{
		//NSLog(@"hand over the image...");
		[delegate decompressedMjpegFrame:self withImage:img];
	}
}

-(void)forwardImageResolution:(int)width height:(int)height
{
	if([delegate respondsToSelector:@selector(informMjpegImageResolution:withWidth:withHeight:)])
	{	
		[delegate informMjpegImageResolution:self withWidth:width withHeight:height];
	}
}

-(BOOL)askFocalMode
{
	if([delegate respondsToSelector:@selector(needPlayMjpegAudio:)])
		return [delegate needPlayMjpegAudio:self];
	return NO;
}

- (void)dealloc 
{
	NSLog(@"MJPEG alloc count =%d\n",cntt--);
	[super dealloc];	
}

@end
