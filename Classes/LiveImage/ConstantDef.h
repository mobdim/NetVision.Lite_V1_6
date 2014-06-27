/*
 *  ConstantDef.h
 *  HypnoTime
 *
 *  Created by Yen Jonathan on 2011/5/1.
 /*
 * Copyright c 2010 SerComm Corporation. 
 * All Rights Reserved. 
 *
 * SerComm Corporation reserves the right to make changes to this document without notice. 
 * SerComm Corporation makes no warranty, representation or guarantee regarding the suitability 
 * of its products for any particular purpose. SerComm Corporation assumes no liability arising 
 * out of the application or use of any product or circuit. SerComm Corporation specifically 
 * disclaims any and all liability, including without limitation consequential or incidental 
 * damages; neither does it convey any license under its patent rights, nor the rights of others.
 */


// application operation mode
#define RUN_P2P_MODE												0
#define RUN_SERVER_MODE												1

// zooming rate
#define ZOOM_RATE_MIN												1.0
#define ZOOM_RATE_MAX												16.0

// maximum allowable device number
#define MAXIMUM_ALLOWABLE_DEVICE_NUMBER								16

// device status
// These status codes are for UILabel status display
#define DEVICE_STATUS_ONLINE										0	// no error
#define DEVICE_STATUS_PREPARE_FOR_ONLINE							0
#define DEVICE_STATUS_OFFLINE										1
#define DEVICE_STATUS_PAUSED										2
#define DEVICE_STATUS_STOPPED										3
#define DEVICE_STATUS_ERROR											4
#define DEVICE_STATUS_SESSION_FAILURE								6
#define DEVICE_STATUS_SESSION_RX_DATA_CORRUPTION					7
#define DEVICE_STATUS_POOR_NETWORK_CONDITION						8
#define DEVICE_STATUS_DATA_RX_ERROR_AFTER_SESSION_SETUP				9
#define DEVICE_STATUS_SOCKET_FAILURE								10
#define DEVICE_STATUS_DEVICE_NOT_FOUND								11
#define DEVICE_STATUS_DEVICE_RESPONSE_ERROR							12
#define DEVICE_STATUS_DECODER_NOT_FOUND								20
#define DEVICE_STATUS_NO_DEVICE_ASSOCIATED							99
#define DEVICE_STATUS_BAD_REQUEST									400
#define DEVICE_STATUS_AUTHENTICATION_ERROR							401
#define DEVICE_STATUS_REQUEST_FORBIDDEN								403
#define DEVICE_STATUS_SERVICE_NOT_FOUND								404
#define DEVICE_STATUS_REQUEST_FORMAT_ERROR							406
#define DEVICE_STATUS_REQUEST_TIMEOUT								408
#define DEVICE_STATUS_INTERNAL_SERVER_ERROR							500
#define DEVICE_STATUS_SERVER_NO_SERVICE								501
#define DEVICE_STATUS_SESSION_NOT_AVAILABLE							503
#define DEVICE_STATUS_SERVICE_TIMEOUT								504
#define DEVICE_STATUS_HTTP_VERSION_ERROR							505

// These status codes are used to identified the status of a streaming session
// Use these codes to avoid unnecessary repeated stop/play request
#define STREAM_SESSION_STATUS_STOP									0	// tear down done
#define STREAM_SESSION_STATUS_TEAR_DOWN_ONGOING						1
#define STREAM_SESSION_STATUS_SETUP_ONGOING							2
#define STREAM_SESSION_STATUS_PLAY									3	// playing
#define STREAM_SESSION_STATUS_PAUSED								4	// paused
#define STREAM_SESSION_STATUS_UNKNOWN								8	// unknow

// image codec
#define IMAGE_CODEC_MJPEG											0
#define IMAGE_CODEC_MPEG4											1
#define IMAGE_CODEC_H264											2
#define IMAGE_CODEC_CH1												11
#define IMAGE_CODEC_CH2												12
#define IMAGE_CODEC_CH3												13
#define IMAGE_CODEC_CH4												14

// timer timout value
//#define TIME_PERIOD_MAX_PT_ICON_ON								1000000	// unit:us
#define TIME_PERIOD_MAX_PT_ICON_ON									1	// unit:s
#define TIME_PERIOD_IMAGE_SAVING									1	// unit:s	
#define TIME_PERIOD_STREAMING_TIMEOUT								8	// unit:s
#define TIME_PERIOD_SESSION_BACK_TO_READY							5000000	// unit:us
#define TIME_PERIOD_MAX_THREAD_EXIT_TIMEOUT							2	// unit: s
#define PROTOCOL_REQUEST_TIMEOUT									20	// unit:s

// frame resolution
#define FRAME_RESOLUTION_WIDTH_DEFAULT								320
#define FRAME_RESOLUTION_HEIGHT_DEFAULT								240

// streaming rx retry count
#define CONNECTION_RETRY_COUNT_MAX									5

// z-position for Viewports on a page
#define Z_POSITION_MIN_ON_PAGE										-200
#define Z_POSITION_MAX_ON_PAGE										0
#define Z_POSITION_DELTA_ON_PAGE									10



#define KNotifyTag											@"focalTag"
#define NOTIFICATION_VIEWPORT_TOUCHED						@"NotifyViewportTouched"

#define KNotifyPanTilt										@"panTiltTag"
#define NOTIFICATION_VIEWPORT_PAN_TILT						@"NotifyViewportPanTilt"

#define KNotifySlideThumbnailTreatment						@"slideThumbnailTag"
#define NOTIFICATION_SLIDE_THUMBNAIL_TREATMENT				@"NotifySlideThumbnailTreatment"

#define KNotifyLiveViewOnOff								@"liveViewOnOffTag"
#define NOTIFICATION_LIVEVIEW_ON_OFF						@"NotifyliveViewOnOff"

#define KNotifyLiveViewPageChanged							@"liveViewPageChangedTag"
#define NOTIFICATION_LIVEVIEW_PAGE_CHANGED					@"NotifyliveViewPageChanged"
