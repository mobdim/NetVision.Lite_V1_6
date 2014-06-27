//
//  MjpegParser.h
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
// for jpeg


#define MJPEG_HUFFMAN_TABLES_LEN_MAX 1280
#define MJPEG_HEADERS_LEN_MAX        MJPEG_HUFFMAN_TABLES_LEN_MAX+768
#define MJPEG_FRAME_BUFF_MAX         460800

struct JPEGHeadr {
	
	unsigned int tspec:8;
	unsigned int off:24;
	unsigned char type;
	unsigned char q;
	unsigned char width;
	unsigned char height;
	
};

struct JPEGQtableHeader {
	unsigned char mbz;
	unsigned char precision;
	unsigned short length;
};

struct JPEGHeaderRst {
	unsigned short dri;
	unsigned short f:1;
	unsigned short l:1;
	unsigned short count:14;
};


@interface MjpegParser : NSObject {
	
	// jpeg
	struct JPEGHeadr _jp_jpeq_hdr;
	unsigned short _jp_pre_dri;
	unsigned char  _jp_pre_q;
	
	unsigned char  _jp_luma_qt[128];
	unsigned char  _jp_chroma_qt[128];
	int            _jp_luma_len;
	int            _jp_chroma_len;
	
	unsigned char  _jp_frame_header[MJPEG_HEADERS_LEN_MAX];
	int            _w;
	int            _h;
	unsigned char  _jp_data[MJPEG_FRAME_BUFF_MAX];
	int            _jp_data_len;
	
	int  _offset_len;

}
- (void) MakeQTableWithWidth: (int) width
                      Height: (int) height
                      Header: (struct JPEGHeadr) jpeq_hdr;

- (unsigned int) MakeHeader;

- (BOOL) ParserHeader:(unsigned char*) data
			   Length:(int) len;

- (BOOL) AddData:(unsigned char*) data
			  Length:(int) len;

- (void) CleanData;

- (unsigned char *) GetData:(int*) ret_len;

- (int) ParserQtable:(unsigned char*) data 
             Dynamic:(BOOL) sign;

@end
