//
//  ViewController.m
//  Job
//
//  Created by lzhu on 7/16/16.
//  Copyright © 2016 redeight. All rights reserved.
//

#import "ViewController.h"
#import "RTTestJob.h"
#import "RTJobManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onPositive:(id)sender {
    self.label.text = @"+";
    printf("assume success : +\n");
    [[RTJobManager sharedManager] addJob:[RTTestJob positiveJob]];
}

- (IBAction)onNegative:(id)sender {
    self.label.text = @"-";
    printf("assume success : -\n");
    [[RTJobManager sharedManager] addJob:[RTTestJob negativeJob]];
}

@end
