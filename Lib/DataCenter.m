//
//  DataCenter.m
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


#import <SystemConfiguration/SCNetworkReachability.h>
#import <netinet/in.h>
#import <CFNetwork/CFNetwork.h>
#import "DataCenter.h"


//data center lock
static NSString *g_device_lock = @"devicelock";
static NSString *g_clip_lock   = @"cliplock";
static NSString *g_event_lock  = @"eventlock";
static NSString *g_obj_lock    = @"objlock";
static NSString *g_arm_lock    = @"armlock";

@implementation DataCenter

@synthesize TerraInfo;
@synthesize m_userName,m_userToken;
@synthesize cfgReload;

#pragma mark ==== Initialization ====

//function(s)
//Initialization..
- (returnCode) Initialization
{	
	
	
	deviceList = nil;
	clipList   = nil;
	eventList  = nil;
	objectClusterList = nil;//object/cluster list
	TerraInfo = nil;
	cfgReload = NO;	
	mobileMode = Mobile_P2P; // load key!!! not yet
	return NO_ERROR;
}


#pragma mark ==== MD5 related functions====
//Before get the device list, we need to connect to Terra server, we need to get "None" string according to spec.
// 
// [in]  null
// [out]	return None's Code string
- (NSString *) generateNone
{
	//NSString *strRandom = @"1234567890qwertyuiopasdfghjklzxcvbnm";
	NSString *strRandom = [[NSString alloc] initWithFormat:@"1234567890qwertyuiopasdfghjklzxcvbnm"];
	NSString *strNone;
	
	srandom(time(NULL));//setting random seed
	
	char chars[10];
	
	for (int i=0 ; i<10 ; i++) {
		chars[i] = [strRandom characterAtIndex:random()%[strRandom length]];
	}
	strNone = [[[NSString alloc] initWithBytes:chars							 
									   length:10
									 encoding:NSUTF8StringEncoding] autorelease];
    [strRandom release];
	return strNone;
}


//Before get the device list, we need to connect to Terra server, we need to get MD5 string
// 
// [in]  source: (NSString)
// [out]	returnMD5Code: (NSString *)
- (NSString *)getMD5FromString:(NSString *)source
{
	if(!source) 
		return nil;
	const char *src = [source UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5(src, strlen(src), result);
    NSString *ret =  [[[NSString alloc] initWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
					  result[0], result[1], result[2], result[3],
					  result[4], result[5], result[6], result[7],
					  result[8], result[9], result[10], result[11],
					  result[12], result[13], result[14], result[15] ]autorelease];
	
	return [ret lowercaseString];
}

#pragma mark ==== string functions====

//A,B.C => input(,.) => B
- (NSString *)getSubstring:(NSString *)mainString startString:(NSString *)startString endString:(NSString *)endString
{	
	if(!startString || !endString)
		return nil;
	NSRange textRange;	
	NSString *result;
	int begin = -1, end = -1;
	
	textRange = [mainString rangeOfString:startString];
	begin = textRange.location + textRange.length;
	
	NSRange endRange;	
	endRange = [[mainString substringFromIndex:begin] rangeOfString:endString];
	
	
	if(textRange.location != NSNotFound && endRange.location != NSNotFound)
	{
		end = endRange.location;
		
		result = [mainString substringWithRange:NSMakeRange(begin, end)];
	}
	else
		result = [NSString stringWithFormat:@""];
	
	return result;
	
}

#pragma mark ==== Terra Server related====
//Connect to server
// [out]	returnCode 
- (NSError*)ConnecttoServer
{
	//logoff first
	[self Logoff];
	
	//if user check Cancel, it will not connect to server , show the UI only
	TerraUIAppDelegate *appDelegate =  (TerraUIAppDelegate *)[[UIApplication sharedApplication]delegate];
	if (appDelegate.demoUIMode) 
	{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"" forKey:NSLocalizedDescriptionKey];
		//UI mode
		NSError *ui_mode = [NSError errorWithDomain:NSURLErrorDomain
															   code:3
														   userInfo:userInfo];
		return ui_mode;
	}
	
	if(TerraInfo != nil)
		[TerraInfo release];
	
	
	TerraInfo = [[ServerInfo alloc] initWithServerIP:[[NSUserDefaults standardUserDefaults] stringForKey:@"ServerIP"]
												Port:[[NSUserDefaults standardUserDefaults] integerForKey:@"Port"]
											Username:[[NSUserDefaults standardUserDefaults] stringForKey:@"UserName"]
											Password:[[NSUserDefaults standardUserDefaults] stringForKey:@"Password"]
											Protocol:[[NSUserDefaults standardUserDefaults] integerForKey:@"Protocol"]];
	
	//1. Logon
	NSString *strURL    = [[NSString alloc] initWithFormat:@"http://%@/cgi/logon.php",TerraInfo.serverIP];
	NSString *strNonce  = [self generateNone];
	NSString *strSvrMD5 = [self getMD5FromString:TerraInfo.serverPassword];
	NSString *strKey    = [[NSString alloc] initWithFormat:@"%@:%@:%@", TerraInfo.serverAccountName ,strSvrMD5, strNonce];
	NSString *strMD5    = [self getMD5FromString:strKey];
	NSString *strData   = [[NSString alloc] initWithFormat:@"username=%@&nonce=%@&key=%@",TerraInfo.serverAccountName, strNonce, strMD5]; 
	NSString *strFieldValue;
    
	
	//2. Account Logon Validation
	//3. Get Response
	//------------------------------------------------------------------------------------------------
	//get Http Response Header Field Value Via Post with the key "Set-Cookie"
	// to get the (A) username
	//			  (B) token string generated by server, random
	
	NSError *error = nil;
	strFieldValue = (NSString *)[self getHttpResponseHeaderFieldValueViaPost:strURL
																withPostData:strData
																	  forKey:@"Set-Cookie"
																   errorCode:&error];
	//NSLog(@"error message: %@",[error localizedDescription]);
	
		
		//4. General CGI Commands
		//5. Account Logon
		//6. Response
		
		self.m_userToken = [self getSubstring:strFieldValue				
								  startString:@"user_token="
									endString:@";"];
		
		self.m_userName = [self getSubstring:strFieldValue				
								 startString:@"user_name="
								   endString:@";"];
	
	
	
	
	[strURL    release];
	[strKey    release];
	[strData   release];
	
	//check if logon successfully
	if( ([m_userName length]<=0 || [m_userToken length]<=0) &&[error code] == 0)
	{
		//NSLog(@"id password error");
		//return ERROR_LOGON_FAIL;
		NSArray *objectArray = [[NSArray alloc] initWithObjects:@"Authentication error",@"Authentication error",nil];
		NSArray *keyArray = [[NSArray alloc] initWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey,nil];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objectArray
															 forKeys:keyArray];
		
        NSError *accountandPasswordError = [NSError errorWithDomain:NSURLErrorDomain
														 code:2
													 userInfo:userInfo];
		[objectArray release];
		[keyArray release];
		return accountandPasswordError;
	}
	
    return error;//no error
}

//Before get the device list, we need to connect to Terra server, so we need to set username/password/port/https....
// 
// [in]  serverIP: (NSString)
// [in]  serverPort: (int)
// [in]  serverAccountName: (NSString)
// [in]  serverPassword: (NSString)
// [in]  protocol: (protocolType)
- (void) SetCMSServerInfo: (NSString *)serverIP 
					   withPort: (int)serverPort 
				   withUsername: (NSString *)serverAccountName 
				   withPassword: (NSString *)serverPassword 
				   withProtocol: (protocolType)protocol
{
	[[NSUserDefaults standardUserDefaults] setObject:serverAccountName forKey:@"UserName"];
	[[NSUserDefaults standardUserDefaults] setObject:serverPassword forKey:@"Password"];
	[[NSUserDefaults standardUserDefaults] setObject:serverIP forKey:@"ServerIP"];
	[[NSUserDefaults standardUserDefaults] setInteger:serverPort forKey:@"Port"];
	[[NSUserDefaults standardUserDefaults] setInteger:protocol forKey:@"Protocol"];//0:HTTP 1:HTTPS
	//sync the defaults to disk
	[[NSUserDefaults standardUserDefaults] synchronize];
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"dateKey"];
	
}

//get Terra server's IP
// 
// [in]  void
// [out]	server's IP: (NSString)
- (NSString *) GetServerIP
{
	return [TerraInfo serverIP];
}

//get Terra server's Account
// 
// [in]  void
// [out]	server's Account: (NSString)
- (NSString *) GetServerAccount
{
	return [TerraInfo serverAccountName];
}


//Logoff
- (void)Logoff
{
	NSError *error=nil;
	NSString *serverip = [[NSUserDefaults standardUserDefaults] stringForKey:@"ServerIP"];
	[self syncHttpsRequest:[[[NSString alloc] initWithFormat:@"http://%@/cgi/logoff.php",serverip]autorelease] 
				 errorCode:&error];
}

- (BOOL)setUserDeviceList:(NSMutableArray*)deviceListArray
{
	NSMutableArray *NSdataDeviceArray = [[NSMutableArray alloc] init];
	for (id obj in deviceListArray) 
	{
		NSData *objData = [NSKeyedArchiver archivedDataWithRootObject:obj];
		[NSdataDeviceArray addObject:objData];
	}
	[[NSUserDefaults standardUserDefaults]setObject:NSdataDeviceArray forKey:@"UserDeviceList"];
	//sync the defaults to disk
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"dateKey"];
	[NSdataDeviceArray release];
	BOOL settingOK = [[NSUserDefaults standardUserDefaults] synchronize];
	return settingOK;
}

-(NSMutableArray*)getUserDeviceList
{
	NSMutableArray* devList =(NSMutableArray*)[[NSUserDefaults standardUserDefaults] arrayForKey:@"UserDeviceList"];
	NSMutableArray *userDefArray = [[NSMutableArray alloc] init];
	for (NSData *dataObj in devList) 
	{
		id userDefObj = [NSKeyedUnarchiver unarchiveObjectWithData:dataObj];
		[userDefArray addObject:userDefObj];
	}
	
	
	return [userDefArray autorelease];
}

#pragma mark ==== HTTP/HTTPS request ====

//get GET return data
- (NSData *) syncHttpsRequest:(NSString *) inUrl errorCode: (NSError **)error
{
	
	NSData *urlData;
	
	NSURL *url = [[NSURL alloc] initWithString:inUrl];
	
		//Old code <== using default header content
		//NSURLRequest *request = [NSURLRequest requestWithURL:url];	
	
		///New code	
		//
		//Modify specific field of response header according to FW spec.
		// Cookie: user_name=XXXX; user_token=1234567890...1234567890;\r\n
		//
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:url];
	[request setTimeoutInterval:15.0];

	//Real case:
	//NSLog(@"%@,%@",m_userName,m_userToken);
	NSString *strCookie = [[NSString alloc] initWithFormat:@"user_name=%@; user_token=%@;", self.m_userName,self.m_userToken];	
	[request setValue:strCookie forHTTPHeaderField:@"Cookie"];
	
	[[NSURLCache sharedURLCache] setMemoryCapacity:0]; // for leak
	[[NSURLCache sharedURLCache] setDiskCapacity:0];   // for leak
		
	NSHTTPURLResponse *response;
	NSError *errorCode = nil;	
	
	urlData = [NSURLConnection sendSynchronousRequest:request 
									returningResponse:&response 
												error:&errorCode];
	
	NSInteger httpStatus = [((NSHTTPURLResponse *)response) statusCode];
	NSLog(@"syncHttpsRequest responsecode:%d", httpStatus);

	 
	*error = errorCode;
	 
		// nash for leak : NSURLConnection sendSynchronousRequest will cache some buffer will cause leak
	[[NSURLCache sharedURLCache] removeAllCachedResponses];

	[url       release];
	[request   release];
	[strCookie release];
	
	return urlData;
}

//get POST return data
- (NSData *) syncHttpsRequestViaPost: (NSString *) inUrl
						withPostData: (NSString *) PostData 
{
	NSData *urlData;
		NSURL *url = [[NSURL alloc] initWithString:inUrl];
		NSData *postData = [ PostData dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
		NSString *postLength = [[NSString alloc] initWithFormat:@"%d", [postData length]];
		
		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
		[request setURL:url];
		[request setHTTPMethod:@"POST"];
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
		[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody:postData];
	
		[[NSURLCache sharedURLCache] setMemoryCapacity:0]; // nash for leak
		[[NSURLCache sharedURLCache] setDiskCapacity:0];   // nash for leak

		NSHTTPURLResponse *response;
		NSError *error =nil;	
		urlData = [NSURLConnection sendSynchronousRequest:request 
										returningResponse:&response 
													error:&error];
	
		NSInteger httpStatus = [((NSHTTPURLResponse *)response) statusCode];
		NSLog(@"syncHttpsRequest responsecode:%d", httpStatus);
		 // nash for leak : NSURLConnection sendSynchronousRequest will cache some buffer will cause leak
		[[NSURLCache sharedURLCache] removeAllCachedResponses];
	
	
		
		[url		release];
		[postLength release];
		[request	release];
    
	return urlData;	
}

//get returned Header Field Value via POST
//
// (return the value of header field when given a specific key)
//
- (NSData *) getHttpResponseHeaderFieldValueViaPost: (NSString *) inUrl														  
									   withPostData: (NSString *) PostData
											 forKey: (NSString *) key
										 errorCode: (NSError **) error
{
	NSData * retData;
		
		NSURL *url = [[NSURL alloc] initWithString:inUrl]; 
		NSData *postData = [ PostData dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	    NSString *postLength = [[NSString alloc] initWithFormat:@"%d", [postData length]];
		
		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
		[request setURL:url];
		[request setHTTPMethod:@"POST"];//[request setHTTPMethod:@"HEAD"];
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
		[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody:postData];
		
		[[NSURLCache sharedURLCache] setMemoryCapacity:0]; // for leak
		[[NSURLCache sharedURLCache] setDiskCapacity:0];  // for leak
		
	    NSHTTPURLResponse *response;
		
	NSError *requestError = nil;	
	[NSURLConnection sendSynchronousRequest:request 
						returningResponse:&response 
									error:&requestError];
	//init return errorobject
	*error = requestError;
	
		// nash for leak : NSURLConnection sendSynchronousRequest will cache some buffer will cause leak
		[[NSURLCache sharedURLCache] removeAllCachedResponses];
	
		NSDictionary *httpResponseHeaderFields= [response allHeaderFields];
	
	
		retData = [httpResponseHeaderFields valueForKey:key];
		
		[url        release];
		[postLength release];
		[request    release];
		
	
	
	return retData;
}

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
			   withRetrievingCount: (int)retrievingCount
{
	// [link to Terra] => [parsing XML]
		
	//NSMutableArray *dList;
	@synchronized(g_device_lock)
	{
		m_nDeviceType = deviceType;
	
		NSString *strType;
	
		switch (deviceType) {
			case 0:
				strType = @"ip_camera";
				break;
			case 1:
				strType = @"nvr";
				break;
			case 2:
				strType = @"hmg";
				break;
			default:
				strType = @"ip_camera";
				break;
		}
	
		NSString *URL = [[NSString alloc] initWithFormat:@"http://%@/cgi/dev_gquery.php?dev_type=%@",TerraInfo.serverIP, strType];
		//NSLog(@"Devinfo URL = %@",URL);
		//for test
		// http://219.87.146.22/cgi/dev_gquery.php?dev_type=ip_camera
		//NSString *URL = [NSString stringWithFormat:@"http://219.87.146.25/dev_gquery_errorTest.xml"];//error test
		//NSString *URL = [NSString stringWithFormat:@"http://219.87.146.25/dev_gquery_empty.xml"];//no divece Test
		//NSString *URL = [NSString stringWithFormat:@"http://219.87.146.25/dev_gquery_real.xml"];//divece Test	
		NSError *error = nil;
		NSData *data = [self syncHttpsRequest:URL
									errorCode:&error];
		
		if(deviceList != nil) {
			[deviceList release];
			deviceList = nil;
		}
		
		if(data != nil) {
			
			NSXMLParser *xmlParser  = [[NSXMLParser alloc] initWithData:data];		
		
			ParserDeviceInfo *parserDelgate = [[ParserDeviceInfo alloc] init];
			[xmlParser setDelegate:parserDelgate];
			[xmlParser parse];
			[xmlParser release];
		
			deviceList = [[parserDelgate getDeviceList] mutableCopy];
			[parserDelgate release];
		}
		
		[URL release];
		
		
	}
	return deviceList;
	
	
}

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
// [in]  clipSubType: (int)			0<reserved> 
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
				   withRetrievingCount: (int)retrievingCount
{
	//NSMutableArray *cList;
	NSString* did = [[NSString alloc ]initWithString:deviceID];
	@synchronized(g_clip_lock)
	{
		//parameter eduration	
		// duration format A,B[,C]
		// CASE asc: "referTime,-,asc"
		// CASE desc: "-,referTime,desc"
		
		NSString *strEduration;
		switch (direction) {
			case 0://CASE asc
				strEduration = [[NSString alloc] initWithFormat:@"%@,%@,asc", startTime, endTime];
				break;
			case 1://CASE desc
				strEduration = [[NSString alloc] initWithFormat:@"%@,%@,desc", startTime, endTime];
				break;
			default:
				strEduration = [[NSString alloc] initWithFormat:@"%@,%@,asc", startTime, endTime];
				break;
		}
	
	
		//parameter number
		// format A,B
		int nEndIndex = startIndex + retrievingCount -1;
		NSString *strNumber = [[NSString alloc] initWithFormat:@"&number=%d,%d", startIndex, nEndIndex];
 
 
		//parameter type
		// format A
		/*
		NSString *strType;
		switch (clipType) {
			case 0x04: // di->input port trigger
				strType= @"&type=di";
				break;
 
			case 0x20: // audio->audio trigger
				strType= @"&type=audio";
				break;
 
			case 0x02: // motion-> motion trigger
				strType= @"&type=motion";
				break;
 
			case 0x08: // pir-> pir trigger
				strType= @"&type=pir";
				break;
 
			///*
			 case : // httpc-> HTTP CGI client trigger
			 strType= @"&type=httpc";
				break;
 
			 case 0x10: // rf->RF sensor trigger
			 strType= @"&type=rf";
				break;
 
			 case : // femto->Femto cell event trigger
			 strType= @"&type=femto";
				break;
			//*
			default:
				strType= @"";
			break;
		}
		*/
		
		//do URL composition	
		//NSString *URL = [NSString stringWithFormat:@"http://%@:%@@%@:%d/terra_mobile/0queryClip.php",TerraInfo.serverAccountName , TerraInfo.serverPassword, TerraInfo.serverIP, TerraInfo.serverPort];
		NSString *URL = [[NSString alloc] initWithFormat:@"http://%@/cgi/query_clip.php?dev_id=%@&eduration=", TerraInfo.serverIP, did];
		NSString *URLCompositon = [[URL stringByAppendingString:strEduration] stringByAppendingString:strNumber];

		//for test
		//NSString *URL = [NSString stringWithFormat:@"http://219.87.146.25/query_clip_error.xml"];//error test
		//NSString *URL = [NSString stringWithFormat:@"http://219.87.146.25/query_clip_empty.xml"];//no divece Test
		//NSString *URL = [NSString stringWithFormat:@"http://219.87.146.25/query_clip_real.xml"];//divece Test
		
		// [link to Terra] => [parsing XML]
		NSError *error = nil;
		NSData *data = [self syncHttpsRequest:URLCompositon
									errorCode:&error];
			//	NSLog(@"URL : %@",URLCompositon);
		if(clipList != nil) {
			[clipList release];
			clipList = nil;
		}
		if(data != nil) {
		
			//NSLog(@"URL =%@\n",URLCompositon);
		
			//NSString *tmp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			//NSLog(@"Data:\n %@\n",tmp);
	
			NSXMLParser *xmlParser  = [[NSXMLParser alloc] initWithData:data];		
		
			ParserClipInfo *parserDelgate = [[ParserClipInfo alloc] init];
			[xmlParser setDelegate:parserDelgate];
			[xmlParser parse];
			[xmlParser release];
		
			clipList    = [[parserDelgate getClipList] mutableCopy];
			[parserDelgate release];
		}
				
		[strEduration release];
		[strNumber release];
		[URL release];
	
	}
	
	[did release];
	//return cList;
	return clipList;
}

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
									 ClipFlag: (BOOL)clipFlag 	
{// [link to Terra] => [parsing XML]
	
	//NSMutableArray *eList;
	@synchronized(g_event_lock)
	{
		NSString *strDeviceID;
		NSString *strDuration;
		NSString *strNumber;
		NSString *strType;
		NSString *strWhere;
		NSString *strClip;
		
		//parameter eduration is must
		//format is A,B[,C]
		strDuration  = [[NSString alloc] initWithFormat:@"eduration=%@",duration];
	
		//parameter dev_id is optional	
		if (deviceIDFlag)
			strDeviceID  = [[NSString alloc] initWithFormat:@"&dev_id=%@",deviceID];
		else
			strDeviceID  = [[NSString alloc] initWithFormat:@""];
	
		//parameter number is optional	
		if (numberFlag)
			strNumber  = [[NSString alloc] initWithFormat:@"&number=%@",number];
		else
			strNumber  = [[NSString alloc] initWithFormat:@""];
	
		//parameter type is optional	
		if (typeFlag)
			strType  = [[NSString alloc] initWithFormat:@"&trigger_by_type=%@",type];
		else
			strType  = [[NSString alloc] initWithFormat:@""];
	
		//parameter where is optional
		if (whereFlag)
			strWhere  = [[NSString alloc] initWithFormat:@"&trigger_by_where%@",where];
		else
			strWhere  = [[NSString alloc] initWithFormat:@""];
	
		//parameter clip is optional	
		if (clipFlag)
			strClip  = @"&clip=yes";
		else
			strClip  = @"&clip=no";

		//do URL compositon
		//NSString *URL = [NSString stringWithFormat:@"http://%@:%@@%@:%d/query_clip.cgi?%@%@%@%@",TerraInfo.serverAccountName
		//, TerraInfo.serverPassword, TerraInfo.serverIP, TerraInfo.serverPort, strDuration, strType ,strWhere, strClip];
		NSString *URL = [[NSString alloc] initWithFormat:@"http://%@/cgi/event_query.php?%@%@%@%@%@%@", TerraInfo.serverIP, strDuration, strDeviceID, strNumber, strType ,strWhere, strClip];
		//NSLog(@"%@",URL);
		//Testing 
		//NSString *URL = [NSString stringWithString:@"http://219.87.146.22/emptyhouseQuery.xml"];//empty event list
		//NSString *URL = [NSString stringWithString:@"http://219.87.146.25/event_query_empty.xml"];//empty event list
		//NSString *URL = [NSString stringWithString:@"http://219.87.146.25/event_query_wrongFormat.xml"];//error event
		NSError *error = nil;
		NSData *data = [self syncHttpsRequest:URL
									errorCode:&error];
		
		if(eventList != nil) {
			[eventList release];
			eventList = nil;
		}
		if(data != nil) {
		
			NSXMLParser *xmlParser  = [[NSXMLParser alloc] initWithData:data];		
		
			ParserEventInfo *parserDelgate = [[ParserEventInfo alloc] init];
			[xmlParser setDelegate:parserDelgate];
			[xmlParser parse];
			[xmlParser release];
		
			eventList = [[parserDelgate getEventList] mutableCopy];
			[parserDelgate release];
		}
		

		[strDuration release];
		[strDeviceID release];
		[strNumber release];
		[strType release];
		[strWhere release];
		[strClip release];
		[URL release];
		
		//NSLog(@"event Array count:%d",[eventList count]);	
		
	}
	//return nil;
	return eventList;
	//return eList;
}


#pragma mark ====1.2.1.1 CGI Relay ====


-(NSError *)cgiRelay:(NSString*)beacon cmd:(NSString*)command
{
	//NSLog(@"%@",command);
	
	NSString *base64 = Base64Encoder([command dataUsingEncoding:NSUTF8StringEncoding]);//[Base64 encode:(uint8_t*)[command UTF8String] length:[command length]];
	//NSLog(@"%@",base64);
	NSString *URL = [[NSString alloc] initWithFormat:@"http://%@/cgi/cmd_relay.php?beacon=%@&cmd=%@",TerraInfo.serverIP,beacon,base64];
	NSError *error = nil;
	[self syncHttpsRequest:URL
				 errorCode:&error];
	
	[URL release];
	return error;
}
#pragma mark ==== 1.2.7 Scene, Notification and Automation ====
#pragma mark ==== 1.2.7.1 Object/Cluster (Z-Wave/ZigBee/RF) Control ====
/*
 [in] dev_id: (NSString)			Device ID, up to 256 ACSII charaters
 [out] device
			object_list
			organization
*/

- (NSMutableArray*)GetObjListWithDevice: (NSString*)dev_id errorCode:(NSError **)error
{
	
	//NSMutableArray *oList;
	
	@synchronized(g_obj_lock)
	{
		NSString *URL = [[NSString alloc] initWithFormat:@"http://%@/cgi/allobj_query.php?dev_id=%@", TerraInfo.serverIP,dev_id];
		//NSString *URL = [NSString stringWithFormat:@"http://219.87.146.22/cgi/allobj_query.php?dev_id=%@",dev_id];
		//for test
		//NSString *URL = [NSString stringWithString:@"http://219.87.146.25/allobj_query.xml"];//all object query
		
		NSError *error = nil;
		NSData *data = [self syncHttpsRequest:URL
									errorCode:&error];
		
		if(objectClusterList != nil) {
			[objectClusterList release];
			objectClusterList = nil;
		}
		if(data != nil) {
		
			NSXMLParser *xmlParser  = [[NSXMLParser alloc] initWithData:data];	
		
			ParserObj *parserDelgate = [[ParserObj alloc] init];
			[xmlParser setDelegate:parserDelgate];
			[xmlParser parse];
			[xmlParser release];
			objectClusterList= [[parserDelgate getDevWithObjList] mutableCopy];
			[parserDelgate release];
			[URL release];
		}
		
		//NSString *tmp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		//NSLog(@"Data:\n %@\n",tmp);
		//[tmp release];
				
	}
	
	//return oList;
	//return [objectClusterList autorelease];
	return objectClusterList;
	 
}

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
			OldQPassword: (NSString *)oldQPassword
{
	NSString *armRet = nil;
	@synchronized(g_arm_lock)
	{
		NSString *strOldPassword;
		NSString *strOldQPassword;
		
		//parameter old_password is optional	
		if (oldPasswordFlag)
			strOldPassword  = [[NSString alloc] initWithFormat:@"&old_password=%@",oldPassword];
		else
			strOldPassword  = [[NSString alloc] initWithFormat:@""];
	
	
		//parameter old_qpassword is optional	
		if (oldQPasswordFlag)
			strOldQPassword  = [[NSString alloc] initWithFormat:@"&old_qpassword=%@",oldQPassword];
		else
			strOldQPassword  = [[NSString alloc] initWithFormat:@""];
		
		//do URL compositon
		NSString *URL = [[NSString alloc] initWithFormat:@"http://%@/cgi/ha_control.php?action=%@&password=%@%@%@", TerraInfo.serverIP, action, password, strOldPassword, strOldQPassword];
		
		NSError *error = nil;
		NSData *data = [self syncHttpsRequest:URL
									errorCode:&error];
		
		if(data != nil) {
		//Parsing
			NSXMLParser *xmlParser  = [[NSXMLParser alloc] initWithData:data];		
			ParserArm *parserDelgate = [[ParserArm alloc] init];
		
			[xmlParser setDelegate:parserDelgate];
			[xmlParser parse];
			[xmlParser release];
		
			NSString *arm = [parserDelgate getArm];
			if(arm != nil)
				armRet = [[[NSString alloc] initWithString: arm] autorelease];
		
			[parserDelgate release];
		}
		else {
			data = nil;
		}

		[strOldPassword release];
		[strOldQPassword release];
		[URL release];
	}
	return armRet;
	
	
}


#pragma mark ==== 1.2.7.3 Notification and Automation (Home Automation) ====
//Get Home Automation List with specific query: 
// 
// [in]  nameFlag: (BOOL)	-> define the parameter "name" if is valid
// [in]  name: (NSString)	<Optional, scence name, up to 256 ASCII charaters. For multiple, format:A[,A,A,...]>
- (NSMutableArray *) GetHomeAutomationListWithNameFlag: (BOOL)nameFlag 	 
												  Name: (NSString *)name
{
	/*
	@synchronized(g_data_lock)
	{
	NSString *strName;
	
	//parameter old_password is optional	
	if (nameFlag)
		strName  = [NSString stringWithFormat:@"?name=%@",name];
	else
		strName  = [NSString stringWithFormat:@""];
	
	NSString *URL = [NSString stringWithFormat:@"http://%@/cgi/esma_query.php%@", TerraInfo.serverIP, strName];
	
	NSData *data = [self syncHttpsRequest:URL];
	
	//Parsing
	NSXMLParser *xmlParser  = [[NSXMLParser alloc] initWithData:data];		
	Parser *Delegateparser = [[[Parser alloc] initXMLParser] autorelease];	
	Delegateparser.delegate = self;
	[Delegateparser setParsingType:5];//Delegateparser.m_nCurrentTyp = 5;//Current parser type: (5) Home Automation list parser
	
	//Set delegate
	[xmlParser setDelegate:Delegateparser];
	
	//Start parsing the XML file.
	[xmlParser parse];
		[xmlParser release];
		[Delegateparser release];
		
	}
	
	return homeAutomationList;
	 */
	return nil;
}

//Home Automation Configuration: 
// 
// [in]  action: (NSString)			<format:string		
//									ex: add(default), delete, modify
// [in]  password: (NSString)		<Ｐlease refer to the relative parameters defined in XML element of esma_query.cgi.
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
					ParameterString: (NSString *)parameterString
{
	/*
	//do URL compositon
	NSString *URL = [NSString stringWithFormat:@"http://%@/cgi/esma_conf.php?action=%@&%@", TerraInfo.serverIP, action, parameterString];
	//NSLog(@"%@",URL);
	//Testing 
	//NSString *URL = @"";
	
	NSString *strResponse = (NSString *)[self syncHttpsRequest:URL];
	
	return strResponse;
	*/
	return nil;
}

#pragma mark ==== 1.2.7.4 Scene ====
//Get Scene List with specific query: 
// 
// [in]  nameFlag: (BOOL)	-> define the parameter "name" if is valid
// [in]  name: (NSString)	<Optional, scence name, up to 256 ASCII charaters. For multiple, format:A[,A,A,...]>
- (NSMutableArray *) GetSceneListWithNameFlag: (BOOL)nameFlag 	 												
										 Name: (NSString *)name
{
	/*
	NSString *strName;
	
	//parameter old_password is optional	
	if (nameFlag)
		strName  = [NSString stringWithFormat:@"?name=%@",name];
	else
		strName  = [NSString stringWithFormat:@""];
	
	NSString *URL = [NSString stringWithFormat:@"http://%@/cgi/scene_query.php%@", TerraInfo.serverIP, strName];
	//NSLog(@"%@",URL);
	//Testing 
	//NSString *URL = @"";
	
	NSData *data = [self syncHttpsRequest:URL];
	
	//Parsing
	NSXMLParser *xmlParser  = [[NSXMLParser alloc] initWithData:data];		
	Parser *Delegateparser = [[[Parser alloc] initXMLParser] autorelease];	
	Delegateparser.delegate = self;
	[Delegateparser setParsingType:6];//Delegateparser.m_nCurrentTyp = 6;//Current parser type: (6) Scene list parser
	
	//Set delegate
	[xmlParser setDelegate:Delegateparser];
	
	//Start parsing the XML file.
	[xmlParser parse];
	[xmlParser release];
	[Delegateparser release];
	
	return sceneList;
	 */
	return nil;
}

// Scene Configuration: 
// 
// [in]  action: (NSString)			<format:string		
//									ex: add(default), delete, modify
// [in]  password: (NSString)		<Ｐlease refer to the relative parameters defined in XML element of query.cgi.
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
		   ParameterString: (NSString *)parameterString
{
	/*
	//do URL compositon
	NSString *URL = [NSString stringWithFormat:@"http://%@/cgi/scene_conf.php?action=%@&%@", TerraInfo.serverIP, action, parameterString];
	//NSLog(@"%@",URL);
	//Testing 
	//NSString *URL = @"";
	
	NSString *strResponse = (NSString *)[self syncHttpsRequest:URL];
	
	return strResponse;
	*/
	return nil;
}


//Get Scene List with specific query: 
// 
// [in]  name: (NSString)	<Optional, scence name, up to 256 ASCII charaters. For multiple, format:A[,A,A,...]>
// [out] status: (NSString) Response status
//				ok 
//				error 
//				no-existing
//				disabled
- (NSString *) SceneTriggerWithName: (NSString *)name
{
	/*
	//do URL compositon
	NSString *URL = [NSString stringWithFormat:@"http://%@/cgi/scene_trigger.php?name=%@", TerraInfo.serverIP, name];
	//NSLog(@"%@",URL);
	//Testing 
	//NSString *URL = @"";
	
	NSString *strResponse = (NSString *)[self syncHttpsRequest:URL];
	
	return strResponse;
	*/
	return nil;
}

#pragma mark ==== 1.2.7.5 SMS ====
// Scene Configuration: 
// 
// [in]  phone: (NSString)			<Phone number which the message will be send to. For multiple, format:A[,A,A,...]>
// [in]  message: (NSString)		<Message content, encodeed in base64, max length depends on ISP>
// [out] status: (NSString) Response status
//				ok 
//				error
- (NSString *) SMS_withPhone: (NSString *)phone
					 Message: (NSString *)message
{
	/*
	//do URL compositon
	NSString *URL = [NSString stringWithFormat:@"http://%@/cgi/sms_notify.php?phone=%@&message=%@", TerraInfo.serverIP, phone, message];
	//NSLog(@"%@",URL);
	//Testing 
	//NSString *URL = @"";
	
	NSString *strResponse = (NSString *)[self syncHttpsRequest:URL];
	
	return strResponse;
	*/
	return nil;
}

#pragma mark ==== dealloc ====


- (void) dealloc {
	
	[deviceList release];
	
	[clipList release];
	[eventList release];
	[objectClusterList release];
	//NSMutableArray *accountList;
	//NSMutableArray *homeAutomationList;//Home automation List
	//NSMutableArray *sceneList;//scene List


	
	
	//add release
	[TerraInfo release];
	
	[super dealloc];
}

- (int) getMobileMode {
	
	return mobileMode; // default mode is P2P
}

- (void) setMobileMode:(int)mode {
	// save key.....
	
	
	mobileMode = mode;
}

- (NSMutableArray *) GetDeviceListWithRefresh: (BOOL*) bRefresh
								  withDevType: (int)deviceType 
								  withSubType: (int)deviceSubType 
						  withRetrievingCount: (int)retrievingCount {
	
	*bRefresh = YES;
	NSMutableArray * dList = nil;
	
	@synchronized(g_device_lock)
	{
		m_nDeviceType = deviceType;
		
		NSString *strType;
		
		switch (deviceType) {
			case 0:
				strType = @"ip_camera";
				break;
			case 1:
				strType = @"nvr";
				break;
			case 2:
				strType = @"hmg";
				break;
			default:
				strType = @"ip_camera";
				break;
		}
		
		NSString *URL = [[NSString alloc] initWithFormat:@"http://%@/cgi/dev_gquery.php?dev_type=%@",TerraInfo.serverIP, strType];

		NSError *error = nil;
		NSData *data = [self syncHttpsRequest:URL
									errorCode:&error];
		
		if(data != nil) {
			
			NSXMLParser *xmlParser  = [[NSXMLParser alloc] initWithData:data];		
			
			ParserDeviceInfo *parserDelgate = [[ParserDeviceInfo alloc] init];
			[xmlParser setDelegate:parserDelgate];
			[xmlParser parse];
			[xmlParser release];
			
			dList = [[parserDelgate getDeviceList] mutableCopy];
			[parserDelgate release];
		}
		
		[URL release];
		
		
	}
	
	
	int checkcount = 0;
	
	
	if(deviceList != nil) {
		
		if([deviceList count] == [dList count]) {
			for (int i = 0 ; i<[deviceList count]; i++) {
			    DeviceInfo *oldDev = [deviceList objectAtIndex:i];
				DeviceInfo *newDev = [dList      objectAtIndex:i];
				
				if([oldDev.ID       isEqualToString:newDev.ID]        && 
				   [oldDev.tz       isEqualToString:newDev.tz]        &&
				   [oldDev.type     isEqualToString:newDev.type]      &&
				   [oldDev.mac      isEqualToString:newDev.mac]       &&
				   [oldDev.name     isEqualToString:newDev.name]      &&
				   [oldDev.internal isEqualToString:newDev.internal]  &&
				   [oldDev.external isEqualToString:newDev.external]  &&
				   [oldDev.relay    isEqualToString:newDev.relay]     &&
				   [oldDev.vpns     isEqualToString:newDev.vpns]      &&
				   [oldDev.username isEqualToString:newDev.username]  &&
				   [oldDev.password isEqualToString:newDev.password]  &&
				   [oldDev.status   isEqualToString:newDev.status]    &&
				   [oldDev.beacon   isEqualToString:newDev.beacon]) 
					checkcount++;
				
			}
			if(checkcount == [dList count])
				*bRefresh = NO;
		}
		
		[deviceList release];
		deviceList = nil;
	}
	
	deviceList = dList;
	
	return deviceList;
}

- (MobileNetworkType) isConnectToNetworkWithMsg:(BOOL) bShow {

	struct sockaddr_in zeroAddr;
	bzero(&zeroAddr, sizeof(zeroAddr));
	zeroAddr.sin_len = sizeof(zeroAddr);
	zeroAddr.sin_family = AF_INET;
	
	SCNetworkReachabilityRef target = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *) &zeroAddr);
	
	SCNetworkReachabilityFlags flags;
	SCNetworkReachabilityGetFlags(target, &flags);
	
	CFRelease(target);

	if (flags & kSCNetworkFlagsReachable) {
		if (flags & kSCNetworkReachabilityFlagsIsWWAN)
			return MB_NETWORK_WIFI;
		else
			return MB_NETWORK_3G;		
	}
	else {
		if(bShow) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network error" 
															message:@"No Internet connection available. Please connect to the Internet." 
														   delegate:nil 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
			
			[alert show];
			[alert release];
			
		}
		return MB_NETWORK_NONE;
	}
}

- (BOOL) isReachableHttpURL: (NSURL*) url {
	
	NSData *urlData;
	
	//NSURL *url = [[NSURL alloc] initWithString:inUrl];
	
	//Old code <== using default header content
	//NSURLRequest *request = [NSURLRequest requestWithURL:url];	
	
	///New code	
	//
	//Modify specific field of response header according to FW spec.
	// Cookie: user_name=XXXX; user_token=1234567890...1234567890;\r\n
	//
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:url];
	[request setTimeoutInterval:1.0];
	
	//Real case:
	//NSLog(@"%@,%@",m_userName,m_userToken);
	//NSString *strCookie = [[NSString alloc] initWithFormat:@"user_name=%@; user_token=%@;", self.m_userName,self.m_userToken];	
	//[request setValue:strCookie forHTTPHeaderField:@"Cookie"];
	
	[[NSURLCache sharedURLCache] setMemoryCapacity:0]; // for leak
	[[NSURLCache sharedURLCache] setDiskCapacity:0];   // for leak
	
	NSHTTPURLResponse *response;
	NSError *errorCode = nil;	
	
	urlData = [NSURLConnection sendSynchronousRequest:request 
									returningResponse:&response 
												error:&errorCode];
	
	NSInteger httpStatus = [((NSHTTPURLResponse *)response) statusCode];
	NSLog(@"responsecode:%d", httpStatus);
		
	//*error = errorCode;
	
	// nash for leak : NSURLConnection sendSynchronousRequest will cache some buffer will cause leak
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	
	[url       release];
	[request   release];
	//[strCookie release];
	return (httpStatus == 200)? YES : NO;
	
}

@end

 
//*/






