//
//  AskerViewController.h
//  AnimatedBookshelf
//
//  Created by Yukui Ye on 5/26/13.
//  Copyright (c) 2013 Yukui Ye. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AskerViewController : UIViewController
@property (strong,nonatomic) NSString *question;
@property (strong,readonly) NSString *answer;

@end
