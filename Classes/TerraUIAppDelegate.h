//
//  TerraUIAppDelegate.h
//  TerraUI
//
//  Created by Shell on 2011/1/6.
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

#import <UIKit/UIKit.h>
#import "loginView.h"
#import "NAVController.h"
#import "DataCenter.h"
#import "LiveImageController.h"

@class loginView;
@class DataCenter;
@interface TerraUIAppDelegate : NSObject 
<UIApplicationDelegate,UITabBarControllerDelegate > 
{
    UIWindow *window;
	IBOutlet UIView *logoView;
    IBOutlet UITabBarController *tabBarController;
	IBOutlet NAVController *playbackNAVController;
	IBOutlet NAVController *liveviewController;
	//IBOutlet NAVController *LiveImageController;
	IBOutlet NAVController *eventController;
	IBOutlet NAVController *P2PconfigureController;
	IBOutlet UIViewController *aboutController;
	loginView *loginViewer;
	BOOL demoUIMode;
	DataCenter *dataCenter;
	// Jonathan added
	// notification	
	int liveViewON;
	NSMutableDictionary *notifyDictionary;	
	
	// nash add
	LiveImageController* LiveVw;
	
}
-(void)waitLive;
-(void)switchtoLoginView:(NSTimer*)timer;
-(void)switchtoP2P;
-(void)switchtoTabView:(BOOL)UImode account:(NSString*)Account password:(NSString*)Password IP:(NSString*)ip port:(NSString*)Port;
@property (nonatomic, retain) LiveImageController * LiveVw;
@property (nonatomic, retain) IBOutlet UIView *logoView;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) IBOutlet NAVController *playbackNAVController;
@property (nonatomic, retain) IBOutlet NAVController *liveviewController;
//@property (nonatomic, retain) IBOutlet NAVController *LiveImageController;
@property (nonatomic, retain) IBOutlet NAVController *eventController;
@property (nonatomic, retain) IBOutlet NAVController *P2PconfigureController;
@property (nonatomic, retain) loginView *loginViewer;
@property (nonatomic) BOOL demoUIMode;
@property (nonatomic, retain) DataCenter *dataCenter;
// Jonathan added
@property(nonatomic, assign) int liveViewON;
@property(nonatomic, retain) NSMutableDictionary *notifyDictionary;

@end
