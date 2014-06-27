//
//  RtpParser.m
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

#import "RtpParser.h"
#import "Md5.h"
#import "Base64.h"
#import <CFNetwork/CFNetwork.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h> 
#import <netdb.h>

static unsigned char* FindChar(unsigned char* d, char c,int len)
{
	int ck = 0;
	unsigned char *p = d;
	while (*p != c)
	{
		
		p++;
		if(++ck == len)
			break;
	}
	if(ck >= len)
		return NULL;
	return p;
	
}

@implementation RtpParser

- (unsigned int) GetPts
{
	return _pts;
}
- (id) init 
{
	
	if ((self = [super init]) == nil)
		return nil;
	
	
	memset(_buf_pool,0,RT_RECV_BUFFER_SIZE);
	_buf_pool_len = 0;
	
	_first_pkt = YES;
	_seq_video = 0;
	
	_p_nt   = NULL;
	_nt_len = 0;
	
	return self;
}



- (void) ParserRtpData:(unsigned char *)data
				Header:(struct RTPHeader *)rtp_header
{
	unsigned char* pp = data+4;
	
	
	rtp_header->ver = ( pp[0] & 0xc0) >> 6;
	rtp_header->p   = ((pp[0] & 0x20) >> 5) ? 1:0;
	rtp_header->x   = ((pp[0] & 0x10) >> 4) ? 1:0;
	rtp_header->cc  = ( pp[0] & 0x0f);
	
	rtp_header->m   = ((pp[1] & 0x80) >> 7) ? 1:0;
	rtp_header->pt  = ( pp[1] & 0x7f);
	
	rtp_header->seq = ntohs( *(( unsigned short*)(&pp[2])));
	rtp_header->ts  = ntohl( *(( unsigned long*)(&pp[4])));
	rtp_header->ssrc= ntohl( *(( unsigned long*)(&pp[8])));
	
}

- (BOOL) ParserPayload:(RtspClient*)  rtsp_cli
				Parser:(MjpegParser*) parser
{
	char head = '$';
	BOOL ret  = NO;
	
	if(!rtsp_cli)
		return NO;
	
	unsigned char *p  = NULL;
	int recv_buf_len = RT_RECV_BUFFER_SIZE;
	unsigned char *recv_buf;
	
	if(_nt_len < 0)
		_nt_len = 0;
	
	if(_p_nt == NULL)
		_p_nt = _buf_pool;
	
	if(_nt_len < RT_RECV_BUFFER_SIZE)
	{
		recv_buf_len = RT_RECV_BUFFER_SIZE;
		recv_buf = [rtsp_cli RecvData:5000 RecvLen:&recv_buf_len];
		
		if([rtsp_cli GetRecvError] >= RTP_MAX_ERROR)
			return NO;
		
		if(recv_buf == NULL)
			return NO;
		
		if(!(recv_buf_len > 0 && recv_buf_len <=RT_RECV_BUFFER_SIZE))
		{
			rterr("recv err----- recv_len = %d\n",recv_buf_len);
			memset(_buf_pool,0,RTP_PROCESS_BUFFER_MAX);
			_buf_pool_len = 0;
			_nt_len       = 0;
			_p_nt         = NULL;
			
			return NO;
		}
		
		if(_nt_len + recv_buf_len > RTP_PROCESS_BUFFER_MAX)
		{
			rterr("out of buffer-----nt_len = %d, recv_len = %d\n",_nt_len,recv_buf_len);
			memset(_buf_pool,0,RTP_PROCESS_BUFFER_MAX);
			_buf_pool_len = 0;
			_nt_len       = 0;
			_p_nt         = NULL;
			
			return NO;
		}
		
		if(_buf_pool_len + recv_buf_len > RTP_PROCESS_BUFFER_MAX)
		{
			memcpy(_buf_pool,_p_nt,_nt_len);
			_buf_pool_len = _nt_len;
			_p_nt = _buf_pool;
		}
		
		memcpy(_buf_pool+_buf_pool_len,recv_buf,recv_buf_len);
		_buf_pool_len += recv_buf_len;
		_nt_len += recv_buf_len;
	}
	
	p = FindChar(_p_nt, head,_nt_len);
	
	if(p == NULL)
	{
		memset(_buf_pool,0,RTP_PROCESS_BUFFER_MAX);
		_buf_pool_len = 0;
		_nt_len       = 0;
		_p_nt         = NULL;
		
		return NO;
	}
	
	if((p+4) >  (_buf_pool + _buf_pool_len))
	{
		rterr("need more buffer remain = %d\n",((_buf_pool + _buf_pool_len) - p));
		_p_nt = p;
		_nt_len = (_buf_pool + _buf_pool_len) - p;
		
		return NO;
	}
	
	
	int ch_val = (int) (*(p+1));
	rtdbg("ch_val = %d\n",ch_val);
	if((ch_val != _video_chanel) && (ch_val != _audio_chanel))
	{
		rterr("ch_val = %d -",ch_val);
		rterr("channel error\n");
		
		_p_nt   += 4;
		_nt_len -= 4;
		
		
		return NO;
	}
	
	unsigned short pkt_len = ntohs(*((unsigned short*)(p + 2)));
	
	if(pkt_len > 1518)
	{
		rterr("ch_val = %d -",ch_val);
		rterr("channel error -");
		rterr("pkt_len =%d error\n",pkt_len);

		memset(_buf_pool,0,RTP_PROCESS_BUFFER_MAX);
		_buf_pool_len = 0;
		_nt_len       = 0;
		_p_nt         = NULL;
		
		return NO;		
	}
	
	int p_mv = (p -_buf_pool);
	
	if(((_buf_pool_len - p_mv )-4) < pkt_len)
	{
		//rterr("pkt_len error((_buf_pool_len - p_mv )-4) =%d, pkt_len = %d\n",((_buf_pool_len - p_mv )-4),pkt_len);
		_p_nt = p;
		_nt_len = (_buf_pool_len - p_mv);
		
		return NO;
	}
	
	if(ch_val ==_video_chanel) // video;
	{
		
		struct RTPHeader rtp_header;
		
		[self ParserRtpData:p Header:&rtp_header];
		
		unsigned int payload_type = rtp_header.pt;
		unsigned int seq = rtp_header.seq;
		unsigned int ex_hdr = rtp_header.x;
		unsigned int crc_count = rtp_header.cc;
		unsigned int padding   = rtp_header.p;
		
		unsigned int mark = rtp_header.m;
		unsigned int pts  = rtp_header.ts;
		
		rtdbg("payload_type = %d, seq = %d\n", payload_type,seq );
		rtdbg("pakct_len = %d\n", pkt_len );
		rtdbg("ex_hdr = %d\n", ex_hdr );
		rtdbg("crc_count = %d\n", crc_count );
		rtdbg("padding = %d\n", padding );
		rtdbg("mark = %d\n", mark);
		
		rtdbg("frame seq = %d,seq_video = %d->\n",seq,(_seq_video));
		
		if(payload_type != 26) // video
		{
			rterr("ch_val = %d -",ch_val);
			rterr("channel error -");
			rterr("payload_type = %d error\n",payload_type);
			
			_p_nt   = p+4+pkt_len;
			_nt_len = _buf_pool_len - p_mv -(4+pkt_len);
					
			return NO;
		}
		
		unsigned char *data = p+4;
		
		int offset = sizeof(struct RTPHeader);
		
		offset += crc_count*sizeof(unsigned long);
		
		if(ex_hdr) 
		{
			
			struct RTPExtHeader *ex_hdr_ptr = (struct RTPExtHeader *) (data + offset);
			offset += sizeof(struct RTPExtHeader);
			offset += (ntohs(ex_hdr_ptr->exHeaderLen) * sizeof(unsigned long));
		}
		
		unsigned char *rtp_payload_data;
		unsigned int   rtp_payload_len;
		
		unsigned char* padd_data;

		
		if(padding)
		{
			int padd_len = data[pkt_len-1];
			
			if(offset + padd_len > pkt_len || padd_len > 255)
			{
				rterr("padding error\n");
				_p_nt   = p+4+pkt_len;
				_nt_len = _buf_pool_len - p_mv -(4+pkt_len);
				return NO;
			}
			
			rtp_payload_len = pkt_len - offset - padd_len;
			rtp_payload_data = data + offset;
			padd_data = data + offset + rtp_payload_len; 
			// got padding data if need?
			//....
		}
		else 
		{
			rtp_payload_data = data + offset;
			rtp_payload_len  = pkt_len - offset;
		}
		
		if(!_seq_err )
		{	
		
			[parser ParserHeader:rtp_payload_data Length:rtp_payload_len];
			if(_first_pkt)
			{
				[parser MakeHeader];
				_first_pkt = NO;
			}
		
			if(_seq_video == seq)
			{
				[parser AddData:rtp_payload_data  Length:rtp_payload_len];
			}
			else
			{
				rterr("Drop frame seq = %d,seq_video = %d->\n",seq,_seq_video);
				_seq_err   = YES;
				_seq_video = seq;

			}
		}
		else 
		{
			if(_seq_video != seq)
			{
				_seq_err   = YES;
				_seq_video = seq;
			}
		}

		_seq_video ++;
				
		if(mark == 1)
		{
			if(_seq_err == YES)
			{
				rterr("clean mjpeg data-------\n");
				[parser CleanData];
				ret = NO;
				_seq_err = NO;

			}
			else 
			{
				ret = YES;
				_pts = pts;
			}
			
			_first_pkt = YES;

			_p_nt   = p+4+pkt_len;
			_nt_len = _buf_pool_len - p_mv -(4+pkt_len);
			
			return ret;
			
		}
		
	}
	
	_p_nt   = p+4+pkt_len;
	_nt_len = _buf_pool_len - p_mv -(4+pkt_len);

	return NO;
	
}


/*
- (BOOL) ParserPayload2:(RtspClient*)  rtsp_cli
				Parser:(MjpegParser*) parser
{
	char head = '$';
	BOOL ret  = NO;
	
	if(!rtsp_cli)
		return NO;
	
	unsigned char *p  = NULL;
	int recv_buf_len = RT_RECV_BUFFER_SIZE;
	unsigned char *recv_buf;
	
	if(_buf_pool_len < RT_RECV_BUFFER_SIZE)
	{
		recv_buf_len = RT_RECV_BUFFER_SIZE;
		recv_buf = [rtsp_cli RecvData:5000 RecvLen:&recv_buf_len];
		if(_buf_pool_len+recv_buf_len > RTP_PROCESS_BUFFER_MAX)
			return NO;
		
		if([rtsp_cli GetRecvError] >= RTP_MAX_ERROR)
			return NO;
		if(recv_buf_len > 0 && recv_buf_len <=RT_RECV_BUFFER_SIZE)
		{
			memcpy(_buf_pool+_buf_pool_len,recv_buf,recv_buf_len);
			_buf_pool_len += recv_buf_len;
		}
		else 
			return NO;
		

	}
    
	p = FindChar(_buf_pool, head,_buf_pool_len);
	
	if(p == NULL)
	{
		//clear buf
		memset(_buf_pool,0,sizeof(_buf_pool));
		_buf_pool_len = 0;
		
		return NO;
	}
	
	while((p+4 > (_buf_pool + _buf_pool_len)))
	{
		recv_buf_len = RT_RECV_BUFFER_SIZE;
		recv_buf = [rtsp_cli RecvData:5000 RecvLen:&recv_buf_len];
		
		if(_buf_pool_len+recv_buf_len > RTP_PROCESS_BUFFER_MAX)
			return NO;
		
		if([rtsp_cli GetRecvError] >= RTP_MAX_ERROR)
			return NO;
		if(recv_buf_len > 0 && recv_buf_len <=RT_RECV_BUFFER_SIZE)
		{
			memcpy(_buf_pool+_buf_pool_len,recv_buf,recv_buf_len);
			_buf_pool_len += recv_buf_len;
		}
		else 
			return NO;
	}
	
	int ch_val = (int) (*(p+1));
	
	//rtdbg("ch_val = %d \n",ch_val);
	
	if((ch_val != _video_chanel) && (ch_val != _audio_chanel))
	{
		rterr("ch_val = %d -",ch_val);
		rterr("channel error\n");
		memcpy(_buf_pool,_buf_pool+2,_buf_pool_len-2);
		_buf_pool_len -= 2;
		
		return NO;
	}
	
	unsigned short pkt_len = ntohs(*((unsigned short*)(p + 2)));
	
	if(pkt_len > 1518)
	{
		rterr("ch_val = %d -",ch_val);
		rterr("channel error -");
		rterr("pkt_len =%d error\n",pkt_len);
		
		//clear buf
		memset(_buf_pool,0,sizeof(_buf_pool));
		_buf_pool_len = 0;
		
		//memcpy(_buf_pool,_buf_pool+4,_buf_pool_len-4);
		//_buf_pool_len -= 4;
		return NO;		
	}
	int p_mv = (p -_buf_pool);
	if(((_buf_pool_len - p_mv )-4) < pkt_len)
	{
		rterr("pkt_len error((_buf_pool_len - p_mv )-4) =%d, pkt_len = %d\n",((_buf_pool_len - p_mv )-4),pkt_len);
		memcpy(_buf_pool,p,(_buf_pool_len - p_mv));
		_buf_pool_len = (_buf_pool_len - p_mv);
		return NO;
	}
	
	if(ch_val ==_video_chanel) // video;
	{
		
		struct RTPHeader rtp_header;
		
		[self ParserRtpData:p Header:&rtp_header];
		
		unsigned int payload_type = rtp_header.pt;
		unsigned int seq = rtp_header.seq;
		unsigned int ex_hdr = rtp_header.x;
		unsigned int crc_count = rtp_header.cc;
		unsigned int padding   = rtp_header.p;
		
		unsigned int mark = rtp_header.m;
		
		rtdbg("payload_type = %d, seq = %d\n", payload_type,seq );
		rtdbg("pakct_len = %d\n", pkt_len );
		rtdbg("ex_hdr = %d\n", ex_hdr );
		rtdbg("crc_count = %d\n", crc_count );
		rtdbg("padding = %d\n", padding );
		rtdbg("mark = %d\n", mark);
		
		
		if(payload_type != 26) // video
		{
			rterr("ch_val = %d -",ch_val);
			rterr("channel error -");
			rterr("payload_type = %d error\n",payload_type);
			_buf_pool_len = _buf_pool_len - p_mv -(4+pkt_len);
			memcpy(_buf_pool,p+4+pkt_len,_buf_pool_len);	
			
			return NO;
		}
		
		
		unsigned char *pp = p+4;
		unsigned char *data = pp;
		
		int offset = sizeof(struct RTPHeader);
		
		offset += crc_count*sizeof(unsigned long);
		
		if(ex_hdr) 
		{
			
			struct RTPExtHeader *ex_hdr_ptr = (struct RTPExtHeader *) (data + offset);
			
			offset += sizeof(struct RTPExtHeader);
			offset += (ntohs(ex_hdr_ptr->exHeaderLen) * sizeof(unsigned long));
		}
		
		if(padding)
		{
			// process padding...
		}
		
		unsigned char *rtp_payload_data = data + offset;
		unsigned int   rtp_payload_len  = pkt_len - offset;
		
		
		if(!_seq_err )
		{	
		
			if(_first_pkt)
			{
				[parser ParserHeader:rtp_payload_data Length:rtp_payload_len];
				[parser MakeHeader];
			
				_first_pkt = NO;
			}
		
		
			if(_seq_video == seq)
			{
				[parser AddData:rtp_payload_data  Length:rtp_payload_len];
			}
			else
			{
				rterr("Drop frame seq = %d,seq_video = %d->\n",seq,_seq_video);
				_seq_err   = YES;
				_seq_video = seq;

			}
		}
		else 
		{
			if(_seq_video != seq)
			{
				_seq_err   = YES;
				_seq_video = seq;
			}
		}

		_seq_video ++;
		
				
		if(mark == 1)
		{
			if(_seq_err == YES)
			{
				rterr("clean mjpeg data-------\n");
				[parser CleanData];
				ret = NO;
				_seq_err = NO;

			}
			else {
				ret = YES;
			}

			
			_first_pkt = YES;
						
			
			_buf_pool_len = _buf_pool_len - p_mv -(4+pkt_len);
			memcpy(_buf_pool,p+4+pkt_len,_buf_pool_len);	
			
						
			if(ret)
				rtdbg("frame seq = %d,seq_video = %d->\n",seq,(_seq_video -1));
			
			return ret;
			
		}
		
	}
	
	
	
	_buf_pool_len = _buf_pool_len - p_mv -(4+pkt_len);
	memcpy(_buf_pool,p+4+pkt_len,_buf_pool_len);	
	
	return NO;
	
}
*/ 
 
- (void) SetChanelVideo:(int)video
				  Audio:(int)audio
{
	_video_chanel = video;
	_audio_chanel = audio;
}

@end
