//
//  ViewController.h
//  Job
//
//  Created by lzhu on 7/16/16.
//  Copyright © 2016 redeight. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *label;

- (IBAction)onPositive:(id)sender;
- (IBAction)onNegative:(id)sender;

@end

