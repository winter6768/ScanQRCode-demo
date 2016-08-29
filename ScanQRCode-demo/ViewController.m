//
//  ViewController.m
//  ScanQRCode-demo
//
//  Created by 也瘦 on 16/8/10.
//  Copyright © 2016年 也瘦. All rights reserved.
//

#import "ViewController.h"
#import "ScanQRCodeViewController.h"
#import "GenerateQRCodeViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton *btn_scan = [UIButton new];
    [btn_scan setTitle:@"扫一扫" forState:UIControlStateNormal];
    [btn_scan setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn_scan setBackgroundColor:[UIColor lightGrayColor]];
    [btn_scan addTarget:self action:@selector(scan:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn_scan];
    
    btn_scan.frame = CGRectMake(0, 0, self.view.frame.size.width, 100);
    btn_scan.center = self.view.center;
    
    
    UIButton *btn_generate = [UIButton new];
    [btn_generate setTitle:@"二维码生成" forState:UIControlStateNormal];
    [btn_generate setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn_generate setBackgroundColor:[UIColor lightGrayColor]];
    [btn_generate addTarget:self action:@selector(generate:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn_generate];
    
    btn_generate.frame = CGRectMake(0, 0, self.view.frame.size.width, 100);
    btn_generate.center = CGPointMake(btn_scan.center.x, btn_scan.center.y + 110);

}

-(void)scan:(UIButton *)button
{
    ScanQRCodeViewController *scanQRCode =  [[ScanQRCodeViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:scanQRCode];
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)generate:(UIButton *)button
{
    GenerateQRCodeViewController *generateQRCode =  [[GenerateQRCodeViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:generateQRCode];
    [self presentViewController:nav animated:YES completion:nil];
}

@end
