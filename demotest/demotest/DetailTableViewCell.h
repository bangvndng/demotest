//
//  DetailTableViewCell.h
//  demotest
//
//  Created by Bang Ngoc Vu on 4/28/14.
//  Copyright (c) 2014 Bang Ngoc Vu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DetailTableViewCellDelegate;

@interface DetailTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *cellTitle;
@property (weak, nonatomic) IBOutlet UILabel *cellAddress;
@property (weak, nonatomic) IBOutlet UILabel *cellSummary;
@property (weak, nonatomic) IBOutlet UILabel *cellDistance;
@property (weak, nonatomic) IBOutlet UILabel *cellDuration;
@property (weak, nonatomic) IBOutlet UIButton *cellBtnNextAlternative;

- (IBAction)pressDetails:(id)sender;
- (IBAction)pressAlternativeRoute:(id)sender;

@property (weak, nonatomic) id<DetailTableViewCellDelegate> delegate;

@end

@protocol DetailTableViewCellDelegate <NSObject>

@optional

- (void)detailTableViewCell:(DetailTableViewCell *)detailTableViewCell didPressDetail:(NSDictionary *)info;
- (void)detailTableViewCell:(DetailTableViewCell *)detailTableViewCell didPressAlternativeRoute:(NSDictionary *)info;

@end
