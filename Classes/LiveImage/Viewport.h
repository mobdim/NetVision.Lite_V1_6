//
//  Viewport.h
//  HypnoTime
//
//  Created by Yen Jonathan on 2011/4/13.
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

#import <UIKit/UIKit.h>
#import "Streaming.h"

#define VIEW_TITLE_BAR_POSITION_NONE						0
#define VIEW_TITLE_BAR_POSITION_BOTTOM						1
#define VIEW_TITLE_BAR_POSITION_TOP							2

#define MARGIN_BETWEEN_VIEWPORT								5	// unit: pixel
#define LABEL_MARGIN										0	// unit: pixel
#define LABEL_HEIGHT										15	// unit: pixel

#define MARGIN_PAGE_CONTROL									2	// unit: pixel

#define STATUS_POSITION_PORTION								2	// put status at viewport center
#define STATUS_HEIGHT										30	// status area height, unit: pixel

#define PAN_TILT_BUTTON_NUM									5
#define PAN_TILT_LEFT										1
#define PAN_TILT_UP											2
#define PAN_TILT_RIGHT										3
#define PAN_TILT_DOWN										4
#define PAN_TILT_HOME										5
#define PAN_TILT_BTN_SIDE									60	// unit: pixel
#define PAN_TILT_MARGIN										2	// unit:pixel

#define INDICATOR_SIDE_WIDTH								20	// unit: pixel
#define BADGE_SIDE_WIDTH									31	// unit: pixel

#define RUN_MODE_FOCAL_PORT									1
#define RUN_MODE_NON_FOCAL									2

// control label On-Off indicator bit definition
#define CONTROL_LABEL_VIEWPORT_TITLE						0x1
#define CONTROL_LABEL_VIEWPORT_STATUS						0x2


@interface Viewport : UIImageView <StreamingProtocol>
{
	//
	// the viewport's property, 'tag', will be used to indicate the following:
	//		1. the position of its associated device data in DeviceCatch array
	//		2. the layout mapping
	// Thus, the layout mapping is done according to the DeviceCache array's object order
	//
	NSString *title;
	int titleBarPosition;
	UILabel *titleView;
	
	BOOL initialLayoutDone;
	
	int status;
	UILabel *statusView;
	
	NSMutableArray *pantiltView;
	int panTiltTouchedDirection;
	// pan/tilt icon on/off monitor timer
	double ptIconONTimeRef;
	NSTimer *watchdogTimerPTIconOFF;
		
	UIImage *snapshot;
	CGRect imageRect;
	
	// notification
	NSMutableDictionary *notifyDictionary;
	int runMode;	// cocal/non-focal modes
	int serverMode;	// P2P/Server modes
	
	// slide thumbnail array up/down indicator
	BOOL slideThumbnailUp;
	
	// pre image saving time
	double preImageSavingTime;
	
	// streaming control
	UIActivityIndicatorView *actionIndicator;
	int indicatorCount;
	Streaming *streaming;
	
	// the control labels(title, status, etc) On-Off indicators
	int controlLabelsOnOff;
	
	// to remember the streaming condition
	BOOL streamTerminated;

}

@property(nonatomic, retain) NSString *title;
@property(nonatomic, retain) UILabel *titleView;
@property(nonatomic, assign) int titleBarPosition;
@property(nonatomic, retain) UIImage *snapshot;
@property(nonatomic, assign) CGRect imageRect;
@property(nonatomic, assign) int status;
@property(nonatomic, retain) UILabel *statusView;
@property(nonatomic, retain) NSMutableArray *pantiltView;
@property(nonatomic, assign) int panTiltTouchedDirection;
@property(assign) double ptIconONTimeRef;
@property(nonatomic, assign) NSTimer *watchdogTimerPTIconOFF;
@property(nonatomic, assign) BOOL initialLayoutDone;
@property(nonatomic, retain) NSMutableDictionary *notifyDictionary;
@property(nonatomic, assign) int runMode;
@property(nonatomic, assign) int serverMode;
@property(nonatomic, assign) BOOL slideThumbnailUp;
@property(assign) double preImageSavingTime;
@property(nonatomic, retain) UIActivityIndicatorView *actionIndicator;
@property(nonatomic, assign) int indicatorCount;
@property(nonatomic, retain) Streaming *streaming;
@property(nonatomic, assign) int controlLabelsOnOff;
@property(nonatomic, assign) BOOL streamTerminated;


+(id)viewportCreationWithLocation:(CGRect)location inLabel:(NSString*)title assignedIndex:(NSInteger)index associatedServer:(int)server;
-(void)doInternalLayout:(NSInteger)mode;
-(void)labelLayout:(NSInteger)mode;
-(void)statusLayout;
-(void)pantiltLayout;
-(void)indicatorLayout;

-(void)labelOnOff:(BOOL)on;
-(void)resetStreamingStatus;
-(void)showStatus;
-(void)notifyViewportPanTilt:(NSNotification*)aNote;
-(void)createIconOffTimer;
-(void)ptIconMonitor:(NSTimer*)timer;
-(void)asyncHttpsRequest:(NSString*)inUrl;

-(void)clean;
-(void)updateViewportSnapshot:(UIImage*)img;

-(void)startIndicator;
-(void)stopIndicator;

-(void)prepareViewportDisplayModeChange;


-(void)showActivityIndicator;
-(BOOL)DeviceReachabilityCheck;

@end
