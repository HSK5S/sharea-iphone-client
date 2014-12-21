//
//  PostCell.h
//  get
//
//  Created by takuti on 9/12/13.
//  Copyright (c) 2013 takuti. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PostCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *postDateLabel;
@end
