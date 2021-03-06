//
//  MjpegParser.m
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

#import "MjpegParser.h"
#import "RtspClient.h"
#import "Md5.h"
#import "Base64.h"
#import <CFNetwork/CFNetwork.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h> 
#import <netdb.h>
// the following pair of Q-tables are shared by all resolution images
static unsigned char QTables_Luma[64] = 
{
	0x03, 0x02, 0x02, 0x03, 0x02, 0x02, 0x03, 0x03, 0x03, 0x03, 
	0x04, 0x03, 0x03, 0x04, 0x05, 0x08, 0x05, 0x05, 0x04, 0x04, 
	0x05, 0x0A, 0x07, 0x07, 0x06, 0x08, 0x0C, 0x0A, 0x0C, 0x0C, 
	0x0B, 0x0A, 0x0B, 0x0B, 0x0D, 0x0E, 0x12, 0x10, 0x0D, 0x0E,
	0x11, 0x0E, 0x0B, 0x0B, 0x10, 0x16, 0x10, 0x11, 0x13, 0x14, 
	0x15, 0x15, 0x15, 0x0C, 0x0F, 0x17, 0x18, 0x16, 0x14, 0x18,
	0x12, 0x14, 0x15, 0x14,
};

static unsigned char QTables_Chroma[64] = 
{
	0x03, 0x04, 0x04, 0x05, 0x04, 0x05, 0x09, 0x05, 0x05, 0x09,
	0x14, 0x0D, 0x0B, 0x0D, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14,
	0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14,
	0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14,
	0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14,
	0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14,
	0x14, 0x14, 0x14, 0x14, 
};

// the following Q-tables are for resolution higher than 160x120
static unsigned char QTables_Luma_Q_640_480_High[64] = 
{
	0x06, 0x04, 0x05, 0x06, 0x05, 0x04, 0x06, 0x06, 0x05, 0x06, 
	0x07, 0x07, 0x06, 0x08, 0x0A, 0x10, 0x0A, 0x0A, 0x09, 0x09,
	0x0A, 0x14, 0x0E, 0x0F, 0x0C, 0x10, 0x17, 0x14, 0x18, 0x18,
	0x17, 0x14, 0x16, 0x16, 0x1A, 0x1D, 0x25, 0x1F, 0x1A, 0x1B,
	0x23, 0x1C, 0x16, 0x16, 0x20, 0x2C, 0x20, 0x23, 0x26, 0x27, 
	0x29, 0x2A, 0x29, 0x19, 0x1F, 0x2D, 0x30, 0x2D, 0x28, 0x30,
	0x25, 0x28, 0x29, 0x28,
};

static unsigned char QTables_Luma_Q_640_480_Normal[64] = 
{
	0x0B, 0x08, 0x08, 0x0A, 0x08, 0x07, 0x0B, 0x0A, 0x09, 0x0A, 
	0x0D, 0x0C, 0x0B, 0x0D, 0x11, 0x1C, 0x12, 0x11, 0x0F, 0x0F, 
	0x11, 0x22, 0x19, 0x1A, 0x14, 0x1C, 0x29, 0x24, 0x2B, 0x2A, 
	0x28, 0x24, 0x27, 0x27, 0x2D, 0x32, 0x40, 0x37, 0x2D, 0x30,
	0x3D, 0x30, 0x27, 0x27, 0x38, 0x4C, 0x39, 0x3D, 0x43, 0x45,
	0x48, 0x49, 0x48, 0x2B, 0x36, 0x4F, 0x55, 0x4E, 0x46, 0x54,
	0x40, 0x47, 0x48, 0x45,
};

static unsigned char QTables_Luma_Q_640_480_Low[64] = 
{
	0x12, 0x0C, 0x0D, 0x10, 0x0D, 0x0B, 0x12, 0x10, 0x0E, 0x10,  
	0x14, 0x13, 0x12, 0x15, 0x1B, 0x2C, 0x1D, 0x1B, 0x18, 0x18,  
	0x1B, 0x36, 0x27, 0x29, 0x20, 0x2C, 0x40, 0x39, 0x44, 0x43,
	0x3F, 0x39, 0x3E, 0x3D, 0x47, 0x50, 0x66, 0x57, 0x47, 0x4B,
	0x61, 0x4D, 0x3D, 0x3E, 0x59, 0x79, 0x5A, 0x61, 0x69, 0x6D,
	0x72, 0x73, 0x72, 0x45, 0x55, 0x7D, 0x86, 0x7C, 0x6F, 0x85,
	0x66, 0x70, 0x72, 0x6E,
};

static unsigned char QTables_Luma_Q_640_480_VeryLow[64] = 
{
	0x1B, 0x12, 0x14, 0x17, 0x14, 0x11, 0x1B, 0x17, 0x16, 0x17,  
	0x1E, 0x1C, 0x1B, 0x20, 0x28, 0x42, 0x2B, 0x28, 0x25, 0x25, 
	0x28, 0x51, 0x3A, 0x3D, 0x30, 0x42, 0x60, 0x55, 0x65, 0x64,
	0x5F, 0x55, 0x5D, 0x5B, 0x6A, 0x78, 0x99, 0x81, 0x6A, 0x71,
	0x90, 0x73, 0x5B, 0x5D, 0x85, 0xB5, 0x86, 0x90, 0x9E, 0xA3,
	0xAB, 0xAD, 0xAB, 0x67, 0x80, 0xBC, 0xC9, 0xBA, 0xA6, 0xC7,
	0x99, 0xA8, 0xAB, 0xA4,
};

static unsigned char QTables_Chroma_Q_640_480_High[64] = 
{
	0x07, 0x07, 0x07, 0x0A, 0x08, 0x0A, 0x13, 0x0A, 0x0A, 0x13,
	0x28, 0x1A, 0x16, 0x1A, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28,
	0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28,
	0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28,
	0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28,
	0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28,
	0x28, 0x28, 0x28, 0x28, 
};

static unsigned char QTables_Chroma_Q_640_480_Normal[64] = 
{
	0x0C, 0x0D, 0x0D, 0x11, 0x0F, 0x11, 0x21, 0x12, 0x12, 0x21,
	0x45, 0x2E, 0x27, 0x2E, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45,
	0x45, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45,
	0x45, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45,
	0x45, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45,
	0x45, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45,
	0x45, 0x45, 0x45, 0x45, 
};

static unsigned char QTables_Chroma_Q_640_480_Low[64] = 
{
	0x13, 0x14, 0x14, 0x1B, 0x17, 0x1B, 0x34, 0x1D, 0x1D, 0x34,
	0x6E, 0x49, 0x3E, 0x49, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E,
	0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E,
	0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E,
	0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E,
	0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E,
	0x6E, 0x6E, 0x6E, 0x6E, 
};

static unsigned char QTables_Chroma_Q_640_480_VeryLow[64] = 
{
	0x1C, 0x1E, 0x1E, 0x28, 0x23, 0x28, 0x4E, 0x2B, 0x2B, 0x4E,
	0xA4, 0x6E, 0x5D, 0x6E, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4,
	0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4,
	0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4,
	0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4,
	0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4, 0xA4,
};

// the following Q-tables are for resolution 160x120
static unsigned char QTables_Luma_Q_VeryHigh[64] = // for 160x120 resolution
{
	0x07, 0x05, 0x06, 0x06, 0x06, 0x05, 0x07, 0x06, 0x06, 0x06, 
	0x08, 0x08, 0x07, 0x09, 0x0B, 0x12, 0x0C, 0x0B, 0x0A, 0x0A, 
	0x0B, 0x17, 0x10, 0x11, 0x0D, 0x12, 0x1B, 0x17, 0x1C, 0x1C, 
	0x1A, 0x17, 0x1A, 0x19, 0x1D, 0x21, 0x2A, 0x24, 0x1D, 0x1F,
	0x28, 0x20, 0x19, 0x1A, 0x25, 0x32, 0x25, 0x28, 0x2C, 0x2D, 
	0x2F, 0x30, 0x2F, 0x1D, 0x23, 0x34, 0x38, 0x34, 0x2E, 0x37,
	0x2A, 0x2E, 0x2F, 0x2E,
};

static unsigned char QTables_Luma_Q_High[64] = 
{
	0x0C, 0x08, 0x09, 0x0A, 0x09, 0x07, 0x0C, 0x0A, 0x0A, 0x0A,
	0x0D, 0x0D, 0x0C, 0x0E, 0x12, 0x1E, 0x13, 0x12, 0x10, 0x10, 
	0x12, 0x24, 0x1A, 0x1B, 0x15, 0x1E, 0x2B, 0x26, 0x2D, 0x2C, 
	0x2A, 0x26, 0x29, 0x29, 0x2F, 0x35, 0x44, 0x3A, 0x2F, 0x32,
	0x40, 0x33, 0x29, 0x29, 0x3B, 0x51, 0x3C, 0x40, 0x46, 0x49, 
	0x4C, 0x4D, 0x4C, 0x2E, 0x39, 0x54, 0x5A, 0x53, 0x4A, 0x59,
	0x44, 0x4B, 0x4C, 0x49,
};

static unsigned char QTables_Luma_Q_Normal[64] = 
{
	0x12, 0x0C, 0x0D, 0x10, 0x0D, 0x0B, 0x12, 0x10, 0x0E, 0x10, 
	0x14, 0x13, 0x12, 0x15, 0x1B, 0x2C, 0x1D, 0x1B, 0x18, 0x18, 
	0x1B, 0x36, 0x27, 0x29, 0x20, 0x2C, 0x40, 0x39, 0x44, 0x43, 
	0x3F, 0x39, 0x3E, 0x3D, 0x47, 0x50, 0x66, 0x57, 0x47, 0x4B,
	0x61, 0x4D, 0x3D, 0x3E, 0x59, 0x79, 0x5A, 0x61, 0x69, 0x6D, 
	0x72, 0x73, 0x72, 0x45, 0x55, 0x7D, 0x86, 0x7C, 0x6F, 0x85,
	0x66, 0x70, 0x72, 0x6E,
};

static unsigned char QTables_Luma_Q_Low[64] = 
{
	0x20, 0x16, 0x18, 0x1C, 0x18, 0x14, 0x20, 0x1C, 0x1A, 0x1C, 
	0x24, 0x22, 0x20, 0x26, 0x30, 0x50, 0x34, 0x30, 0x2C, 0x2C, 
	0x30, 0x62, 0x46, 0x4A, 0x3A, 0x50, 0x74, 0x66, 0x7A, 0x78,
	0x72, 0x66, 0x70, 0x6E, 0x80, 0x90, 0xB8, 0x9C, 0x80, 0x88,
	0xAE, 0x8A, 0x6E, 0x70, 0xA0, 0xDA, 0xA2, 0xAE, 0xBE, 0xC4,
	0xCE, 0xD0, 0xCE, 0x7C, 0x9A, 0xE2, 0xF2, 0xE0, 0xC8, 0xF0,
	0xB8, 0xCA, 0xCE, 0xC6,
};

static unsigned char QTables_Luma_Q_VeryLow[64] = 
{
	0x28, 0x1C, 0x1E, 0x23, 0x1E, 0x19, 0x28, 0x23, 0x21, 0x23, 
	0x2D, 0x2B, 0x28, 0x30, 0x3C, 0x64, 0x41, 0x3C, 0x37, 0x37, 
	0x3C, 0x7B, 0x58, 0x5D, 0x49, 0x64, 0x91, 0x80, 0x99, 0x96,
	0x8F, 0x80, 0x8C, 0x8A, 0xA0, 0xB4, 0xE6, 0xC3, 0xA0, 0xAA,
	0xDA, 0xAD, 0x8A, 0x8C, 0xC8, 0xFF, 0xCB, 0xDA, 0xEE, 0xF5,
	0xFF, 0xFF, 0xFF, 0x9B, 0xC1, 0xFF, 0xFF, 0xFF, 0xFA, 0xFF,
	0xE6, 0xFD, 0xFF, 0xF8,
};

static unsigned char QTables_Chroma_Q_VeryHigh[64] =	// 160x120 resolution
{
	0x08, 0x08, 0x08, 0x0B, 0x0A, 0x0B, 0x16, 0x0C, 0x0C, 0x16,
	0x2E, 0x1E, 0x1A, 0x1E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
	0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
	0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
	0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
	0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
	0x2E, 0x2E, 0x2E, 0x2E, 
};

static unsigned char QTables_Chroma_Q_High[64] =	// 160x120 resolution
{
	0x0D, 0x0D, 0x0D, 0x12, 0x10, 0x12, 0x23, 0x13, 0x13, 0x23,
	0x49, 0x31, 0x29, 0x31, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49,
	0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49,
	0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49,
	0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49,
	0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49,
	0x49, 0x49, 0x49, 0x49, 
};

static unsigned char QTables_Chroma_Q_Normal[64] =	// 160x120 resolution
{
	0x13, 0x14, 0x14, 0x1B, 0x17, 0x1B, 0x34, 0x1D, 0x1D, 0x34,
	0x6E, 0x49, 0x3E, 0x49, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E,
	0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E,
	0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E,
	0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E,
	0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E, 0x6E,
	0x6E, 0x6E, 0x6E, 0x6E, 
};

static unsigned char QTables_Chroma_Q_Low[64] = 
{
	0x22, 0x24, 0x24, 0x30, 0x2A, 0x30, 0x5E, 0x34, 0x34, 0x5E,
	0xC6, 0x84, 0x70, 0x84, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6,
	0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6,
	0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6,
	0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6,
	0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6,
	0xC6, 0xC6, 0xC6, 0xC6, 
};
static unsigned char QTables_Chroma_Q_VeryLow[64] = 
{
	0x2B, 0x2D, 0x2D, 0x3C, 0x35, 0x3C, 0x76, 0x41, 0x41, 0x76,
	0xF8, 0xA5, 0x8C, 0xA5, 0xF8, 0xF8, 0xF8, 0xF8, 0xF8, 0xF8,
	0xF8, 0xF8, 0xF8, 0xF8, 0xF8, 0xF8, 0xF8, 0xF8, 0xF8, 0xF8,
	0xF8, 0xF8, 0xF8, 0xF8, 0xF8, 0xF8, 0xF8, 0xF8, 0xF8, 0xF8,
	0xF8, 0xF8, 0xF8, 0xF8, 0xF8, 0xF8, 0xF8, 0xF8, 0xFF, 0xC4,
	0x01, 0xA2, 0x00, 0x00, 0x01, 0x05, 0x01, 0x01, 0x01, 0x01,
	0x01, 0x01, 0x00, 0x00, 
};

/*
// the following Q-tables are for NC831 model
static unsigned char QTables_Luma_NC831[64] = 
{
	0x10, 0x0B, 0x0C, 0x0E, 0x0C, 0x0A, 0x10, 0x03, 0x0E, 0x0D, 
	0x0E, 0x12, 0x11, 0x10, 0x13, 0x18, 0x28, 0x1A, 0x18, 0x16, 
	0x16, 0x18, 0x31, 0x23, 0x25, 0x1D, 0x28, 0x3A, 0x33, 0x3D, 
	0x3C, 0x39, 0x33, 0x38, 0x37, 0x40, 0x48, 0x5C, 0x4E, 0x40,
	0x44, 0x57, 0x45, 0x37, 0x38, 0x50, 0x6D, 0x51, 0x57, 0x5F, 
	0x62, 0x67, 0x68, 0x3E, 0x4D, 0x71, 0x79, 0x70, 0x64, 0x78,
	0x5C, 0x65, 0x67, 0x63,
};

static unsigned char QTables_Chroma_NC831[64] = 
{
	0x11, 0x12, 0x12, 0x18, 0x15, 0x18, 0x2F, 0x1A, 0x1A, 0x2F,
	0x63, 0x42, 0x38, 0x42, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63,
	0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63,
	0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63,
	0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63,
	0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63,
	0x63, 0x63, 0x63, 0x63, 
};
*/


static unsigned char lum_dc_codelens[] = 
{
	0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
};

static unsigned char lum_dc_symbols[] = 
{
	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
};

static unsigned char lum_ac_codelens[] = 
{
	0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 0x7d,
};

static unsigned char lum_ac_symbols[] = 
{
	0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12,
	0x21, 0x31, 0x41, 0x06, 0x13, 0x51, 0x61, 0x07,
	0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xa1, 0x08,
	0x23, 0x42, 0xb1, 0xc1, 0x15, 0x52, 0xd1, 0xf0,
	0x24, 0x33, 0x62, 0x72, 0x82, 0x09, 0x0a, 0x16,
	0x17, 0x18, 0x19, 0x1a, 0x25, 0x26, 0x27, 0x28,
	0x29, 0x2a, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
	0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
	0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
	0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
	0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79,
	0x7a, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
	0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98,
	0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
	0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6,
	0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3, 0xc4, 0xc5,
	0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2, 0xd3, 0xd4,
	0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xe1, 0xe2,
	0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea,
	0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
	0xf9, 0xfa,
};

static unsigned char chm_dc_codelens[] = 
{
	0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0,
};

static unsigned char chm_dc_symbols[] = 
{
	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
};

static unsigned char chm_ac_codelens[] = 
{
	0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 0x77,
};

static unsigned char chm_ac_symbols[] = 
{
	0x00, 0x01, 0x02, 0x03, 0x11, 0x04, 0x05, 0x21,
	0x31, 0x06, 0x12, 0x41, 0x51, 0x07, 0x61, 0x71,
	0x13, 0x22, 0x32, 0x81, 0x08, 0x14, 0x42, 0x91,
	0xa1, 0xb1, 0xc1, 0x09, 0x23, 0x33, 0x52, 0xf0,
	0x15, 0x62, 0x72, 0xd1, 0x0a, 0x16, 0x24, 0x34,
	0xe1, 0x25, 0xf1, 0x17, 0x18, 0x19, 0x1a, 0x26,
	0x27, 0x28, 0x29, 0x2a, 0x35, 0x36, 0x37, 0x38,
	0x39, 0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
	0x49, 0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58,
	0x59, 0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68,
	0x69, 0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78,
	0x79, 0x7a, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
	0x88, 0x89, 0x8a, 0x92, 0x93, 0x94, 0x95, 0x96,
	0x97, 0x98, 0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5,
	0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4,
	0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3,
	0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2,
	0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda,
	0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9,
	0xea, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
	0xf9, 0xfa,
};
/*
static unsigned char humffmanTable[] = 
{
	0x00, 0x00, 0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x02,
	0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x10,
	0x00, 0x02, 0x01, 0x03, 0x03, 0x02, 0x04, 0x03, 0x05, 0x05,
	0x04, 0x04, 0x00, 0x00, 0x01, 0x7D, 0x01, 0x02, 0x03, 0x00,
	0x04, 0x11, 0x05, 0x12, 0x21, 0x31, 0x41, 0x06, 0x13, 0x51,
	0x61, 0x07, 0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xA1, 0x08,
	0x23, 0x42, 0xB1, 0xC1, 0x15, 0x52, 0xD1, 0xF0, 0x24, 0x33,
	0x62, 0x72, 0x82, 0x09, 0x0A, 0x16, 0x17, 0x18, 0x19, 0x1A,
	0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x34, 0x35, 0x36, 0x37,
	0x38, 0x39, 0x3A, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
	0x4A, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x63,
	0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x73, 0x74, 
	0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x83, 0x84, 0x85, 0x86,
	0x87, 0x88, 0x89, 0x8A, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
	0x98, 0x99, 0x9A, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8,
	0xA9, 0xAA, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8, 0xB9,
	0xBA, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 
	0xCA, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA,
	0xE1, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA,
	0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA,
	0x01, 0x00, 0x03, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
	0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x02,
	0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x11,
	0x00, 0x02, 0x01, 0x02, 0x04, 0x04, 0x03, 0x04, 0x07, 0x05,
	0x04, 0x04, 0x00, 0x01, 0x02, 0x77, 0x00, 0x01, 0x02, 0x03,
	0x11, 0x04, 0x05, 0x21, 0x31, 0x06, 0x12, 0x41, 0x51, 0x07,
	0x61, 0x71, 0x13, 0x22, 0x32, 0x81, 0x08, 0x14, 0x42, 0x91,
	0xA1, 0xB1, 0xC1, 0x09, 0x23, 0x33, 0x52, 0xF0, 0x15, 0x62,
	0x72, 0xD1, 0x0A, 0x16, 0x24, 0x34, 0xE1, 0x25, 0xF1, 0x17,
	0x18, 0x19, 0x1A, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x35, 0x36,
	0x37, 0x38, 0x39, 0x3A, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
	0x49, 0x4A, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A,
	0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x73, 0x74,
	0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x82, 0x83, 0x84, 0x85,
	0x86, 0x87, 0x88, 0x89, 0x8A, 0x92, 0x93, 0x94, 0x95, 0x96,
	0x97, 0x98, 0x99, 0x9A, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7,
	0xA8, 0xA9, 0xAA, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8,
	0xB9, 0xBA, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9,
	0xCA, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA,
	0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xF2,
	0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA,
};
*/


unsigned char* MakeQtHeader(unsigned char* p,unsigned char* qt ,int no,int len)
{
	*p++ = 0xff;
	*p++ = 0xdb;
	*p++ = 0x00;
	*p++ = 64+3;
	*p++ = no;
	memcpy(p,qt,len);
	return (p+len);
}

static unsigned char* MakeHuffmanHeader(unsigned char* p, unsigned char *codelens, int ncodes,
										unsigned char *symbols, int nsymbols, int tableNo,
										int tableClass)
{
    *p++ = 0xFF;
    *p++ = 0xC4;            /* DHT */
    *p++ = 0;               /* length msb */
    *p++ = 3 + ncodes + nsymbols; /* length lsb */
    *p++ = (tableClass << 4) | tableNo;
    memcpy(p, codelens, ncodes);
    p += ncodes;
    memcpy(p, symbols, nsymbols);
    p += nsymbols;
    return (p);
	
	
}

static unsigned char* MakeDRIHeader(unsigned char *p,unsigned short dri)
{
	*p++ = 0xff;
	*p++ = 0xdd;
	*p++ = 0x00;
	*p++ = 0x4;
	*p++ = dri >> 8;
	*p++ = dri & 0xff;
	
	return p;
}


@implementation MjpegParser


- (id) init 
{
	
	if ((self = [super init]) == nil)
		return nil;
	
		
	_jp_pre_dri = 0;
	
	_offset_len = 0;
	
	_jp_luma_len   = 0;
	_jp_chroma_len = 0;
	
	return self;
}


- (void) MakeQTableWithWidth: (int) width
                      Height: (int) height
                      Header: (struct JPEGHeadr) jpeq_hdr
{
	
	int w = width;
	int h = height;
	
	if((w>=640) && (h>=480))	// high resolution
	{
		if(jpeq_hdr.q >= 90)	// very high
		{
			memcpy(_jp_luma_qt, QTables_Luma, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma, 64);
		}
		else if(jpeq_hdr.q >= 80)	// high
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_640_480_High, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_640_480_High, 64);
		}
		else if(jpeq_hdr.q >= 50)	// normal
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_640_480_Normal, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_640_480_Normal, 64);
		}
		else if(jpeq_hdr.q >= 40)	// low
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_640_480_Low, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_640_480_Low, 64);
		}
		else
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_640_480_VeryLow, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_640_480_VeryLow, 64);
		}
		_jp_luma_len   = 64;
		_jp_chroma_len = 64;
	}
	else if((w>=320) && (h>=240))
	{
		if(jpeq_hdr.q >= 90)	// very high
		{
			memcpy(_jp_luma_qt, QTables_Luma, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma, 64);
		}
		else if(jpeq_hdr.q >= 75)	// high
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_640_480_High, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_640_480_High, 64);
		}
		else if(jpeq_hdr.q>= 60)	// normal
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_640_480_Normal, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_640_480_Normal, 64);
		}
		else if(jpeq_hdr.q >= 45)	// low
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_640_480_Low, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_640_480_Low, 64);
		}
		else
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_640_480_VeryLow, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_640_480_VeryLow, 64);
		}
		_jp_luma_len   = 64;
		_jp_chroma_len = 64;
	}
	else if((w<=160) && (h<=120))
	{
		if(jpeq_hdr.q  >= 75)	// very high
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_VeryHigh, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_VeryHigh, 64);
		}
		else if(jpeq_hdr.q  >= 60)	// high
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_High, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_High, 64);
		}
		else if(jpeq_hdr.q  >= 45)	// normal
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_Normal, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_Normal, 64);
		}
		else if(jpeq_hdr.q  >= 25)	// low
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_Low, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_Low, 64);
		}
		else
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_VeryLow, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_VeryLow, 64);
		}
		_jp_luma_len   = 64;
		_jp_chroma_len = 64;
	}
	else if(((w<=160) && (h<=128))
			|| ((w<=176) && (h<=144))
			|| ((w<=176) && (h<=120)))
	{
		if(jpeq_hdr.q  >= 90)	// very high
		{
			memcpy(_jp_luma_qt, QTables_Luma, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma, 64);
		}
		else if(jpeq_hdr.q  >= 75)	// very high
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_VeryHigh, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_VeryHigh, 64);
		}
		else if(jpeq_hdr.q  >= 60)	// high
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_High, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_High, 64);
		}
		else if(jpeq_hdr.q  >= 45)	// normal
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_Normal, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_Normal, 64);
		}
		else if(jpeq_hdr.q  >= 25)	// low
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_Low, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_Low, 64);
		}
		else
		{
			memcpy(_jp_luma_qt, QTables_Luma_Q_VeryLow, 64);
			memcpy(_jp_chroma_qt, QTables_Chroma_Q_VeryLow, 64);
		}
		_jp_luma_len   = 64;
		_jp_chroma_len = 64;
	}
	
	else {
		_jp_luma_len   = 0;
		_jp_chroma_len = 0;
	}
	
}

- (unsigned int) MakeHeader 
{
	unsigned char* start = _jp_frame_header;
	unsigned char* p     = _jp_frame_header;
	int w = _w;
	int h = _h;
	
	*p++ = 0xff;
	*p++ = 0xd8; /* SOI */
	
	p = MakeQtHeader(p,_jp_luma_qt  ,0,_jp_luma_len  );
	p = MakeQtHeader(p,_jp_chroma_qt,1,_jp_chroma_len);
	
	if(_jp_pre_dri != 0)
	{
		// make dri header	
		p = MakeDRIHeader(p,_jp_pre_dri);
	}
	
	*p++ = 0xff;
	*p++ = 0xc0;	/* SOF */
	
	*p++ = 0x00;	/* length msb */
	*p++ = 17;		/* length lsb */
	*p++ = 8;		/* 8-bit precision */
	*p++ = h >> 8;  /* height msb */
	*p++ = h;		/* height lsb */
	*p++ = w >> 8;  /* width msb */
	*p++ = w;		/* wudth lsb */
	*p++ = 3;		/* number of components */
	
	
	// data extrected from HTTP motion jpef frame header
    *p++ = 0;               // comp 0 
    if ((_jp_jpeq_hdr.type == 0) || (_jp_jpeq_hdr.type == 64))
		*p++ = 0x21;    // hsamp = 2, vsamp = 1 
	else
		*p++ = 0x22;    // hsamp = 2, vsamp = 2 
	*p++ = 0;               // quant table 0 
	*p++ = 1;               // comp 1 
	*p++ = 0x11;            // hsamp = 1, vsamp = 1 
	*p++ = 1;               // quant table 1 
	*p++ = 2;               // comp 2 
	*p++ = 0x11;            // hsamp = 1, vsamp = 1 
	*p++ = 1;               // quant table 1 
	
	
	// huffman table
	//p = MakeHuffmanHeader(p);
	p = MakeHuffmanHeader(p, lum_dc_codelens,
						  sizeof(lum_dc_codelens),
						  lum_dc_symbols,
						  sizeof(lum_dc_symbols), 0, 0);
	p = MakeHuffmanHeader(p, lum_ac_codelens,
						  sizeof(lum_ac_codelens),
						  lum_ac_symbols,
						  sizeof(lum_ac_symbols), 0, 1);
	p = MakeHuffmanHeader(p, chm_dc_codelens,
						  sizeof(chm_dc_codelens),
						  chm_dc_symbols,
						  sizeof(chm_dc_symbols), 1, 0);
	p = MakeHuffmanHeader(p, chm_ac_codelens,
						  sizeof(chm_ac_codelens),
						  chm_ac_symbols,
						  sizeof(chm_ac_symbols), 1, 1);
	
	*p++ = 0xFF;
	*p++ = 0xDA;            // SOS 
	*p++ = 0;               // length msb 
	*p++ = 12;              // length lsb 
	*p++ = 3;               // 3 components 
	
	// data extrected from HTTP motion jpef frame header
	*p++ = 0;               // comp 1 
	*p++ = 0;               // huffman table 0 
	*p++ = 1;               // comp 1 
	*p++ = 0x11;            // huffman table 1 
	*p++ = 2;               // comp 2 
	*p++ = 0x11;            // huffman table 1 
	*p++ = 0;               // first DCT coeff 
	*p++ = 0x3F;            // last DCT coeff 
	*p++ = 0;               // sucessive approx. 
	
	int head_len = (p - start);
	
	memset(_jp_data,0,MJPEG_FRAME_BUFF_MAX);
	memcpy(_jp_data,_jp_frame_header,head_len);
	
	_jp_data_len = head_len;
	
	return (p - start);
}

- (int) ParserQtable:(unsigned char*) data
	         Dynamic:(BOOL) sign
{
	if(!(_jp_jpeq_hdr.type == 0  || _jp_jpeq_hdr.type == 1  || 
		 _jp_jpeq_hdr.type == 64  || _jp_jpeq_hdr.type == 65 ))
	{
		rterr("ParserQtable: Unknow mjpeg type\n");
		return sizeof(struct JPEGQtableHeader);
	}
	
	// build two q_table
	
	if(data[0] != 0 || data[1] != 0)
		return 0;
	
	unsigned int q_len = (unsigned int)(data[2] << 8) + data[3]; 
	
	
	if(q_len != 256 && q_len != 128 && q_len != 64)
		return 0;
	
	if(q_len<=0)
	{
		rterr("ParserQtable: q_len <=0\n");
		[self MakeQTableWithWidth:_w Height:_h Header:_jp_jpeq_hdr];
		return sizeof(struct JPEGQtableHeader);
	}
	
	
	int count = q_len;
	int q_offset = sizeof(struct JPEGQtableHeader);
	
	if(sign || _jp_pre_q !=_jp_jpeq_hdr.q) // dynamic q table
	{
		_jp_pre_q = _jp_jpeq_hdr.q;
		
		unsigned char* p = data + 4; //#1table
		
		if((*(data+1) & 0x01))
		{
			if(count < 128)
				return q_offset;
			
			memset(_jp_luma_qt,0,128);
			memcpy(_jp_luma_qt,p,128);
			count -= 128;
			q_offset += 128;
			_jp_luma_len = 128;
		}
		else 
		{
			if(count < 64) 
				return q_offset;
			
			memset(_jp_luma_qt,0,128);
			memcpy(_jp_luma_qt,p,64);
			count -= 64;
			q_offset += 64;
			_jp_luma_len = 64;
			
		}
		p += _jp_luma_len;  // #2table start---
		
		if((*(data+1) & 0x02))
		{
			if(count < 128)
				return q_offset;
			
			memset(_jp_chroma_qt,0,128);
			memcpy(_jp_chroma_qt,p,128);
			q_offset += 128;
			_jp_chroma_len = 128;
			
		}
		else 
		{
			if(count < 64)
				return q_offset;
			
			memset(_jp_chroma_qt,0,128);
			memcpy(_jp_chroma_qt,p,64);
			q_offset += 64;
			_jp_chroma_len = 64;
			
		}
		
		
	}
	
	return q_offset;
}


- (BOOL) ParserHeader:(unsigned char*) data
                   Length:(int) len
{
	if(*(data +1) & 0xffffff)
		return NO;
	
	struct JPEGHeadr jpeq_hdr;
	
	memcpy (&jpeq_hdr, data, sizeof(struct JPEGHeadr));
	
	_jp_jpeq_hdr = jpeq_hdr;
	
	int w = _w = jpeq_hdr.width << 3;
	int h = _h = jpeq_hdr.height << 3;
	
	rtdbg("ParserHeader: width = %d, height = %d\n", w, h);
	
	unsigned offset =  sizeof(struct JPEGHeadr);
	
	unsigned char *jp = data +sizeof(struct JPEGHeadr);
	//int jp_len = len -  sizeof(struct JPEGHeadr);
	
	rtdbg("ParserHeader: jpeg type = %d\n",jpeq_hdr.type);
	rtdbg("ParserHeader: jpeg q = %d\n",jpeq_hdr.q);
	
	if(jpeq_hdr.type > 63 && jpeq_hdr.type <128)
	{
		unsigned int n = (unsigned int)(jp[0] << 8) + jp[1]; 
	    if(_jp_pre_dri != n)	
			rterr("DRI = %d\n",n);
		
		if(n!=0)
			_jp_pre_dri = n;
		
		//offset 4 byte 
		jp += sizeof(struct JPEGHeaderRst);
		
		offset += sizeof(struct JPEGHeaderRst);
	}
	else if(jpeq_hdr.type > 128)
	{
		rtdbg("ParserHeader: not supported jpeg\n");
		return NO;
	}
	else 
		_jp_pre_dri = 0;

	if(jpeq_hdr.q >=128 && jpeq_hdr.q <255)
	{
		//static qtable
		offset += [self ParserQtable:jp Dynamic:NO];
	}
	else if(jpeq_hdr.q == 255)
	{
		//dynamic qtable
		offset += [self ParserQtable:jp Dynamic:YES];
	}
	else
	{
		if(_jp_pre_q != jpeq_hdr.q)
		{
			_jp_pre_q = jpeq_hdr.q;
			[self MakeQTableWithWidth:w Height:h Header:jpeq_hdr];
		}
	}
	
	_offset_len = offset;
	
	return YES;
}
- (BOOL) AddData:(unsigned char*) data
			  Length:(int) len
{
	unsigned char* pdata = data;
	int            p_len = len;
	
	pdata += _offset_len;
	p_len -= _offset_len;
	
	if(_jp_data_len + p_len > MJPEG_FRAME_BUFF_MAX || p_len <0)
		return NO;
	
	memcpy(_jp_data+_jp_data_len,pdata,p_len);
	_jp_data_len += p_len;
	
	return YES;
}

- (unsigned char *) GetData:(int*) ret_len
{
	*ret_len = _jp_data_len;
	return _jp_data;
}

- (void) CleanData
{
	if(_jp_data_len == 0)
		return;
	memset(_jp_data,0,MJPEG_FRAME_BUFF_MAX);
	_jp_data_len = 0;
		
}

@end
