//
//  loginView.h
//  TerraUI
//
//  Created by Shell on 2011/1/21.
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
#import "TerraUIAppDelegate.h"


@interface loginView : UIViewController 
<UITextFieldDelegate>
{
	id delegate;
	IBOutlet UITextField *accountField;
	IBOutlet UITextField *passwordField;
	IBOutlet UITextField *ipField;
	IBOutlet UITextField *portField;
	IBOutlet UIButton *cancelBtn;
	IBOutlet UIButton *connectBtn;

}

- (IBAction)cancel:(id)object;
- (IBAction)connect:(id)object;

@property (nonatomic,retain) IBOutlet UITextField *accountField;
@property (nonatomic,retain) IBOutlet UITextField *passwordField;
@property (nonatomic,retain) IBOutlet UITextField *ipField;
@property (nonatomic,retain) IBOutlet UITextField *portField;
@property (nonatomic,retain) IBOutlet UIButton *cancelBtn;
@property (nonatomic,retain) IBOutlet UIButton *connectBtn;
@end
