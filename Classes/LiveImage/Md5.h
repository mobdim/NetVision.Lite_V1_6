//
//  Md5.h
//  socketest
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

#import <Foundation/Foundation.h>

/* POINTER defines a generic pointer type */
typedef unsigned char*		POINTER;
/* UINT2 defines a two byte word */
typedef unsigned short int	UINT2;
/* UINT4 defines a four byte word */
typedef unsigned long int	UINT4;


#define		LENGTH			16

/* MD5 context. */
typedef struct {
	UINT4 state[4]; /* state (ABCD) */
	UINT4 count[2]; /* number of bits, modulo 2^64 (lsb first) */
	unsigned char buffer[64]; /* input buffer */
} MD5_CTX;


void MD5Init(MD5_CTX* context);
void MD5Update(MD5_CTX* context, unsigned char* input, unsigned int inputLen);
void MD5Final(unsigned char* digest, MD5_CTX* context);

char* MD5HexToChar(MD5_CTX* ctx, char* buf);
char* EncodeMD5Data(unsigned char *data, unsigned int len, char *buf);