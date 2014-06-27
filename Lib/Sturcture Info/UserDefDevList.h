//
//  UserDefDevList.h
//  TerraUI
//
//  Created by Shell on 2011/4/25.
//  Copyright 2011 Sercomm. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UserDefDevList : NSObject <NSCoding>
{
	NSString *cameraName;
	NSString *IPAddr;
	NSString *UserName;
	NSString *Password;
}
- (id)initWithDeviceName:(NSString*)name DeviceIP:(NSString*)deviceIp UserName:(NSString*)uname Password:(NSString*)pw;
@property (nonatomic ,retain) NSString *cameraName;
@property (nonatomic ,retain) NSString *IPAddr;
@property (nonatomic ,retain) NSString *UserName;
@property (nonatomic ,retain) NSString *Password;

@end
