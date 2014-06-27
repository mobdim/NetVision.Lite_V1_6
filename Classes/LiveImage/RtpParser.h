//
//  RtpParser.h
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
#import "RtspClient.h"
#import "MjpegParser.h"

#define RTP_PROCESS_BUFFER_MAX 2048*3
#define RTP_MAX_ERROR          1

struct RTPHeader {
	
	unsigned char ver :2;
	unsigned char p   :1;
	unsigned char x   :1;
	unsigned char cc  :4;
	
	unsigned char m   :1;
	unsigned char pt  :7;
	
	unsigned short seq;
	unsigned long  ts;
	unsigned long  ssrc;
	
};

struct RTPExtHeader {
	unsigned short profile_def;
	unsigned short exHeaderLen;
	
};

@interface RtpParser : NSObject {
	
	unsigned char   _buf_pool[RTP_PROCESS_BUFFER_MAX];
	int    _buf_pool_len;
	
	int    _video_chanel;
	int    _audio_chanel;
	int    _first_pkt;
	int    _seq_video;
	BOOL   _seq_err;
	
	unsigned char* _p_nt;
	int _nt_len;
	unsigned int _pts;
}
- (void) ParserRtpData:(unsigned char *)data
				Header:(struct RTPHeader *)rtp_header;

- (BOOL) ParserPayload:(RtspClient*)  rtsp_cli
				Parser:(MjpegParser*) parser;
						

- (void) SetChanelVideo:(int)video
				  Audio:(int)audio;

- (unsigned int) GetPts;

@end
