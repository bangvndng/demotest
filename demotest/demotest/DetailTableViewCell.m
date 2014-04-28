//
//  DetailTableViewCell.m
//  demotest
//
//  Created by Bang Ngoc Vu on 4/28/14.
//  Copyright (c) 2014 Bang Ngoc Vu. All rights reserved.
//

#import "DetailTableViewCell.h"

@implementation DetailTableViewCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)pressDetails:(id)sender {
    NSLog(@"DetailTableViewCell pressDetails");
    if (self.delegate && [self.delegate respondsToSelector:@selector(detailTableViewCell:didPressDetail:)]) {
        [self.delegate detailTableViewCell:self didPressDetail:nil];
    }
}

- (IBAction)pressAlternativeRoute:(id)sender {
    NSLog(@"DetailTableViewCell pressAlternativeRoute");
    if (self.delegate && [self.delegate respondsToSelector:@selector(detailTableViewCell:didPressAlternativeRoute:)]) {
        [self.delegate detailTableViewCell:self didPressAlternativeRoute:nil];
    }
}
@end
