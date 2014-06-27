//
//  RtspClient.h
//  socketest
//
//  Created by ISBU Nash on 公元2011/06/03.
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

#define rtdbg     //printf
#define rterr     //printf
#define rtmsg     //printf

#define RT_TIMEOUT              5 //bug
#define RT_BUFFER_SIZE      20480
#define RT_CMD_LENGTH        4096
#define RT_SESSION_LENGTH      23
#define RT_USR_PW_LENGTH      128
#define RT_RECV_BUFFER_SIZE  2048
#define RT_CONTROL_DESC_LENGTH 32
      
#define RT_AUTH_PATTERN   "Authorization: Basic " 
#define RT_REQ_FILE       "/img/video.sav?video=MJPEG"

#define RT_HTTP_OK												"200 OK"
#define RT_HTTP_UNAUTHORIZATION									"401 Unauthorized"
#define RT_HTTP_DEVICE_BUSY										"503"
#define RT_HTTP_STREAM_TYPE_NOT_MATCHED							"404"

#define RT_G726_16   0
#define RT_G726_24   1
#define RT_G726_32   2
#define RT_G726_40   3
#define RT_G726_U    4
#define RT_G726_A    5
#define RT_AAC       6
#define RT_LPCM      7

#define RT_RTSP_DESCRIBE_CODEC_INFO_MJPEG     "JPEG"

#define RT_RTP_CODEC_MJPEG    3
#define RT_RTP_PAYLOAD_MJPEG 26

#define RT_FILELD(x,y,z)    ((x & y) >> z)

typedef enum {
	RT_HTTP_OPTIONS,
	RT_HTTP_GET,
	RT_HTTP_HEAD,
	RT_HTTP_POST,
	RT_HTTP_DELETE,
	RT_HTTP_TRACE,
	RT_HTTP_CONNECT,
	RT_HTTP_CUSTOM
	
} RT_HTTP_CMD;


typedef enum {
	RT_RTSP_DESCRIBE,
	RT_RTSP_ANNOUNCE,
	RT_RTSP_GET_PARAMETER,
	RT_RTSP_OPTIONS,
	RT_RTSP_PAUSE,
	RT_RTSP_PLAY,
	RT_RTSP_RECORD,
	RT_RTSP_REDIRECT,
	RT_RTSP_SETUP,
	RT_RTSP_SET_PARAMETER,
	RT_RTSP_TEARDOWN,
	RT_RTSP_CUSTOM
	
} RT_RTSP_CMD;

typedef enum {
	RT_STREAM_AUDIO,
	RT_STREAM_VIDEO,
	RT_STREAM_BOTHAV
	
} RT_STREAM_TYPE;

@interface RtspClient : NSObject {
	
	int    _rtsp_fd;
	char   _x_session[RT_SESSION_LENGTH];
	char   _username[RT_USR_PW_LENGTH];
	char   _password[RT_USR_PW_LENGTH];
	char   _host[256];
	RT_RTSP_CMD _rtsp_state;
	
	int    _port;
	
	unsigned char   _recv_buf[RT_RECV_BUFFER_SIZE];
	int    _recv_buf_len;
		
	int    _max_frame_rate;
	int    _audio_payload_type;
	int    _audio_codec;
	char   _audio_desc[RT_CONTROL_DESC_LENGTH];
	
	int    _video_payload_type;
	int    _frame_rate_calculation_param;
	int    _video_codec_type;
	char   _video_desc[RT_CONTROL_DESC_LENGTH];
	
	int    _sesstion_timeout;
	
	int    _interleaved;
	int    _interleaved_audio;
	
	int    _cseq;
	int    _recv_error;
	
	int	   _errCode;	
}



+ (void) InitXsession:(char*) cookie;

- (int) GetVideoInterleaved;
- (int) GetAudioInterleaved;
- (int) GetRecvError;
- (int) GetTimeBase;
- (void) SetPort:(int) port;
- (char*)GetAudioDesc;
- (void) SetAudioDesc:(char*)desc;

- (char*)GetVideoDesc;
- (void) SetVideoDesc:(char*)desc;

- (void) DumpInfo;

- (void) SetXsession:(char*) cookie;

- (BOOL) ConnectWithAddr:(char*) addr;

- (void) CloseConnect;

- (BOOL) RequestWithCmd:(RT_HTTP_CMD) cmd
			     Encode:(BOOL) encode
				   Data:(char*) src;

- (BOOL) ResponseWithHttpCmd:(RT_HTTP_CMD) http_cmd
					 RtspCmd:(RT_RTSP_CMD) rtsp_cmd
				  StreamType:(RT_STREAM_TYPE) strem_type;

- (void) SetUsername:(char*)usr
			Password:(char*)pw;

- (void) GenRtspCmd:(RT_RTSP_CMD) rtsp_cmd
			 CmdStr:(char*) cmd
             StreamType:(RT_STREAM_TYPE) strem_type
             Encode:(BOOL) encode;

- (void) SetMaxFrameRate:(int) val;
- (int)  GetMaxFrameRate;

- (void) FilterAudioCodec:(char*) audio_codec_dec;

- (unsigned char*) RecvData:(int) recv_timeout RecvLen:(int*)recv_len;

- (int) RetrieveErrCode;

@end
