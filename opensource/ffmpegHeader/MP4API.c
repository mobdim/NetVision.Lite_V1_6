/*
 ??????????
 */

#import <stdio.h>
#import <fcntl.h>
#import <unistd.h>
#include <time.h>
#include <sys/socket.h>
#include <arpa/inet.h>



#import "MP4API.h"
/*
Note: Only support MPEG-4 now
 */

/*
 Write a frame to mdat temp file
 */
int WriteFrame2MDATFile(int fd, AVPacket *packet)
{
	// Write Frame 	
	if (-1 == write(fd, packet->data, packet->size))
	{
		return -1;
	}

	return 0;
}

/*
 Write frame info to temp info file
 */
int WriteFrameInfo2File(int fd, FrameInfo info)
{
	return write(fd, &info, sizeof(FrameInfo));
}

/*
 Open temp file
 */
int OpenTempFile(const char *fname)
{
	if (fname == NULL)
	{
		return -1;
	}
	
	unlink(fname); 
    return open(fname, O_CREAT|O_RDWR, 0666);
}

/*
 Close temp file
 */
void CloseTempFile(int fd)
{
	if (fd >= 0)
		close(fd);
}

u32 SampleEntrySize(int fd_info)
{
	u32 size;
	u32 chunk,i,stts_count=0;
	FrameInfo info, info1;
	u32 duration = 0;
	
	lseek(fd_info, 0, SEEK_SET);
	read(fd_info, &info, sizeof(FrameInfo));
	
	if((info.count % FRAMES_PER_TRUNK) == 0)
		chunk = info.count / FRAMES_PER_TRUNK;
	else
		chunk = (info.count / FRAMES_PER_TRUNK) + 1;
	
	for( i = 1; i <= info.count; i++)  
	{
		read(fd_info, &info1, sizeof(FrameInfo));
		if( info1.duration != duration ) 
			stts_count++;
		duration = info1.duration;
	}
	
	// stsz + stco+ stts + stsc + stss
	size = ((sizeof(MP4SampleEntryAtom)*4)+sizeof(MP4SampleSizeAtom)+(info.count*4)+(chunk*4)+(stts_count*8)+(chunk*12))+(info.frm*4); //four byte for sample size 
	
	return size;
}

static unsigned char m4v_vos_header[] = {
0x00, 0x00, 0x01, 0xB0, //      visual-objuect-sequence sc
0x01,                   //      simple profile, level 1
0x00, 0x00, 0x01, 0xB5, //      visual-object sc
0x09,
0x00,0x00,0x01,0x00,0x00,0x00,0x01,
0x20,0x00,0x84,0x5D,
0x4C,0x28,0x50,0x20,
0xF0,0xA3,0x1F
};

int FillMpeg4SampleEntry(Mpeg4SampleEntry *mp4v, int fd_info, int width, int height)
{
	int i = 0;
	int maxbitrate = 0;
	FrameInfo info,info1;
	
	lseek(fd_info, 0, SEEK_SET);
	read(fd_info, &info, sizeof(FrameInfo));
	// mp4v
	mp4v->size = SWAP32(sizeof(Mpeg4SampleEntry));
	strncpy((char *)mp4v->type,"mp4v",4);
	mp4v->data_ref = SWAP16(0x0001);

	mp4v->reserved2 = SWAP32(width<<16|height);
	
	mp4v->reserved3 = SWAP32(0x00480000);
	mp4v->reserved4 = SWAP32(0x00480000);
	mp4v->reserved6 = SWAP16(0x0001);
	//mp4v->name_len 
	//mp4v->name 
	mp4v->reserved7 = SWAP16(0x0018);
	mp4v->reserved8 = SWAP16(0xFFFF);
	// ES
	mp4v->ES.size = SWAP32(sizeof(ESDAtom));
	strncpy((char *)mp4v->ES.type,"esds",4);
	// ESdesc
	mp4v->ES.ESdesc.tag = SWAP32(0x03808080);
	mp4v->ES.ESdesc.size =(sizeof(ES_Desc) - 5);
	//mp4v->ES.ESdesc.ESID 
	
	mp4v->ES.ESdesc.sf =0x1f; 

	// SLConfig
	mp4v->ES.ESdesc.sl.tag = SWAP32(0x06808080); 
	mp4v->ES.ESdesc.sl.size = 0x01;
	mp4v->ES.ESdesc.sl.predefined = 0x02;
	
	// DecodeConfig
	mp4v->ES.ESdesc.dec.tag = SWAP32(0x04808080); 
	mp4v->ES.ESdesc.dec.size = (sizeof(DecConfig) - 5); 
	mp4v->ES.ESdesc.dec.objtypeid = 0x20; 
	mp4v->ES.ESdesc.dec.stream = 0x11;
	mp4v->ES.ESdesc.dec.bufferSizeDB[0] = 0x00;
	mp4v->ES.ESdesc.dec.bufferSizeDB[1] = 0x50;
	mp4v->ES.ESdesc.dec.bufferSizeDB[2] = 0x00;
	for(i = 1 ; i <= info.count ; i++)
	{
		read(fd_info, &info1, sizeof(FrameInfo));
		if (info1.duration <= 0)
		{
			fprintf(stderr, "frmInfo[%d].duration = %x\n",i,info1.duration);
			continue;
		}
		if (((info1.size / info1.duration)* 1000 * 8) > maxbitrate)
		{
			maxbitrate = ((info1.size / info1.duration)* 1000 * 8);
		}
	}
	mp4v->ES.ESdesc.dec.maxBitrate = SWAP32(maxbitrate);
	mp4v->ES.ESdesc.dec.avgBitrate = SWAP32((info.size*8*1000)/info.duration);
	
	// DecodeInfo
	mp4v->ES.ESdesc.dec.decInfo.tag = SWAP32(0x05808080);
	mp4v->ES.ESdesc.dec.decInfo.size =(sizeof(DecInfo) -5);

	memcpy(&mp4v->ES.ESdesc.dec.decInfo.decidx[0], m4v_vos_header, 28);
		
	return 0;
}

int GetMP4FileHeader(int fd_info, MP4Atom *mp4c, int width, int height)
{
	time_t now;
	u32 size = 0;
	FrameInfo info;
	
	time(&now);
	
	lseek(fd_info, 0, SEEK_SET);
	read(fd_info, &info, sizeof(FrameInfo));

	size = SampleEntrySize(fd_info);
	
	/* ftype */
	memset(mp4c,0,sizeof(MP4Atom));
	mp4c->fbox.size = SWAP32(0x00000020); // 0x00000020
	strncpy((char *)mp4c->fbox.type,"ftyp",4);
	strncpy((char *)mp4c->fbox.brand,"isom",4);
	mp4c->fbox.minver = SWAP32(0x00000000);
	strncpy((char *)mp4c->fbox.compbrand,"mp41isom",8);
	
	/* moov */
	//mp4c->moov.size = SWAP32(sizeof(MP4MoovAtom));//??
	strncpy((char *)mp4c->moov.type,"moov",4);
	/* mvhd */
	mp4c->moov.mvhd.size = SWAP32(sizeof(MP4MoovHeaderAtom));
	strncpy((char *)mp4c->moov.mvhd.type,"mvhd",4);
	//mp4c->moov.mvhd.version  0x00;
	//mp4c->moov.mvhd.flag   0x000000
	mp4c->moov.mvhd.creation_time = SWAP32(now+DTIME);
	mp4c->moov.mvhd.modification_time = SWAP32(now+DTIME);
	mp4c->moov.mvhd.timescale = SWAP32(0x000003E8);
	mp4c->moov.mvhd.duration = SWAP32(info.duration);
	mp4c->moov.mvhd.reserved = SWAP32(0x00010000);
	mp4c->moov.mvhd.reserved1 = SWAP16(0x0100);
	//mp4c->moov.mvhd.reserved2  0x0
	//mp4c->moov.mvhd.reserved3  0x0
	mp4c->moov.mvhd.reserved4[0] = SWAP32(0x00010000); // 0x00010000
	mp4c->moov.mvhd.reserved4[4] = SWAP32(0x00010000); // 0x00010000
	mp4c->moov.mvhd.reserved4[8] = SWAP32(0x40000000); // 0x40000000
	//mp4c->moov.mvhd.reserved5  0x0
	mp4c->moov.mvhd.next_track_ID = SWAP32(0x00000002);
	
	
	/* trak */
	//mp4c->moov.trak.size = SWAP32(sizeof(MP4TrackAtom));
	strncpy((char *)mp4c->moov.trak.type,"trak",4);
	/* tkhd */
	mp4c->moov.trak.tkhd.size = SWAP32(sizeof(MP4TrackHeaderAtom));
	strncpy((char *)mp4c->moov.trak.tkhd.type,"tkhd",4);
	//mp4c->moov.trak.tkhd.version
	mp4c->moov.trak.tkhd.flag[2] = 0x01; // 0x000001
	mp4c->moov.trak.tkhd.creation_time = SWAP32(now+DTIME);
	mp4c->moov.trak.tkhd.modification_time = SWAP32(now+DTIME);
	mp4c->moov.trak.tkhd.track_ID = SWAP32(0x00000001);
	//mp4c->moov.trak.tkhd.reserved
	mp4c->moov.trak.tkhd.duration = SWAP32(info.duration);
	//mp4c->moov.trak.tkhd.reserved1
	//mp4c->moov.trak.tkhd.reserved2
	//mp4c->moov.trak.tkhd.reserved3
	mp4c->moov.trak.tkhd.reserved4[0]= SWAP32(0x00010000);
	mp4c->moov.trak.tkhd.reserved4[4]= SWAP32(0x00010000);
	mp4c->moov.trak.tkhd.reserved4[8]= SWAP32(0x40000000);
	mp4c->moov.trak.tkhd.reserved5= SWAP32(width<<16);  //width 
	mp4c->moov.trak.tkhd.reserved6= SWAP32(height<<16);  //height
		
	/* mdia */
	//mp4c->moov.trak.mdia.size = SWAP32(sizeof(MP4MediaAtom));
	strncpy((char *)mp4c->moov.trak.mdia.type,"mdia",4);
	/* mdhd */
	mp4c->moov.trak.mdia.mdhd.size = SWAP32(sizeof(MP4MediaHeaderAtom));
	strncpy((char *)mp4c->moov.trak.mdia.mdhd.type,"mdhd",4);
	//mp4c->moov.trak.mdia.mdhd.version
	//mp4c->moov.trak.mdia.mdhd.flag
	mp4c->moov.trak.mdia.mdhd.creation_time = SWAP32(now+DTIME);
	mp4c->moov.trak.mdia.mdhd.modification_time = SWAP32(now+DTIME);
	mp4c->moov.trak.mdia.mdhd.timescale = SWAP32(0x000003E8);
	mp4c->moov.trak.mdia.mdhd.duration = SWAP32(info.duration);
	mp4c->moov.trak.mdia.mdhd.lang = SWAP16(0x15c7);
	mp4c->moov.trak.mdia.mdhd.reserved = 0x0;
	
	/* hdlr */
	mp4c->moov.trak.mdia.hdlr.size = SWAP32(sizeof(MP4MediaHandlerAtom));
	strncpy((char *)mp4c->moov.trak.mdia.hdlr.type,"hdlr",4); 
	//mp4c->moov.trak.mdia.version 
	//mp4c->moov.trak.mdia.flag
	//mp4c->moov.trak.mdia.reserved
	strncpy((char *)mp4c->moov.trak.mdia.hdlr.handler_type,"vide",4);
	//mp4c->moov.trak.mdia.reserved1
	strncpy((char *)mp4c->moov.trak.mdia.hdlr.name,"SercV",5);
	
	/* minf */
	//mp4c->moov.trak.mdia.minf.size = SWAP32(sizeof(MP4MediaInfoAtom));
	strncpy((char *)mp4c->moov.trak.mdia.minf.type,"minf",4);

	/* vmhd */
	mp4c->moov.trak.mdia.minf.vmhd.size = SWAP32(sizeof(MP4VideoMediaHeaderAtom));
	strncpy((char *)mp4c->moov.trak.mdia.minf.vmhd.type,"vmhd",4);
	//mp4c->moov.trak.mdia.minf.vmhd.version
	mp4c->moov.trak.mdia.minf.vmhd.flag[2] = 0x01;
	//mp4c->moov.trak.mdia.minf.vmhd.reserve

	/* dinf */
	mp4c->moov.trak.mdia.minf.dinf.size = SWAP32(sizeof(MP4DataInfoAtom));
	strncpy((char *)mp4c->moov.trak.mdia.minf.dinf.type,"dinf",4);
	/* dref */
	mp4c->moov.trak.mdia.minf.dinf.dref.size = SWAP32(sizeof(MP4DataRefAtom));
	strncpy((char *)mp4c->moov.trak.mdia.minf.dinf.dref.type,"dref",4);
	//mp4c->moov.trak.mdia.minf.dref.version;
	mp4c->moov.trak.mdia.minf.dinf.dref.flag[2] = 0x00;
	mp4c->moov.trak.mdia.minf.dinf.dref.entry_count = SWAP32(0x00000001);
	// url
	mp4c->moov.trak.mdia.minf.dinf.dref.url.size = SWAP32(sizeof(DataEntryUrlAtom));
	strncpy((char *)mp4c->moov.trak.mdia.minf.dinf.dref.url.type,"url ",4);
	//mp4c->moov.trak.mdia.minf.dinf.dref.url.version
	mp4c->moov.trak.mdia.minf.dinf.dref.url.flag[2] = 0x01;
	
	// stbl
	//mp4c->moov.trak.mdia.minf.stbl.size = SWAP32(sizeof(MP4SampleTableAtom));
	strncpy((char *)mp4c->moov.trak.mdia.minf.stbl.type,"stbl",4);
	
	// stsd
	mp4c->moov.trak.mdia.minf.stbl.stsd.size = SWAP32(sizeof(MP4SampleDescAtom));
	strncpy((char *)mp4c->moov.trak.mdia.minf.stbl.stsd.type,"stsd",4);
	//mp4c->moov.trak.mdia.minf.stbl.stsd.version
	mp4c->moov.trak.mdia.minf.stbl.stsd.flag[2] = 0x0;
	mp4c->moov.trak.mdia.minf.stbl.stsd.entry_count = SWAP32(0x00000001);
	
	FillMpeg4SampleEntry((Mpeg4SampleEntry *)&mp4c->moov.trak.mdia.minf.stbl.stsd.VisualSampleEntry[0], fd_info, width, height);
	
	mp4c->moov.trak.mdia.minf.stbl.size = SWAP32(sizeof(MP4SampleTableAtom)+size);
	mp4c->moov.trak.mdia.minf.size = SWAP32(sizeof(MP4MediaInfoAtom)+size);
	mp4c->moov.trak.mdia.size = SWAP32(sizeof(MP4MediaAtom)+size);
	mp4c->moov.trak.size = SWAP32(sizeof(MP4TrackAtom)+size);
	mp4c->moov.size = SWAP32(sizeof(MP4MoovAtom)+size);
	
	return 0;
}

static int FillSampleEntry(int fd, int fd_info)
{
	MP4SampleEntryAtom entry;
	MP4SampleSizeAtom size_entry;

	u32 i,j,k,len;
	u32 chunk,offset,stts_count=0;
	FrameInfo info,info1,info2;
	u32 duration = 0;
	u32 size;

	// stts
	lseek(fd_info, 0, SEEK_SET);
	read(fd_info, &info, sizeof(FrameInfo));
	for (i = 1; i <= info.count; i++)
	{
		read(fd_info, &info1, sizeof(FrameInfo));
		//fprintf(stderr, "i %d duration %d\n",i,info1.duration);
		if (info1.duration != duration)
		{
			stts_count++;
		}
		duration = info1.duration;
	}
	
	memset(&entry, 0, sizeof(entry));
	entry.size = SWAP32(sizeof(MP4SampleEntryAtom) + (stts_count*8));
	strncpy((char *)entry.type, "stts", 4);
	entry.entry_count = SWAP32(stts_count);
	write(fd, &entry, sizeof(MP4SampleEntryAtom));
	
	j = 0;
	for( i = 1; i <= stts_count; i++ )
	{
		k = 0;
		while(j < info.count) 
		{
			k++;
			j++;
			lseek(fd_info, j*sizeof(FrameInfo), SEEK_SET);
			read(fd_info, &info1, sizeof(FrameInfo));
			read(fd_info, &info2, sizeof(FrameInfo));
			
			if( info1.duration != info2.duration)
			{
				break;
			}
		}
		//fprintf(stderr, "i %d k %d j %d duration %d\n",i,k,j,info1.duration);
		len = SWAP32(k);
		write(fd, &len, sizeof(u32));
		len = SWAP32(info1.duration);		
		write(fd, &len, sizeof(u32));
	}

	// stsc
	if((info.count % FRAMES_PER_TRUNK) == 0)
	{
		chunk = info.count / FRAMES_PER_TRUNK;
	}
	else
	{
		chunk = (info.count / FRAMES_PER_TRUNK) + 1;
	}
	
	memset(&entry, 0, sizeof(entry));
	entry.size = SWAP32(sizeof(MP4SampleEntryAtom) + (chunk*12));
	strncpy((char *)entry.type,"stsc",4);
	entry.entry_count = SWAP32(chunk);
	write(fd, &entry, sizeof(MP4SampleEntryAtom));
	
	for( i = 1; i < chunk; i++ ){
		len = SWAP32(i);
		write(fd, &len, sizeof(u32));
		len = SWAP32(FRAMES_PER_TRUNK);
		write(fd, &len, sizeof(u32));
		len = SWAP32(0x00000001);
		write(fd, &len, sizeof(u32));
	}
	
	if( info.count % FRAMES_PER_TRUNK == 0 ){
		len = SWAP32(i);
		write(fd, &len, sizeof(u32));
		len = SWAP32(FRAMES_PER_TRUNK);
		write(fd, &len, sizeof(u32));
		len = SWAP32(0x00000001);
		write(fd, &len, sizeof(u32));

	} else {
		len = SWAP32(i);
		write(fd, &len, sizeof(u32));
		len = SWAP32(info.count % FRAMES_PER_TRUNK);
		write(fd, &len, sizeof(u32));
		len = SWAP32(0x00000001);
		write(fd, &len, sizeof(u32));
	}
	
	// stsz
	memset(&size_entry, 0, sizeof(size_entry));
	size_entry.size = SWAP32(sizeof(MP4SampleSizeAtom) + (info.count*4));
	strncpy((char *)size_entry.type,"stsz",4);
	size_entry.defaultsize = 0x0;
	size_entry.entry_count = SWAP32(info.count);
	write(fd, &size_entry, sizeof(MP4SampleSizeAtom));
	
	lseek(fd_info, sizeof(FrameInfo), SEEK_SET);
	for( i = 1; i <= info.count; i++ ){
		read(fd_info, &info1, sizeof(FrameInfo));
		len = SWAP32(info1.size);
		write(fd, &len, sizeof(u32));
	}
	
	// stco
	memset(&entry, 0, sizeof(entry));
	entry.size = SWAP32(sizeof(MP4SampleEntryAtom) + (chunk*4));
	strncpy((char *)entry.type,"stco",4);
	entry.entry_count = SWAP32(chunk);
	write(fd, &entry, sizeof(MP4SampleEntryAtom));
	
	size = SampleEntrySize(fd_info);
	offset = sizeof(MP4Atom) + size + sizeof(MDAT);
	for( i = 1; i <= chunk; i++ )
	{
		len = SWAP32(offset);
		write(fd, &len, sizeof(u32));
		for( j = 1; j <=FRAMES_PER_TRUNK ; j++)
		{
			lseek(fd_info, (j+(i-1)*FRAMES_PER_TRUNK)*sizeof(FrameInfo), SEEK_SET);
			read(fd_info, &info1, sizeof(FrameInfo));
			offset += info1.size;
		}
	}
	
	// stss		
	memset(&entry, 0, sizeof(entry));
	entry.size = SWAP32(sizeof(MP4SampleEntryAtom) + (info.frm*4));
	strncpy((char *)entry.type,"stss",4);
	entry.entry_count = SWAP32(info.frm);
	write(fd, &entry, sizeof(MP4SampleEntryAtom));

	j = 1;
	for( i = 1; i <= info.frm; i++ ){
		for( ; j <= info.count ; j++ )
		{
			lseek(fd_info, j*sizeof(FrameInfo), SEEK_SET);
			read(fd_info, &info1, sizeof(FrameInfo));
			if( info1.frm == 1 ){
				len = SWAP32(j);
				write(fd, &len, sizeof(u32));
			}
		}
	}
	
	return 0;
}

int CreateMP4File(int fd, int fd_info, int fd_mdat, int width, int height)
{
	int ret = 0;
	MDAT mdat;
	MP4Atom mp4header;
	FrameInfo info;
	char buf[4096];
	
	fprintf(stderr, "create MP4 File start...\n");
	
	// Fill mp4 header
	memset(&mp4header, 0, sizeof(mp4header));	
	ret = GetMP4FileHeader(fd_info, &mp4header, width, height);
	if (-1 == ret)
	{
		fprintf(stderr, "Get MP4 Header error.\n");
		return -1;
	}
	fprintf(stderr, "Get MP4 Header done.\n");
	
	if (-1 == write(fd, &mp4header, sizeof(MP4Atom)))
	{
		return -1;
	}
	fprintf(stderr, "Write header, size: %lu\n", sizeof (MP4Atom));
	
	// Fill sample entry
	FillSampleEntry(fd, fd_info);	
	
	// Fill mdat atom	
	lseek(fd_info, 0, SEEK_SET);
	read(fd_info, &info, sizeof(FrameInfo));
	
	memset(&mdat,'\0',sizeof(MDAT));
	mdat.size = SWAP32(info.size + 8);	
	strncpy((char *)mdat.type, "mdat", 4);
	if (-1 == write(fd, &mdat, sizeof(MDAT)))
	{
		return -1;
	}
	
	//write mdat data to mp4 file	
	lseek(fd_mdat, 0, SEEK_SET);
	while(1)
	{
		memset(buf, 0 ,sizeof(buf));
		ret = read(fd_mdat, buf, sizeof(buf));
		if (ret <= 0)
		{
			break;
		}
		write(fd, buf, ret);
	}
	
#if 0
	//dump the file for analysis
	{
		int ret;
		struct sockaddr_in dst;
		int sock;
		char *http_header="POST / HTTP/1.0\r\n\r\n";
		
		sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
		
		dst.sin_family = AF_INET;
		dst.sin_addr.s_addr = inet_addr("172.21.15.59");
		dst.sin_port = htons(1235);
		
	
		ret = connect(sock, (struct sockaddr *)&dst, sizeof(dst));
		if (ret < 0)
		{
			fprintf(stderr, "connect to relay server fail\n");
			return -1;
		}
		write(sock,http_header, strlen(http_header));
		
		lseek(fd, 0, SEEK_SET);
		
		while(1)
		{
			memset(buf, 0 ,sizeof(buf));
			ret = read(fd, buf, sizeof(buf));
			fprintf(stderr, "read %d from file.\n",ret);

			if (ret <= 0)
			{
				break;
			}
			ret = write(sock, buf, ret);
			fprintf(stderr, "write %d to socket\n",ret);

		}
	}
#endif
	return 0;
}

