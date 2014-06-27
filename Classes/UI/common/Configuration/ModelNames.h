/*
 *  ModelNames.h
 *  NetVision Lite
 *
 *  Created by Yen Jonathan on 2011/7/11.
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
 
#define MODEL_NAME_TOTAL							14

#define MODEL_NAME_DONTCARE							0x0
#define MODEL_NAME_RC4021							0x1
#define MODEL_NAME_RC8021							0x2
#define MODEL_NAME_RC8061							0x3
#define MODEL_NAME_OC810							0x4
#define MODEL_NAME_OC821							0x5
#define MODEL_NAME_iCam								0x6
#define MODEL_NAME_DC402							0x7
#define MODEL_NAME_DC421							0x8
#define MODEL_NAME_NV812D							0x9
#define MODEL_NAME_NV412A							0xA
#define MODEL_NAME_NV842							0xB
#define MODEL_NAME_RC8221							0xC
#define MODEL_NAME_RC8120							0xD

// Device Features Comparisomn Table
/*------------------------------------------------------------------------------------------------------
 Model Name		P/T		RS-485	LED(W)	LED(IR)	D/N Switcher	I/O	H.264	MPEG-4	MJPEG
 ======================================================================================================== 
 RC4021			X		X		X		X		X				X	X		V		V
 --------------------------------------------------------------------------------------------------------
 RC8021			X		X		X		X		X				X	X		V		V
 -------------------------------------------------------------------------------------------------------- 
 RC8061			V		X		V		X		X				V	X		V		V
 --------------------------------------------------------------------------------------------------------
 RC8221			X		X		X		V		V				V	V		V		V
 --------------------------------------------------------------------------------------------------------
 OC810			X		X		X		V		V				X	V		V		V
 --------------------------------------------------------------------------------------------------------
 OC821			X		X		X		V		V				X	V		V		V
 --------------------------------------------------------------------------------------------------------
 DC402			X		X		X		V		V				V	X		V		V
 --------------------------------------------------------------------------------------------------------
 RC421			X		X		X		X		X				V	V		V		V
 --------------------------------------------------------------------------------------------------------
 iCam			X		X		X		V		X				X	V		V		V
 --------------------------------------------------------------------------------------------------------
 NV812D			X		V		X		X		X				V	V		V		V
 --------------------------------------------------------------------------------------------------------
 NV412A			X		V		X		X		X				V	X		V		V
 --------------------------------------------------------------------------------------------------------
 NV842			X		V		X		X		X				V	V		V		V
 -------------------------------------------------------------------------------------------------------- 
 RC8120			X		X		X		X		X				X	V		V		V
--------------------------------------------------------------------------------------------------------*/


// Model nameand associated extension feature definition
#define DEVICE_EXTENSION_PT									0x1
#define DEVICE_EXTENSION_RS485								0x2
#define DEVICE_EXTENSION_LED_W								0x4
#define DEVICE_EXTENSION_LED_IR								0x8
#define DEVICE_EXTENSION_DNS								0x10
#define DEVICE_EXTENSION_IO									0x20
#define DEVICE_EXTENSION_STREAM_TYPE_MJPEG					0x40
#define DEVICE_EXTENSION_STREAM_TYPE_MPEG4					0x80
#define DEVICE_EXTENSION_STREAM_TYPE_H264					0x100










