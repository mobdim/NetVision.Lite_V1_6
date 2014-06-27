//
//  RtspClient.m
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

#import "RtspClient.h"
#import "MjpegParser.h"
#import "Md5.h"
#import "Base64.h"
#import <CFNetwork/CFNetwork.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h> 
#import <netdb.h>
#import <fcntl.h>
#import "ConstantDef.h"

static char base64Table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static void Base64EncoderChar(unsigned char* dest, const unsigned char *src,int src_len) 
{
	
	int len = src_len;
	int index = 0;
	const unsigned char *data = src;
	unsigned char * output = malloc(len*2);
	memset(output,0,len*2);
	
	
	
	unsigned char *d = malloc(len+3);
	memset(d,0,len+3);
	memcpy(d,data,len);
	
	for(int i=0;i<len;i+=3) {
		const unsigned char *p = (d +i);
		output[index++] = base64Table[((*p) >> 2)];
		output[index++] = base64Table[(((*p)& 0x03) << 4) + ((*(p+1)) >> 4)];
		output[index++] = ((i + 1) < len)?base64Table[(((*(p+1)) & 0x0f) << 2) + ((*(p+2)) >> 6)] : '=';
	    output[index++] = ((i + 2) < len)?base64Table[((*(p+2)) & 0x3f)] : '=';
	}
	
	output[index] =0;
	
	memcpy(dest,output,(index+1));
	
	free(output);
	free(d);
	
}

@implementation RtspClient


- (id) init 
{
	
	if ((self = [super init]) == nil)
		return nil;
	
	[self SetUsername:nil Password:nil];
	
	memset(_recv_buf,0,RT_RECV_BUFFER_SIZE);
	_recv_buf_len = 0;
	
	_sesstion_timeout = 60;
	_cseq = 0;
	_interleaved = 0;
	_interleaved_audio = 2;
	
	_rtsp_fd = -1;
	
	_recv_error = 0;
	_port = 80;
	_errCode = 0;
	
	return self;
}

static int sess_rand = 0;
+ (void) InitXsession : (char*) cookie
{
	
	//sleep(1);
	time_t timer = time(NULL);
	char* time_str = asctime(localtime(&timer));
	time_str[0] = time_str[0] + sess_rand++;
	if(sess_rand > 255) sess_rand = 0;
	EncodeMD5Data((unsigned char*)time_str, strlen(time_str), cookie);
}

- (int) GetVideoInterleaved
{
	return _interleaved;
}
- (int) GetAudioInterleaved
{
	return _interleaved_audio;
}
- (int) GetTimeBase
{
	return _frame_rate_calculation_param;
}

- (char*)GetAudioDesc
{
	return _audio_desc;
}
- (void) SetAudioDesc:(char*)desc
{
	if(strlen(desc))
		strcpy(_audio_desc,desc);
}

- (char*)GetVideoDesc
{
	return _video_desc;
}
- (void) SetVideoDesc:(char*)desc 
{
	if(strlen(desc))
		strcpy(_video_desc,desc);
}


- (void) SetXsession:(char*) cookie 
{
	memset(_x_session,0,RT_SESSION_LENGTH);
	strncpy(_x_session,cookie,RT_SESSION_LENGTH-1);
}


- (void) SetUsername:(char*)usr
			Password:(char*)pw 
{
	memset(_username,0,RT_USR_PW_LENGTH);
	memset(_password,0,RT_USR_PW_LENGTH);
	if(!usr || !pw) 
		return;
	
	int usr_len = strlen(usr);
	int pw_len  = strlen(pw);
	int cp_len;
	
	cp_len = (usr_len > RT_USR_PW_LENGTH)? RT_USR_PW_LENGTH : usr_len;
	
	strncpy(_username,usr,cp_len);
	
	cp_len = (pw_len > RT_USR_PW_LENGTH)? RT_USR_PW_LENGTH : pw_len;
	
	strncpy(_password,pw,cp_len);
	
	rtmsg("username =%s\n",_username);
	rtmsg("password =%s\n",_password);
	
}

- (void) CloseConnect 
{
	if(_rtsp_fd >=0)
		close(_rtsp_fd);
	_rtsp_fd = -1;
	
	memset(_recv_buf,0,RT_RECV_BUFFER_SIZE);
	
	_sesstion_timeout = 60;
	_cseq = 0;
	_interleaved = 0;
	_interleaved_audio = 2;
	_recv_buf_len = 0;
}

- (BOOL) ConnectWithAddr:(char*) addr 
{
	
	struct sockaddr_in fd_addr;
	int  buf_size     = RT_BUFFER_SIZE;
	bool reused       = true;
	int  read_timeout = RT_TIMEOUT;
	int  set          = 1;
	
	char* ip_addr;
	
	struct linger lg;
	int conneted;
	
	struct hostent *host_entry = NULL;
	host_entry=gethostbyname(addr);
	
	if(host_entry)
		ip_addr = inet_ntoa (*(struct in_addr *)*host_entry->h_addr_list);
	else 
	{
		_errCode = DEVICE_STATUS_DEVICE_NOT_FOUND;
		return NO;
	}

	rtmsg("Nash--ip---------------%s\n",ip_addr);
	
	strcpy(_host,addr);
	
	memset(&fd_addr,0,sizeof(fd_addr));
	
	_rtsp_fd = socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
	
	rtmsg("socket fd = %d\n",_rtsp_fd);
	
	if(_rtsp_fd < 0) 
	{ 
		rterr("Create socket error!\n");
		_errCode = DEVICE_STATUS_SOCKET_FAILURE;
		return NO;
	}
	
	fd_addr.sin_family = AF_INET;
	fd_addr.sin_port   = htons(_port);
	fd_addr.sin_addr.s_addr = inet_addr(ip_addr);
	
	setsockopt(_rtsp_fd, SOL_SOCKET, SO_RCVBUF,    &buf_size,     sizeof(int));
	setsockopt(_rtsp_fd, SOL_SOCKET, SO_SNDBUF,    &buf_size,     sizeof(int));
	setsockopt(_rtsp_fd, SOL_SOCKET, SO_REUSEADDR, &reused,       sizeof(bool));
	setsockopt(_rtsp_fd, SOL_SOCKET, SO_RCVTIMEO,  &read_timeout, sizeof(int));
	setsockopt(_rtsp_fd, SOL_SOCKET, SO_LINGER,    &lg,           sizeof(struct linger));
	setsockopt(_rtsp_fd, SOL_SOCKET, SO_KEEPALIVE, (void *)&set,  sizeof(int));
	setsockopt(_rtsp_fd, SOL_SOCKET, SO_NOSIGPIPE, (void *)&set,  sizeof(int));
	
	conneted = connect(_rtsp_fd,(const struct sockaddr *)&fd_addr,sizeof(struct sockaddr_in));
	
	if(conneted != 0) 
	{
		_errCode = _rtsp_fd;
		rterr("connet socket = %d fail\n", _errCode);
		close(_rtsp_fd);
		
		return NO;
	}
	
	return YES;

}

- (BOOL) RequestWithCmd:(RT_HTTP_CMD) cmd
			     Encode:(BOOL) encode
				   Data:(char*) src 
{
	
	char auth_src[512];
	char auth_dest[512];

	memset(auth_src,0,512);
	memset(auth_dest,0,512);
	
	char req[RT_CMD_LENGTH];
	memset(req,0,RT_CMD_LENGTH);
	
	switch(cmd) 
	{
			
		case RT_HTTP_GET:
			
			sprintf(req,"GET %s HTTP/1.0\r\n",src);
			strcat(req,"User-Agent: Viewer\r\n");

			strcat(req,"x-sessioncookie: ");
			strcat(req,_x_session);
			
			strcat(req,"\r\n");
			strcat(req,"Accept: application/x-rtsp-tunnelled\r\n");
			
			strcat(req,RT_AUTH_PATTERN);
			strcpy(auth_src,_username);
			strcat(auth_src,":");
			
			if(_password[0] != 0)
				strcat(auth_src,_password);
			
			Base64EncoderChar((unsigned char*)auth_dest, (unsigned char*)auth_src, strlen(auth_src));
			strcat(req,auth_dest);
			
			strcat(req,"\r\n\r\n");
			
			break;
		case RT_HTTP_POST:
			
			if(!encode) 
			{
				sprintf(req,"POST %s HTTP/1.0\r\n",src);
				
				strcat(req,"User-Agent: Viewer\r\n");
				strcat(req,"x-sessioncookie: ");
				strcat(req,_x_session);
				strcat(req,"\r\n");
				strcat(req,"Accept: application/x-rtsp-tunnelled\r\n");
				
				strcat(req,RT_AUTH_PATTERN);
				strcpy(auth_src,_username);
				strcat(auth_src,":");
				
				if(_password[0] != 0)
					strcat(auth_src,_password);
				
				Base64EncoderChar((unsigned char*)auth_dest, (unsigned char*)auth_src, strlen(auth_src));
				strcat(req,auth_dest);
				
				strcat(req,"\r\n");
				strcat(req,"Content-Length: 32767");
				strcat(req,"\r\n");
				strcat(req,"Expires: Sun, 9, Jan 1972 00:00:00 GMT");
				strcat(req,"\r\n\r\n");
				
				
			}
			else 
			{
				strcat(req,RT_AUTH_PATTERN);
				strcpy(auth_src,_username);
				strcat(auth_src,":");
				
				if(_password[0] != 0)
					strcat(auth_src,_password);
				
				Base64EncoderChar((unsigned char*)auth_dest, (unsigned char*)auth_src, strlen(auth_src));
				strcat(req,auth_dest);
				
				strcat(src,req);
				strcat(src,"\r\n\r\n");
				memset(req,0,RT_CMD_LENGTH);
				
				Base64EncoderChar((unsigned char*)req, (unsigned char*)src, strlen(src));
				
			}

			
			break;
	}
	
	if(req[0] == 0) 
	{
		
		rterr("No request!\n");
		_errCode = DEVICE_STATUS_BAD_REQUEST;
		return NO;
	}
	
	rtmsg("\nsend\n====================================================================\n");
	rtmsg("%s",req);
	rtmsg("\n====================================================================\n");
	
	int len = send(_rtsp_fd,req,strlen(req),0); //use tcp
	
	if(len <= 0) 
	{
		
		rterr("send data with socket error!\n");
		_errCode = DEVICE_STATUS_SOCKET_FAILURE;
		return NO;
	}
	
	return YES;
	
}

- (void) SetMaxFrameRate:(int) val 
{
	
	if(val > 30 || val < 0)
		val = 30;
	
	_max_frame_rate = val;
}
- (int)  GetMaxFrameRate
{
	return _max_frame_rate;
}
- (BOOL) ResponseWithHttpCmd:(RT_HTTP_CMD) http_cmd
					 RtspCmd:(RT_RTSP_CMD) rtsp_cmd
				  StreamType:(RT_STREAM_TYPE) strem_type 
{
	
	char *pbuf = (char*)_recv_buf;
	
	int len = RT_RECV_BUFFER_SIZE;
	
	[self RecvData:5000 RecvLen:&len];
	
	//int len = recv(_rtsp_fd,pbuf,RT_RECV_BUFFER_SIZE,0); //use tcp
	
	if(len <= 0) 
	{
		rterr("recv data error!\n");
		_errCode = DEVICE_STATUS_SESSION_RX_DATA_CORRUPTION;
		return NO;
	}
	
	rtmsg("\nrecv\n====================================================================\n");
	rtmsg("%s",pbuf);
	rtmsg("\n====================================================================\n");
	
	char *ptmp;
	char num_str[9];
	char frame_rate_param[10];  frame_rate_param[0] = 0;
	char audio_codec_desc[128]; audio_codec_desc[0] = 0;
	char video_codec_desc[128]; video_codec_desc[0] = 0;
	
	int  n = 0;
	
	
	ptmp = strstr(pbuf,RT_HTTP_OK );
	if(!ptmp) 
	{
		ptmp = strstr(pbuf, RT_HTTP_UNAUTHORIZATION);
		if(ptmp)
			_errCode = DEVICE_STATUS_AUTHENTICATION_ERROR;
		else
		{
			ptmp = strstr(pbuf, RT_HTTP_DEVICE_BUSY);
			if(ptmp)
				_errCode = DEVICE_STATUS_SESSION_NOT_AVAILABLE;
			else
			{
				ptmp = strstr(pbuf, RT_HTTP_STREAM_TYPE_NOT_MATCHED);
				if(ptmp)
					_errCode = DEVICE_STATUS_SERVER_NO_SERVICE;
				else
					_errCode = DEVICE_STATUS_SESSION_FAILURE; 
			}
		}
		return NO;
	}

	if(RT_HTTP_GET == http_cmd && RT_RTSP_DESCRIBE == rtsp_cmd) 
	{
		ptmp = strstr(pbuf,"framerate:");
		if(ptmp) 
		{
			char *pstr;
			pstr = strstr(ptmp,"\r\n");
			if(pstr) 
			{
				memset(num_str,0,9);
				int n = pstr - ptmp - 10;
				if(n > 8)
					n = 8;
				
				strncpy(num_str, ptmp + 10, n);
				
				[self SetMaxFrameRate:atoi(num_str)];
			}
		}
		ptmp = strstr(pbuf,"m=audio");
		
		if(ptmp) 
		{
			char *pstr;
			pstr = strstr(ptmp, "RTP/AVP");
			ptmp = strstr(ptmp, "\r\n");
			if(pstr && ptmp) {
				memset(num_str, 0, 8);
				n = ptmp - pstr - 7;
				if(n>8)
					n = 8;
				strncpy(num_str, pstr + 7, n);
				_audio_payload_type = atoi(num_str);
				
				ptmp = strstr(ptmp, "a=control:trackID=");
				if(ptmp) 
				{ // audio description 
					char *pstr;
					pstr = strstr(ptmp, "\r\n");
					int n = pstr - ptmp - 10;
					if(n >= RT_CONTROL_DESC_LENGTH)
						n = RT_CONTROL_DESC_LENGTH-1;
					strncpy(_audio_desc, ptmp + 10, n);
					_audio_desc[n] = 0;
				}
				else
					_audio_desc[0] = 0;
			} // end if pstr && ptmp
		} // end if ptmp
		else
			_audio_payload_type = -1;
		
		ptmp = strstr(pbuf,"m=video");
		
		if(ptmp)
		{
			char *pstr;
			pstr = strstr(ptmp, "RTP/AVP");
			ptmp = strstr(ptmp, "\r\n");
			if(ptmp && pstr) {
				memset(num_str, 0, 8);
				n = ptmp - pstr - 7;
				if(n>8)
					n = 8;
				strncpy(num_str, pstr + 7, n);
				_video_payload_type = atoi(num_str);
				
				// get frame rate calculation parameter
				ptmp = strstr(ptmp, "a=rtpmap");
				if(ptmp)
				{
					char *pstr, *pstrE;
					pstr = strstr(ptmp, "/");
					if(pstr)
					{
						pstr++;
						pstrE = strstr(ptmp, "\r\n");
						int n = pstrE - pstr;
						strncpy(frame_rate_param, pstr, n);
						frame_rate_param[n] = 0;
						_frame_rate_calculation_param = atoi(frame_rate_param);
					}
				}
				
				ptmp = strstr(ptmp, "a=control:trackID=");
				if(ptmp)	// video description
				{
					char *pstr;
					pstr = strstr(ptmp, "\r\n");
					int n = pstr - ptmp - 10;
					if(n>=RT_CONTROL_DESC_LENGTH)
						n = RT_CONTROL_DESC_LENGTH-1;
					strncpy(_video_desc, ptmp + 10, n);
					_video_desc[n] = 0;
				}
				else
					_video_desc[0] = 0;
			}
		}
		else
			_video_payload_type = -1;
		
		// if the audio/video strea control ID description not get yet, remember to get it 
		if(_video_desc[0] == 0)
		{
			ptmp = strstr(pbuf, "a=control:videoID=");
			if(ptmp)	// video description
			{
				char *pstr;
				pstr = strstr(ptmp, "\r\n");
				n = pstr - ptmp - 10;
				if(n>=RT_CONTROL_DESC_LENGTH)
					n = RT_CONTROL_DESC_LENGTH-1;
				strncpy(_video_desc, ptmp + 10, n);
				_video_desc[n] = 0;
			}
			else
				_video_desc[0] = 0;
		}
		if(_audio_desc[0] == 0)
		{
			ptmp = strstr(pbuf, "a=control:audioID=");
			if(ptmp)	// audio description
			{
				char *pstr;
				pstr = strstr(ptmp, "\r\n");
				n = pstr - ptmp - 10;
				if(n>=RT_CONTROL_DESC_LENGTH)
					n = RT_CONTROL_DESC_LENGTH-1;
				strncpy(_audio_desc, ptmp + 10, n);
				_audio_desc[n] = 0;
			}
			else
				_audio_desc[0] = 0;
		}
		
		// remember the audio codec
		ptmp = strstr(pbuf, "m=audio");
		if(ptmp)
		{
			char *pstr;
			ptmp = strstr(ptmp, "a=rtpmap:");
			if(ptmp)
			{
				pstr = strstr(ptmp, "\r\n");
				n = pstr - ptmp;
				if(n>=128)
					n=127;
				
				strncpy(audio_codec_desc, ptmp, n);
				audio_codec_desc[n] = 0;
				[self FilterAudioCodec: audio_codec_desc];
			}
		}
		else
			audio_codec_desc[0] = 0;
		
		// remember the video codec
		ptmp = strstr(pbuf, "m=video");
		if(ptmp)
		{
			char *pstr;
			ptmp = strstr(ptmp, "a=rtpmap:");
			if(ptmp)
			{
				pstr = strstr(ptmp, "\r\n");
				int n = pstr - ptmp;
				if(n>=128)
					n=127;
				strncpy(video_codec_desc, ptmp, n);
				video_codec_desc[n] = 0;
				
				if(strstr(video_codec_desc,RT_RTSP_DESCRIBE_CODEC_INFO_MJPEG) && 
				   _video_payload_type == RT_RTP_PAYLOAD_MJPEG)
					_video_codec_type = RT_RTP_CODEC_MJPEG; // only support MJPEG
				else
					_video_codec_type = RT_RTP_CODEC_MJPEG; 	// default
				
			}
		}
		else
			_video_codec_type = RT_RTP_CODEC_MJPEG; 	// default
		
	}// end if RT_HTTP_GET && RT_RTSP_DESCRIBE
	
	if(RT_HTTP_GET == http_cmd && RT_RTSP_SETUP == rtsp_cmd) 
	{
		char* pstr;
		memset(num_str, 0, 8);
		pstr = (strstr(pbuf, "interleaved="));
		if(!pstr)
		{
			_errCode = DEVICE_STATUS_DEVICE_RESPONSE_ERROR;
			goto Error_CHTTPClient_Response;
		}
		ptmp = strstr(pstr, "-");
		if(!ptmp)
		{
			_errCode = DEVICE_STATUS_DEVICE_RESPONSE_ERROR;
			goto Error_CHTTPClient_Response;
		}
		
		n = ptmp - pstr - 12;
		if(n>8)
			n = 8;
		strncpy(num_str, pstr + 12, n);
		
		if(strem_type == RT_STREAM_VIDEO)
		{
			_interleaved = atoi(num_str);
			rtmsg("Server assigned video chanel id = %d\n",_interleaved);
		}
		else
		{
			_interleaved_audio = atoi(num_str);
			rtmsg("Server assigned audio chanel id = %d\n",_interleaved_audio);
		}
		// find the timeout value if there is any
		memset(num_str, 0, 8);
		pstr = (char*)(strstr(pbuf, "timeout="));
		if(pstr)
		{
			ptmp = strstr(pstr, "\r\n");
			if(ptmp)
			{
				n = ptmp - pstr - 8;
				if(n>8)
					n = 8;
				strncpy(num_str, pstr + 8, n);
				_sesstion_timeout = (atoi(num_str));
			}
		}
		
	}// end if RT_HTTP_GET && RT_RTSP_SETUP 
	
	return YES;
	
Error_CHTTPClient_Response:
	
	return NO;
}

- (void) GenRtspCmd:(RT_RTSP_CMD) rtsp_cmd
			 CmdStr:(char*) cmd
		 StreamType:(RT_STREAM_TYPE) strem_type
             Encode:(BOOL) encode 
{
	
	if(!cmd) 
		return;
	memset(cmd,0,RT_CMD_LENGTH);
	
	_rtsp_state = rtsp_cmd;
	
	switch(rtsp_cmd) 
	{
		case RT_RTSP_OPTIONS:
			strcpy(cmd,"OPTIONS ");
			break;
		case RT_RTSP_DESCRIBE:
			strcpy(cmd,"DESCRIBE ");
			break;
		case RT_RTSP_PAUSE:
			strcpy(cmd,"PAUSE ");
			break;
		case RT_RTSP_PLAY:
			strcpy(cmd,"PLAY ");
			break;
		case RT_RTSP_SETUP:
			strcpy(cmd,"SETUP ");
			break;
		case RT_RTSP_TEARDOWN:
			strcpy(cmd,"TEARDOWN ");
			break;
		default:
			_rtsp_state = RT_RTSP_CUSTOM;
			break;
	}
	
	strcat(cmd,"rtsp://");
	strcat(cmd,_host);
	strcat(cmd,RT_REQ_FILE);
	
	if(rtsp_cmd == RT_RTSP_SETUP) 
	{
		if(strem_type == RT_STREAM_VIDEO) 
		{
			if(_video_desc[0] != 0) 
			{
				strcat(cmd, "/");
				strcat(cmd, _video_desc);
			}
		}
		else if(strem_type == RT_STREAM_AUDIO)
		{
			if(_audio_desc[0] != 0)
			{
				strcat(cmd, "/");
				strcat(cmd, _audio_desc);
			}
		}
	}
	
	strcat(cmd, " RTSP/1.0\r\n");
	
	char	tmp[128];
	memset(tmp, 0, 128);
	sprintf(tmp, "CSeq: %d\r\n", ++_cseq);
	strcat(cmd, tmp);
	
	switch(rtsp_cmd) 
	{
		case RT_RTSP_SETUP:
			strcat(cmd, "Transport: RTP/AVP/TCP;");
			strcat(cmd, "unicast;"); //default 
			
			if(strem_type == RT_STREAM_VIDEO)
				sprintf(tmp, "interleaved=%d-%d\r\n", _interleaved, _interleaved + 1);
			else
				sprintf(tmp, "interleaved=%d-%d\r\n", _interleaved_audio, _interleaved_audio + 1);
			
			strcat(cmd, tmp);
			break;
		case RT_RTSP_PLAY:
			strcat(cmd, "Range: npt=0.0-\r\n");
			sprintf(tmp, "Session: -1\r\n");
			strcat(cmd, tmp);
			break;
		
			
		case RT_RTSP_PAUSE:
		case RT_RTSP_TEARDOWN:	
			sprintf(tmp, "Session: -1\r\n");
			strcat(cmd, tmp);
			break;
			
		default:
			break;
	}
	
	switch(rtsp_cmd) 
	{
		
		case RT_RTSP_DESCRIBE:
			strcat(cmd,"Accept: application/sdp\r\n");
			break;
		default:
			strcat(cmd,"User-Agent: Viewer RTSP 1.0\r\n");
			break;
	}
	
	
	if(encode) 
	{
		
		char auth_src[512];
		char auth_dest[512];
		
		memset(auth_src,0,512);
		memset(auth_dest,0,512);
		
		strcat(cmd,RT_AUTH_PATTERN);
		strcpy(auth_src,_username);
		strcat(auth_src,":");
		
		if(_password[0] != 0)
			strcat(auth_src,_password);
		
		Base64EncoderChar((unsigned char*)auth_dest, (unsigned char*)auth_src, strlen(auth_src));
		strcat(cmd,auth_dest);
		strcat(cmd,"\r\n\r\n");
		
	}
	
}

- (void) FilterAudioCodec:(char*) audio_codec_dec
{
	if(strstr(audio_codec_dec,"G726-16"))
		_audio_codec = RT_G726_16;
	else if(strstr(audio_codec_dec,"G726-24"))
		_audio_codec = RT_G726_24;
	else if(strstr(audio_codec_dec,"G726-32"))
		_audio_codec = RT_G726_32;
	else if(strstr(audio_codec_dec,"G726-40"))
		_audio_codec = RT_G726_40;
	else if(strstr(audio_codec_dec,"PCMU"))
		_audio_codec = RT_G726_U;
	else if(strstr(audio_codec_dec,"PCMA"))
		_audio_codec = RT_G726_A;
	else if(strstr(audio_codec_dec,"L16/8000"))
		_audio_codec = RT_LPCM;
	else
		_audio_codec = RT_G726_U;
		
}

- (unsigned char*) RecvData:(int) recv_timeout RecvLen:(int*)recv_len
{
    //printf("XX recv --start--\n");
	_recv_buf_len = 0;
	if(_rtsp_fd <0)
	{
		_recv_error = 1000;
		return NULL;
	}
	int size = *recv_len;
	*recv_len  = 0;
	
	int recv_time = recv_timeout /100;
	int ret =0;
	//int recv_time_remaind = recv_timeout % 1000;
	fcntl(_rtsp_fd,F_SETFL,fcntl(_rtsp_fd, F_GETFL) | O_NONBLOCK);
	
	while (recv_time -- && ![[NSThread currentThread] isCancelled])
	{
	
		fd_set fds;
		struct timeval tout;
		
		
		tout.tv_sec  = 0;
		tout.tv_usec = 100 * 1000;
	
		FD_ZERO(&fds);
		FD_SET(_rtsp_fd,&fds);

		//printf("XX recv --start--select--\n");
	
		ret = select(_rtsp_fd+1,&fds,NULL,NULL,&tout);
	
	
		if(ret <= 0) 
			continue;
		
	}
	
	if([[NSThread currentThread] isCancelled])
	{
		fcntl(_rtsp_fd,F_SETFL,fcntl(_rtsp_fd, F_GETFL) & ~O_NONBLOCK);
		printf("Recv data thread cancel\n");
		_recv_error ++;
		return NULL;
	}
	if(ret <= 0) 
	{
		fcntl(_rtsp_fd,F_SETFL,fcntl(_rtsp_fd, F_GETFL) & ~O_NONBLOCK);
		printf("Recv data socket error with select function\n");
		_recv_error ++;
		return NULL;
	}
	else if(ret == 0) 
	{
		fcntl(_rtsp_fd,F_SETFL,fcntl(_rtsp_fd, F_GETFL) & ~O_NONBLOCK);
		printf("Recv data time out with select function\n");
		_recv_error ++;
		return NULL;
	}
	
	int recv_size = (size > 0 && size < RT_RECV_BUFFER_SIZE)? size:RT_RECV_BUFFER_SIZE;
	
	
	char *pbuf = (char*)_recv_buf;
	
	memset(pbuf,0,RT_RECV_BUFFER_SIZE);
	
	//printf("XX recv --start--recv--\n");
	int len = recv(_rtsp_fd,pbuf,recv_size,0); //use tcp
	
	fcntl(_rtsp_fd,F_SETFL,fcntl(_rtsp_fd, F_GETFL) & ~O_NONBLOCK);
	
	
	if(len ==0) 
	{
		_recv_buf_len = *recv_len = 0;
		_recv_error ++;
		rterr("Recv data socket NO data\n");
		return NULL;
	}
	
	if(len <0) 
	{
		_recv_buf_len = *recv_len = 0;
		_recv_error ++;
		rterr("Recv data socket error!\n");
		return NULL;
	}
	_recv_buf_len = *recv_len = len;
	
	return _recv_buf;

	
}

- (int) GetRecvError
{
	return _recv_error;
}

- (void) SetPort:(int) port
{
	_port = port;
	
}

- (int) RetrieveErrCode
{
	
	return _errCode;
}

- (void) DumpInfo 
{
	
	rtmsg("\n+++++++++++++++++++++++++++++++++++++++++++++\n");
	rtmsg("socket   = %d\n",_rtsp_fd);
	rtmsg("xsession = %s\n",_x_session);
	rtmsg("username = %s\n",_username);
	rtmsg("password = %s\n",_password);
	rtmsg("host     = %s\n\n",_host);
	rtmsg("max_frame_rate     = %d\n",_max_frame_rate);
	rtmsg("audio_payload_type = %d\n",_audio_payload_type);
	rtmsg("audio_desc         = %s\n",_audio_desc);
	rtmsg("audio_codec        = %d\n\n",_audio_codec);
	
	rtmsg("video_payload_type           = %d\n",_video_payload_type);
	rtmsg("frame_rate_calculation_param = %d\n",_frame_rate_calculation_param);
	rtmsg("video_codec_type             = %d\n",_video_codec_type);
	rtmsg("video_desc                   = %s\n",_video_desc);
	
	rtmsg("sesstion_timeout         = %d\n",_sesstion_timeout);
	rtmsg("interleaved              = %d\n",_interleaved);
	rtmsg("interleaved_audio        = %d\n",_interleaved_audio);
	rtmsg("\n+++++++++++++++++++++++++++++++++++++++++++++\n");
	 
}

@end
