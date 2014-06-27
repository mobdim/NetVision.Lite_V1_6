//
//  DataCenter.h
//  TerraUI
//
//  Created by ISBU Joseph Huang on 2011/2/14.
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
#import "ServerInfo.h"
#import <CommonCrypto/CommonDigest.h>//Calculating MD5 hash with the iPhone SDK
#import "Base64.h"

#import "ParserDeviceInfo.h"
#import "ParserClipInfo.h"
#import "ParserEventInfo.h"
#import "ParserObj.h"
#import "ParserArm.h"
#import "TerraUIAppDelegate.h"


//define the return code
typedef enum _returnCode
{
	NO_ERROR,
	ERROR_LOGON_FAIL
}returnCode;

typedef enum _MobileWorkMode {
	Mobile_P2P,
	Mobile_Server
	
}MobileWorkMode;

typedef enum _MobileNetworkType {
	
	MB_NETWORK_NONE = 0,
    MB_NETWORK_WIFI,		
	MB_NETWORK_3G,			
	
}MobileNetworkType;


typedef enum _MobilePlayType {
	
	MB_MJPEG = 0,
    MB_MP4,		
	MB_H264,			
	
}MobilePlayType;

@interface DataCenter : NSObject {//<ParserDelegate>{
	
	//variable(s)
	// logon return for CGI command used
	
	ServerInfo *TerraInfo;
	
	NSString *m_userName;
	NSString *m_userToken;
	
	int m_nDeviceType;//0:camera, 1:NVR 2:sensor
		
	//NSMutableArray *cameraList;	//camera List
	//NSMutableArray *NVR_List;	//NVR List
	//NSMutableArray *sensorList;	//sensor List
	NSMutableArray *clipList;
	NSMutableArray *eventList;
	//NSMutableArray *accountList;
	//NSMutableArray *homeAutomationList;//Home automation List
	//NSMutableArray *sceneList;//scene List
	NSMutableArray *objectClusterList;//object/cluster list
	NSMutableArray *deviceList;
	
	//NSString *armStatus;
	
	//int nTotalDeviceCount;
	//int nTotalClipCount;
	//int nTotalEventCount;
	//int nTotalAccountCount;
	//int max;
	
	//status Response
	//NSString* m_strResponse;
	
	//Parser
	//Parser *m_parser;
	
	//store the server's info
	
	int mobileMode;
	BOOL cfgReload;
	
	int playType;
}

@property (nonatomic, retain) ServerInfo *TerraInfo;
@property (nonatomic, retain) NSString *m_userName;
@property (nonatomic, retain) NSString *m_userToken;
@property (nonatomic) BOOL cfgReload;
//@property (nonatomic, retain) NSString *m_strResponse;

//function(s)
#pragma mark ==== Initialization ====
- (returnCode) Initialization;

#pragma mark ==== Terra Server related====
- (NSError*)ConnecttoServer;
//Before get the device list, we need to connect to Terra server, so we need to set username/password/port/https....
// 
// [in]  serverIP: (NSString)
// [in]  serverPort: (int)
// [in]  serverAccountName: (NSString)
// [in]  serverPassword: (NSString)
// [in]  protocol: (protocolType)
// [out]	returnCode
- (void) SetCMSServerInfo: (NSString *)serverIP 
					   withPort: (int)serverPort 
				   withUsername: (NSString *)serverAccountName 
				   withPassword: (NSString *)serverPassword 
				   withProtocol: (protocolType)protocol;

//get Terra server's IP
// 
// [in]  void
// [out]	server's IP: (NSString)
- (NSString *) GetServerIP;


//get Terra server's Account
// 
// [in]  void
// [out]	server's Account: (NSString)
- (NSString *) GetServerAccount;
- (void)Logoff;
- (BOOL)setUserDeviceList:(NSMutableArray*)deviceListArray;
-(NSMutableArray*)getUserDeviceList;

#pragma mark ==== HTTP/HTTPS request ====
- (NSData *) syncHttpsRequest:(NSString *) inUrl errorCode: (NSError **) error;
- (NSData *) syncHttpsRequestViaPost: (NSString *) inUrl
						withPostData: (NSString *) PostData;

//get returned Header Field Value via POST
//
// (return the value of header field when given a specific key)
//
- (NSData *) getHttpResponseHeaderFieldValueViaPost: (NSString *) inUrl														  
									   withPostData: (NSString *) PostData
											 forKey: (NSString *) key
										  errorCode: (NSError **) error;

#pragma mark ==== Device ====
//Get Terra server mode's device list
// 
// [in]  deviceType: (int)
//					0 DEVICE_CAMERA
//					1 DEVICE_SERVER
//					2 DEVICE_SENSOR
// [in]  deviceSubType: (int)		<reserved>
// [in]  retrievingCount: (int)
// [out]	device list:	 (the returned data structure: DeviceInfo class)
- (NSMutableArray *) GetDeviceList: (int)deviceType 
					   withSubType: (int)deviceSubType 
			   withRetrievingCount: (int)retrievingCount;

#pragma mark ==== Clip =====
//Get Clip List with specific query: deviceID /startTime /endTime /direction /clipType /clipSubType /maxCount
// 
// [in]  deviceID: (NSString)
// [in]  startTime: (NSString)		<format:YYYYMMDDHHMMSS, ex:20110225164123>
// [in]  endTime: (NSString)		<format:YYYYMMDDHHMMSS, ex:20110225164123>
// [in]  direction: (int)
//					0: CASE asc
//					1: CASE desc
// [in]  clipType: (int)
//				case 0x04: // di->input port trigger
//				case 0x20: // audio->audio trigger
//				case 0x02: // motion-> motion trigger
//				case 0x08: // pir-> pir trigger
//				case		: // httpc-> HTTP CGI client trigger
//				case 0x10: // rf->RF sensor trigger
//				case		: // femto->Femto cell event trigger
// [in]  clipSubType: (int)			<reserved>
// [in]  startIndex: (int)
// [in]  retrievingCount: (int)
// [out]	Clip list:	 (the returned data structure: ClipInfo class)
- (NSMutableArray *) GetClipListWithID: (NSString *)deviceID 				   
						 withStartTime: (NSString *)startTime				   
						   withEndTime: (NSString *)endTime 					 
						 withDirection: (int)direction 						
							  withType: (int)clipType 						   
						   withSubType: (int)clipSubType						
						withStartIndex: (int)startIndex					  
				   withRetrievingCount: (int)retrievingCount;


#pragma mark ==== Event =====
//Get Event List with specific query: 
// 
// [in]  duration: (NSString)	<format:A,B[,C]		ex: (1)YYYYMMDDHHMMSS,-,asc    (2)-,YYYYMMDDHHMMSS,desc>
// [in]  deviceIDFlag: (BOOL)	-> define the parameter "dev_id" if is valid
// [in]  deviceID: (NSString)	<format:A				ex: 00C0022EOCDC>
// [in]  numberFlag: (BOOL)		-> define the parameter "number" if is valid
// [in]  number: (NSString)		<format:A,B			ex: 1,50>
// [in]  typeFlag: (BOOL)		-> define the parameter "type" if is valid
// [in]  type: (NSString)		<format:A[,B,...]		ex: di,audio,motion,pir,httpc,rf,femto>
// [in]  whereFlag: (BOOL)		-> define the parameter "where" if is valid
// [in]  where: (NSString)		<format:A				ex: di1/windowName/IP/sensorID/phoneNumber>
// [in]  clipFlag: (BOOL)		-> define the parameter "clip" if is valid
- (NSMutableArray *) GetEventListWithDuration: (NSString *)duration 									 
								 DeviceIDFlag: (BOOL)deviceIDFlag 	 
									 DeviceID: (NSString *)deviceID 									 
								   NumberFlag: (BOOL)numberFlag 
									   Number: (NSString *)number 
									 TypeFlag: (BOOL)typeFlag
										 Type: (NSString *)type	
									WhereFlag: (BOOL)whereFlag 	
										Where: (NSString *)where
									 ClipFlag: (BOOL)clipFlag;

#pragma mark ==== 1.2.1.1 CGI Relay ====
- (NSError*)cgiRelay:(NSString*)beacon cmd:(NSString*)command;
#pragma mark ==== 1.2.7 Scene, Notification and Automation ====
#pragma mark ==== 1.2.7.1 Object/Cluster (Z-Wave/ZigBee/RF) Control ====
- (NSMutableArray*)GetObjListWithDevice: (NSString*)dev_id errorCode:(NSError **)error;
#pragma mark ==== 1.2.7.2 Arm/Disarm ====
//Arm/Disarm Action: 
// 
// [in]  action: (NSString)			<format:string		
//									ex: arm(default), disarm, qam, qdisarm, get, set
// [in]  password: (NSString)		<Protection code for arm/disarm, mandatory for arm/disarm action, up to 256 ASCII charaters>
// [in]  oldPasswordFlag: (BOOL)		-> define the parameter "oldPassword" if is valid
// [in]  oldPassword: (NSString)	<Optional, only valid for set action, 
//										OLD protection code for arm/disarm, mandatory for arm/disarm action, up to 256 ASCII charaters
//										NOTES: oldPassword is mandatory if modify the password>
// [in]  qpassword: (NSString)		<Protection code for qarm/qdisarm, mandatory for arm/disarm action, up to 256 ASCII charaters>
// [in]  oldQPasswordFlag: (BOOL)		-> define the parameter "oldQPassword" if is valid
// [in]  oldQPassword: (NSString)	<Optional, only valid for set action, 
//										OLD protection code for qarm/qdisarm, mandatory for qarm/qdisarm action, up to 256 ASCII charaters
//										NOTES: oldQPassword is mandatory if modify the password>
// [out] status: (NSString) Response status
//				ok 
//				error 
//				wrong-pass: the old_password is wrong
//				armed
//				disarmed
- (NSString *) ArmAction: (NSString *)action 				 							 
			  Password: (NSString *)password 									 						   
	   OldPasswordFlag: (BOOL)oldPasswordFlag 
		   OldPassword: (NSString *)oldPassword				 
			  QPassword: (NSString *)qpassword 									 
	   OldQPasswordFlag: (BOOL)oldQPasswordFlag 
		   OldQPassword: (NSString *)oldQPassword;

#pragma mark ==== 1.2.7.3 Notification and Automation (Home Automation) ====
//Get Home Automation List with specific query: 
// 
// [in]  nameFlag: (BOOL)	-> define the parameter "name" if is valid
// [in]  name: (NSString)	<Optional, scence name, up to 256 ASCII charaters. For multiple, format:A[,A,A,...]>
- (NSMutableArray *) GetHomeAutomationListWithNameFlag: (BOOL)nameFlag 	 
												  Name: (NSString *)name;
//Home Automation Configuration: 
// 
// [in]  action: (NSString)			<format:string		
//									ex: add(default), delete, modify
// [in]  password: (NSString)		<¢Þlease refer to the relative parameters defined in XML element of esma_query.cgi.
//									For add action, all are mandatory;
//									For delete action, only name is mandatory.>
//
//								name
//								schedule_mode
//								schedule_days
//								schedule_duration
//								by_ip_dev_id
//								by_ip_dev_type
//								by_condition
//								control_ip_dev_id
//								control_ip_dev_type
//								sensor_id
//								sensor_value
//								capture_file
//								capture_duration
//								email_to
//								email_subject
//								email_content
//								sms_number
//								sms_message
// [out] status: (NSString) Response status
//				ok 
//				error 
//				name-existing -> For add action
//				not-existing -> For delete/modify actions
- (NSString *) HomeAutomationAction: (NSString *)action 				 							 
					ParameterString: (NSString *)parameterString;



#pragma mark ==== 1.2.7.4 Scene ====
//Get Scene List with specific query: 
// 
// [in]  nameFlag: (BOOL)	-> define the parameter "name" if is valid
// [in]  name: (NSString)	<Optional, scence name, up to 256 ASCII charaters. For multiple, format:A[,A,A,...]>
- (NSMutableArray *) GetSceneListWithNameFlag: (BOOL)nameFlag 	 												
										 Name: (NSString *)name;


// Scene Configuration: 
// 
// [in]  action: (NSString)			<format:string		
//									ex: add(default), delete, modify
// [in]  password: (NSString)		<¢Þlease refer to the relative parameters defined in XML element of query.cgi.
//									For add action, all are mandatory;
//									For delete action, only name is mandatory.>
//
//								name
//								mode
//								control_ip_dev_id
//								control_ip_dev_type
//								sensor_id
//								sensor_value
//								capture_file
//								capture_duration
//								email_to
//								email_subject
//								email_content
//								sms_number
//								sms_message
// [out] status: (NSString) Response status
//				ok 
//				error 
//				name-existing -> For add action
//				not-existing -> For delete/modify actions
- (NSString *) SceneAction: (NSString *)action 				 							 					
		   ParameterString: (NSString *)parameterString;


//Get Scene List with specific query: 
// 
// [in]  name: (NSString)	<Optional, scence name, up to 256 ASCII charaters. For multiple, format:A[,A,A,...]>
// [out] status: (NSString) Response status
//				ok 
//				error 
//				no-existing
//				disabled
- (NSString *) SceneTriggerWithName: (NSString *)name;



#pragma mark ==== 1.2.7.5 SMS ====
// Scene Configuration: 
// 
// [in]  phone: (NSString)			<Phone number which the message will be send to. For multiple, format:A[,A,A,...]>
// [in]  message: (NSString)		<Message content, encodeed in base64, max length depends on ISP>
// [out] status: (NSString) Response status
//				ok 
//				error
- (NSString *) SMS_withPhone: (NSString *)phone
					 Message: (NSString *)message;
/*
- (NSData *) getHttpResponseHeaderFieldValueViaPost: (NSString *) inUrl														  
									   withPostData: (NSString *) PostData
											 forKey: (NSString *) key;
*/
- (int)  getMobileMode;
- (void) setMobileMode: (int) mode;

- (NSMutableArray *) GetDeviceListWithRefresh: (BOOL*) bRefresh
								  withDevType: (int)deviceType 
								  withSubType: (int)deviceSubType 
						  withRetrievingCount: (int)retrievingCount;

- (MobileNetworkType) isConnectToNetworkWithMsg:(BOOL) bShow;

- (BOOL) isReachableHttpURL: (NSURL*) url;


@end
