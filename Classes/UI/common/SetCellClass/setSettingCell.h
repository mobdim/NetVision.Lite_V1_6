//
//  setSettingCell.h
//  TerraUI
//
//  Created by Shell on 2011/1/26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface setSettingCell : NSObject {
	UIImage *icon;
	NSString *titleText;
	NSString *detailText;

}
-(id)initWithIcon:(id)image Title:(NSString*)first Detail:(NSString*)secondary;
@property (nonatomic,retain) UIImage *icon;
@property (nonatomic,retain) NSString *titleText;
@property (nonatomic,retain) NSString *detailText;

@end
