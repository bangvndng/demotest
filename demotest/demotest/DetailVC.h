//
//  DetailVC.h
//  demotest
//
//  Created by Bang Ngoc Vu on 4/29/14.
//  Copyright (c) 2014 Bang Ngoc Vu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailVC : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *steps;
@end
