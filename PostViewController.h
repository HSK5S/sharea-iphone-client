//
//  ViewController.h
//  HSK5Spost
//
//  Created by yukihara on 2013/09/12.
//  Copyright (c) 2013年 edu.self. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface PostViewController : UIViewController <UITextViewDelegate>
{
    UITextView *inputTextView;
    __weak IBOutlet UIBarButtonItem *topbtn;
    
    UILabel *inputCountLabel;
    UIButton *submitBtn;
}

@property (nonatomic) double latitude;
@property (nonatomic) double longitude;

@end
