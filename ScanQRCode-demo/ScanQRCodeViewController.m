
//
//  ScanQRCodeViewController.m
//  ScanQRCode-demo
//
//  Created by 也瘦 on 16/8/10.
//  Copyright © 2016年 也瘦. All rights reserved.
//

#import "ScanQRCodeViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ScanQRCodeViewController ()<AVCaptureMetadataOutputObjectsDelegate>
{
    UIImageView *image_line;
}
/** 扫描区域的显示位置 */
@property(nonatomic,assign)CGRect showRect;

@property(nonatomic,strong)AVCaptureSession *session;

@property(nonatomic,strong)AVCaptureDeviceInput *deviceInput;

@property(nonatomic,strong)AVCaptureMetadataOutput *output;

@property(nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation ScanQRCodeViewController

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"扫描二维码";
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    [self setupNavigationItem];
    [self initSession];
    
    [self addNotification];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_session)
    {
        [_session startRunning];
        [self setupUI];
    }
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (_session)
    {
        [_session stopRunning];
        _session = nil;
    }
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
    UIView *maskView = [[UIView alloc] initWithFrame:self.view.bounds];
    maskView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    [self.view addSubview:maskView];
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:self.view.bounds];
    [maskPath appendPath:[[UIBezierPath bezierPathWithRoundedRect:_showRect cornerRadius:1] bezierPathByReversingPath]];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.path = maskPath.CGPath;
    
    maskView.layer.mask = maskLayer;


    //    扫描框 & 动画
    UIImageView *image_codeFrame = [UIImageView new];
    image_codeFrame.image = [UIImage imageNamed:@"ScanQRCodeFrame"];
    image_codeFrame.frame = _showRect;
    [self.view addSubview:image_codeFrame];
    
    image_line = [UIImageView new];
    image_line.image = [UIImage imageNamed:@"ScanQRCodeLine"];
    image_line.frame = CGRectMake(10, -2, 264, 2);
    [image_codeFrame addSubview:image_line];
    
    [self addLineAnimation:image_line.layer];
}

-(void)addLineAnimation:(CALayer *)layer
{
    CABasicAnimation *frameAnimation = [CABasicAnimation animationWithKeyPath:@"position.y"];
    frameAnimation.duration = 3.f;
    frameAnimation.fromValue = [NSNumber numberWithFloat:-2];
    frameAnimation.toValue   = [NSNumber numberWithFloat: 284];
    frameAnimation.repeatCount = HUGE_VALF;
    [layer addAnimation:frameAnimation forKey:@"position.y"];
}

#pragma mark - 通知
-(void)addNotification
{
//    进入前台通知
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(didBecomeActive:)
                                                name:UIApplicationDidBecomeActiveNotification
                                              object:nil];
}

//应用挂起后basic动画会停止 需重新加入
-(void)didBecomeActive:(NSNotification *)notification
{
    [image_line.layer removeAllAnimations];
    [self addLineAnimation:image_line.layer];
}

#pragma mark - session init
-(void)initSession
{
    _session = [AVCaptureSession new];
    _session.sessionPreset = AVCaptureSessionPreset1920x1080;
    
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType: AVMediaTypeVideo];
    _deviceInput = [AVCaptureDeviceInput deviceInputWithDevice: device error: nil];
    
    _output = [AVCaptureMetadataOutput new];
    [_output setMetadataObjectsDelegate: self queue: dispatch_get_main_queue()];
    _output.rectOfInterest = [self scanRect];

    if ([_session canAddInput:self.deviceInput])
    {
        [_session addInput: self.deviceInput];
    }
    
    if ([_session canAddOutput:self.output])
    {
        [_session addOutput: self.output];
    }
    
//    可用的类型  addOutput 之后才会有值
//    NSLog(@"%@",_output.availableMetadataObjectTypes);
    
//    addOutput  之后再设置  否则crash
    _output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];

    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.backgroundColor = [UIColor whiteColor].CGColor;
    _previewLayer.frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64);
    [self.view.layer addSublayer:_previewLayer];
}

/** rectOfInterest  每个值的取值范围在0-1之间 代表的是对应轴上的比例大小 以屏幕右上角为坐标原点 并且宽高的顺序要对换过来
 
 rectOfInterest是基于图像的大小裁剪的
 */
//获取扫描区域
-(CGRect)scanRect
{
    CGSize size = self.view.bounds.size;
    _showRect = CGRectMake((size.width - 284) / 2.0, (size.height - 284) / 2.0, 284, 284);
    
    CGRect rect = CGRectMake(_showRect.origin.y / size.height,
                             _showRect.origin.x / size.width,
                             _showRect.size.height / size.height,
                             _showRect.size.width / size.width);

    return rect;
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects.count)
    {
        [self.session stopRunning];
        [image_line.layer removeAllAnimations];
        image_line.hidden = YES;
        
        AVMetadataMachineReadableCodeObject *obj = metadataObjects.firstObject;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:obj.stringValue message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}


@end
