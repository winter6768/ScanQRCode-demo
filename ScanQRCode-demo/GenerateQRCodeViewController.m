//
//  GenerateQRCodeViewController.m
//  ScanQRCode-demo
//
//  Created by 也瘦 on 16/8/12.
//  Copyright © 2016年 也瘦. All rights reserved.
//

#import "GenerateQRCodeViewController.h"

@interface GenerateQRCodeViewController ()
{
    UITextView *inputText;
    
    UIImageView *image_code;
}
@end

@implementation GenerateQRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"二维码生成";
    self.view.backgroundColor = [UIColor lightGrayColor];

    [self setupNavigationItem];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self setupUI];
    });
}

#pragma mark - UI
-(void)setupNavigationItem
{
    //    关闭按钮
    UIButton *btn_colse = [UIButton new];
    btn_colse.frame = CGRectMake(0, 0, 44, 44);
    [btn_colse setTitle:@"关闭" forState:UIControlStateNormal];
    [btn_colse setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn_colse addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:btn_colse];
}

-(void)close:(UIButton *)button
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)setupUI
{
//    输入框
    inputText = [UITextView new];
    inputText.font = [UIFont systemFontOfSize:15];
    inputText.frame = CGRectMake(10, 74, self.view.frame.size.width - 20, 150);
    [self.view addSubview:inputText];

    //    输入完成
    UIButton *btn_finish = [UIButton new];
    [btn_finish setTitle:@"完成" forState:UIControlStateNormal];
    btn_finish.titleLabel.textAlignment = NSTextAlignmentRight;
    [btn_finish setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btn_finish.backgroundColor = [UIColor whiteColor];
    btn_finish.frame = CGRectMake(0, 0, self.view.frame.size.width, 50);
    inputText.inputAccessoryView = btn_finish;
    
    [btn_finish addTarget:self action:@selector(inputFinish:) forControlEvents:UIControlEventTouchUpInside];
    
//    生成按钮
    UIButton *btn_generate = [UIButton new];
    btn_generate.frame = CGRectMake(inputText.frame.origin.x, inputText.frame.size.height + inputText.frame.origin.y + 10, inputText.frame.size.width, 70);
    [btn_generate setTitle:@"生成" forState:UIControlStateNormal];
    [btn_generate setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn_generate setBackgroundColor:[UIColor grayColor]];
    [btn_generate addTarget:self action:@selector(generate:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn_generate];
    
//    显示图片
    image_code = [UIImageView new];
    image_code.frame = CGRectMake(0, 0, 270, 270);
    image_code.center = CGPointMake(self.view.center.x, btn_generate.center.y + 200);
    [self.view addSubview:image_code];
    
    image_code.userInteractionEnabled = YES;
    [image_code addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(recognition:)]];
}

-(void)inputFinish:(UIButton *)button
{
    [inputText resignFirstResponder];
}

#pragma mark - 生成二维码
-(void)generate:(UIButton *)button
{
    // 1. 实例化二维码滤镜
    
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    // 2. 恢复滤镜的默认属性
    
    [filter setDefaults];
    
    // 3. 将字符串转换成
    
    NSData *data = [inputText.text dataUsingEncoding:NSUTF8StringEncoding];
    
    // 4. 通过KVO设置滤镜inputMessage数据
    
    [filter setValue:data forKey:@"inputMessage"];
    
//    纠错级别
    [filter setValue:@"M" forKey:@"inputCorrectionLevel"];
    
    // 5. 获得滤镜输出的图像
    
    CIImage *outputImage = [filter outputImage];
    
    // 6. 将CIImage转换成UIImage，并放大显示
    
    UIImage *image = [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:image_code.frame.size.width];
    
    image_code.image = image;
    
//    NSLog(@"%@",image);
}

/**
 * 根据CIImage生成指定大小的UIImage
 *
 * @param image CIImage
 * @param size 图片宽度
 */
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

#pragma mark - 识别图片中的二维码

static CIDetector *detector;
-(void)recognition:(UITapGestureRecognizer *)tap
{
    if (!image_code.image)
    {
        return;
    }
    
    detector = detector ?: [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
    
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image_code.image.CGImage]];
    
    if (features.count)
    {
        CIQRCodeFeature *feature = features.firstObject;
        NSString *scannedResult = feature.messageString;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:scannedResult message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }
}


@end
