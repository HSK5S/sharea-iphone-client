//
//  getViewController.h
//  get
//
//  Created by takuti on 9/12/13.
//  Copyright (c) 2013 takuti. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <QuartzCore/QuartzCore.h>
#import "EGORefreshTableHeaderView.h"

@interface getViewController : UIViewController <CLLocationManagerDelegate, EGORefreshTableHeaderDelegate>
{
    CLLocationManager *locaitonManager;
    UILabel *areaLabel;
}

- (IBAction)changeLocation:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *headerImage;

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UITableView *postTableView;
@property (weak, nonatomic) IBOutlet UIButton *getLocationButton;
@end
