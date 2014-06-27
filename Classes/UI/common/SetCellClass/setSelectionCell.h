//
//  setSelectionCell.h
//  TerraUI
//
//  Created by Shell on 2011/1/27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface setSelectionCell : NSObject 
{
	BOOL checkOption;
	NSString *titleLabel;
	NSString *cgiType;

}
-(id) initWithTitle:(NSString*)t check:(BOOL)c cgi:(NSString*)type;
@property (nonatomic) BOOL checkOption;
@property (nonatomic,retain) NSString *titleLabel;
@property (nonatomic,retain) NSString *cgiType;

@end
