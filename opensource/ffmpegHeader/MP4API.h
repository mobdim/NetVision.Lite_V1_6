/*
 ??????????
 */

#import "MP4Macros.h"
#import "libavcodec/avcodec.h"

#define VISUAL_SAMPLE_ENTRY_SIZE	163 // maximun of H264SampleEntry and Mpeg4SampleEntry

typedef struct FrameInfo {
	u32	count;
	u32	duration;
	u32	size;
	u16	frm;
} __attribute__((packed)) FrameInfo;

typedef struct  MDAT {
	u32	size;
	u8	type[4];
} __attribute__((packed)) MDAT;

typedef	struct MP4SampleSizeAtom {
	u32	size;
	u8      type[4];	//stsz	
	u8	version;
	u8	flag[3];
	u32	defaultsize;
	u32	entry_count;
} __attribute__((packed)) MP4SampleSizeAtom;


typedef	struct MP4SampleEntryAtom {
	u32	size;
	u8      type[4];	//stts,stco,stsc,stss	
	u8	version;
	u8	flag[3];
	u32	entry_count;
} __attribute__((packed)) MP4SampleEntryAtom;

typedef struct DecInfo {
	u32	tag;		// 05 80 80 80
	u8 	size;	
	u8 	decidx[28];
} __attribute__((packed)) DecInfo;

typedef struct	DecConfig {
	u32	tag;	 	// 04 80 80 80
	u8	size;
	u8 	objtypeid;
	u8	stream;
	u8	bufferSizeDB[3];
	u32	maxBitrate;
	u32	avgBitrate;
	struct  DecInfo decInfo;
} __attribute__((packed)) DecConfig;

typedef struct	SLConfig {
	u32	tag;	 	// 06 80 80 80
	u8	size;
	u8	predefined;	// 2
} __attribute__((packed)) SLConfig;

typedef struct ES_Desc {
	u32	tag;		// 03 80 80 80
	u8 	size;
	u16 	ESID;
	//	struct	StreamFlag	sf;
	u8	sf;
	struct 	DecConfig	dec;
	struct	SLConfig	sl;
} __attribute__((packed)) ES_Desc;

typedef struct ESDAtom {
	u32 	size;
	u8 	type[4];	//esds
	u8 	version;
	u8	flag[3];	// 0x00
	struct	ES_Desc	ESdesc;
} __attribute__((packed)) ESDAtom;

typedef struct Mpeg4SampleEntry {
	u32	size;
	u8	type[4];	//mp4v
	u8	reserved[6];
	u16 	data_ref;
	u32	reserved1[4];
	u32	reserved2;	//0x014000F0
	u32	reserved3;	//0x00480000
	u32	reserved4;	//0x00480000
	u32	reserved5;	//0
	u16	reserved6;	//1
	u8	name_len;
	u8	name[31];
	u16	reserved7;	//24
	s16	reserved8;	//-1
	struct ESDAtom	ES;
} __attribute__((packed)) Mpeg4SampleEntry;

typedef	struct MP4SampleDescAtom {
	u32	size;
	u8	type[4];	//stsd	
	u8 	version;
	u8	flag[3];	// 0x0001	
	u32 	entry_count;
	u8 VisualSampleEntry[VISUAL_SAMPLE_ENTRY_SIZE];	// Mpeg4SampleEntry or H264SampleEntry
} __attribute__((packed)) MP4SampleDescAtom;

typedef	struct MP4SampleTableAtom {
	u32	size;
	u8	type[4];  // stbl
	struct MP4SampleDescAtom  stsd;
} __attribute__((packed)) MP4SampleTableAtom;

typedef struct DataEntryUrlAtom {
	u32	size;
	u8	type[4];  // url(0x20)
	u8 	version;
	u8 	flag[3];  // 0x0001	
} __attribute__((packed)) DataEntryUrlAtom;

typedef struct MP4DataRefAtom {
	u32 	size;
	u8 	type[4];	// dref
	u8 	version;
	u8	flag[3];	// 0x0001	
	u32 	entry_count;
	struct  DataEntryUrlAtom url;
} __attribute__((packed)) MP4DataRefAtom;

typedef	struct MP4DataInfoAtom {
	u32     size;
	u8 	type[4];	// dinf
	struct MP4DataRefAtom	dref;
} __attribute__((packed)) MP4DataInfoAtom;


typedef	struct MP4VideoMediaHeaderAtom {
	u32     size;
	u8 	type[4];	// vmhd
	u8 	version;
	u8	flag[3];	// 0x0001	
	u32	reserve[2];
} __attribute__((packed)) MP4VideoMediaHeaderAtom;

typedef struct MP4MediaInfoAtom {
	u32     size;
	u8 	type[4];	// minf
	struct MP4VideoMediaHeaderAtom  vmhd;
	struct MP4DataInfoAtom		dinf;
	struct MP4SampleTableAtom	stbl;
} __attribute__((packed)) MP4MediaInfoAtom;

typedef struct MP4MediaHandlerAtom {
	u32     size;
	u8 	type[4];	// hdlr
	u8 	version;
	u8	flag[3];
	u32	reserved;
	u8	handler_type[4];
	u8 	reserved1[12];
	u8	name[6];	// camera ,terminate by null char
} __attribute__((packed)) MP4MediaHandlerAtom;

typedef struct MP4MediaHeaderAtom {
	u32     size;
	u8 	type[4];	// mdhd
	u8 	version;
	u8	flag[3];
	u32	creation_time;	
	u32	modification_time;
	u32	timescale;
	u32	duration;
	u16	lang;		// 1 bit pad = 0 ,15 bits = 0x15c7
	u16	reserved;
} __attribute__((packed)) MP4MediaHeaderAtom;

typedef struct MP4MediaAtom {
	u32     size;
	u8 	type[4];	// mdia
	struct MP4MediaHeaderAtom 	mdhd;
	struct MP4MediaHandlerAtom	hdlr;
	struct MP4MediaInfoAtom		minf;
} __attribute__((packed)) MP4MediaAtom;

typedef struct MP4TrackHeaderAtom {
	u32     size;
	u8 	type[4];	// tkhd
	u8 	version;
	u8	flag[3];
	u32	creation_time;	
	u32	modification_time;
	u32 	track_ID;
	u32 	reserved;
	u32	duration;
	u32 	reserved1[3];
	u16	reserved2;	// audio 0x0100 else 0
	u16 	reserved3;
	u32 	reserved4[9];
	u32	reserved5;	// visual 0x01400000 else 0 (width)
	u32	reserved6;	// visual 0x00f00000 else 0 (height)
} __attribute__((packed)) MP4TrackHeaderAtom;

typedef struct MP4TrackAtom {
	u32     size;
	u8 	type[4];	// trak
	struct MP4TrackHeaderAtom tkhd;
	struct MP4MediaAtom	mdia;
	// ??
} __attribute__((packed)) MP4TrackAtom;

typedef struct MP4MoovHeaderAtom {
	u32	size;
	u8	type[4];	// mvhd
	u8 	version;
	u8	flag[3];
	u32	creation_time;	
	u32	modification_time;
	u32 	timescale;
	u32	duration;
	u32	reserved;	// 0x00010000 -> 0x00000100
	u16	reserved1;	// 0x0100 -> 0x0001
	u16	reserved2;
	u32	reserved3[2];	
	u32	reserved4[9];
	u32 	reserved5[6];
	u32	next_track_ID;
} __attribute__((packed)) MP4MoovHeaderAtom;


typedef struct MP4MoovAtom {
	u32     size;
	u8 	type[4];	// moov
	struct  MP4MoovHeaderAtom  mvhd;
	struct  MP4TrackAtom  trak;
} __attribute__((packed)) MP4MoovAtom;

typedef struct MP4FileTypeAtom {
	u32	size;		// 0x00000020 -> 0x20000000
	u8	type[4];	// ftype
	u8	brand[4];	// mp42
	u32	minver;         // 0x00000000
	u8	compbrand[16];	
} __attribute__((packed)) MP4FileTypeAtom;


typedef struct MP4Atom {
	struct MP4FileTypeAtom  fbox;
	struct MP4MoovAtom	 moov;
} __attribute__((packed)) MP4Atom;

int OpenTempFile(const char *fname);
void CloseTempFile(int fd);
int WriteFrame2MDATFile(int fd, AVPacket *packet);
int WriteFrameInfo2File(int fd, FrameInfo info);
int CreateMP4File(int fd, int fd_info, int fd_mdat, int width, int height);