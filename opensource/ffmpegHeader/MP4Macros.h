/*
 ??????????
 */

#ifndef _MP4Macro_
#define _MP4Macro_

#define H264_PROFILE_INDICATION	0x4D
#define H264_PROFILE_COMPATIBILITY 0x40
#define H264_LEVEL_INDICATION	0x1F
#define MP4_SPS_LEN_MAX 36
#define MP4_PPS_LEN_MAX 22


#define FRAMES_PER_TRUNK 10

//#define  MAX_FRAME_NUM	200
#define	 DTIME		(1970-1904)*365*24*3600
#define SWAP16(val) \
	((u16)( \
		(((u16)(val) & (u16)0x00ffU) << 8) | \
		(((u16)(val) & (u16)0xff00U) >> 8) ))
	
/* Byte swap a 32 bit value */
#define SWAP32(val) \
	((u32)( \
		(((u32)(val) & (u32)0x000000ffUL) << 24) | \
		(((u32)(val) & (u32)0x0000ff00UL) <<  8) | \
		(((u32)(val) & (u32)0x00ff0000UL) >>  8) | \
		(((u32)(val) & (u32)0xff000000UL) >> 24) ))

typedef unsigned int   u32;  // 4 bytes 
typedef unsigned short u16;  // 2 bytes
typedef unsigned char   u8;  // 1 bytes
typedef int     s32;
typedef short   s16;
typedef char     s8;
#endif
