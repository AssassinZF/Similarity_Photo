//
//  ViewController.m
//  EqualImage
//
//  Created by zhanfeng on 2017/6/20.
//  Copyright © 2017年 lzf. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    NSInteger selectIndex;
}
@property (weak, nonatomic) IBOutlet UIButton *button1;
@property (weak, nonatomic) IBOutlet UIButton *button2;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}
- (IBAction)clickStart:(id)sender {
    
    if (self.button1.currentBackgroundImage == nil || self.button2.currentBackgroundImage == nil) {
        return;
    }
    
    UIImage *image1 = self.button1.currentBackgroundImage;
    UIImage *smallImage = [self OriginImage:image1 scaleToSize:CGSizeMake(8, 8)];
    smallImage = [self getGrayImage:smallImage];
    NSString *has1 = [self myHash:smallImage];
    NSLog(@"has1 === %@",has1);
    
    
    UIImage *image2 = self.button2.currentBackgroundImage;
    UIImage *smallImage2 = [self OriginImage:image2 scaleToSize:CGSizeMake(8, 8)];
    smallImage2 = [self getGrayImage:smallImage2];
    NSString *has2 = [self myHash:smallImage2];
    NSLog(@"has2 === %@",has2);
    
    NSInteger value = 0;
    for (NSInteger indx = 0;indx < has1.length  ; indx++) {
        NSString *s1 = [has1 substringWithRange:NSMakeRange(indx, 1)];
        NSString *s2 = [has2 substringWithRange:NSMakeRange(indx, 1)];
        if (![s1 isEqualToString:s2]) {
            value++;
        }
    }
    
    if (value > 5) {
        NSLog(@"不相似");
        self.resultLabel.text = [NSString stringWithFormat:@"不相似 value:%ld",(long)value];
    }else{
        NSLog(@"相似");
        self.resultLabel.text = [NSString stringWithFormat:@"相似 value:%ld",(long)value];

    }

}

- (IBAction)clickButton1:(id)sender {
    UIButton *button = (UIButton *)sender;
    selectIndex = button.tag;
    [self getImageFromIpc];
    
}

- (void)getImageFromIpc
{
    // 1.判断相册是否可以打开
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) return;
    // 2. 创建图片选择控制器
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    /**
     typedef NS_ENUM(NSInteger, UIImagePickerControllerSourceType) {
     UIImagePickerControllerSourceTypePhotoLibrary, // 相册
     UIImagePickerControllerSourceTypeCamera, // 用相机拍摄获取
     UIImagePickerControllerSourceTypeSavedPhotosAlbum // 相簿
     }
     */
    // 3. 设置打开照片相册类型(显示所有相簿)
    ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    // ipc.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    // 照相机
    // ipc.sourceType = UIImagePickerControllerSourceTypeCamera;
    // 4.设置代理
    ipc.delegate = self;
    // 5.modal出这个控制器
    [self presentViewController:ipc animated:YES completion:nil];
}

#pragma mark -- <UIImagePickerControllerDelegate>--
// 获取图片后的操作
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    // 销毁控制器
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIButton *button = [self.view viewWithTag:selectIndex];
    [button setBackgroundImage:info[UIImagePickerControllerOriginalImage] forState:UIControlStateNormal];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//第一步，缩小尺寸。将图片缩小到8x8的尺寸，总共64个像素。这一步的作用是去除图片的细节，只保留结构、明暗等基本信息，摒弃不同尺寸、比例带来的图片差异。
-(UIImage * ) OriginImage:(UIImage *)image scaleToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);  //size 为CGSize类型，即你所需要的图片尺寸
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;   //返回的就是已经改变的图片
}


//第二步，简化色彩。将缩小后的图片，转为64级灰度。也就是说，所有像素点总共只有64种颜色
-(UIImage*)getGrayImage:(UIImage*)sourceImage
{
    int width = sourceImage.size.width;
    int height = sourceImage.size.height;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate (nil,width,height,8,0,colorSpace,kCGImageAlphaNone);
    CGColorSpaceRelease(colorSpace);
    if (context == NULL) {
        return nil;
    }
    CGContextDrawImage(context,CGRectMake(0, 0, width, height), sourceImage.CGImage);
    UIImage *grayImage = [UIImage imageWithCGImage:CGBitmapContextCreateImage(context)];
    CGContextRelease(context);
    return grayImage;
}

-(NSString *) myHash:(UIImage *) img
{
    unsigned char* pixelData = [self grayscalePixels:img];
    
    int total = 0;
    int ave = 0;
    for (int i = 0; i < img.size.height; i++) {
        for (int j = 0; j < img.size.width; j++) {
            total += (int)pixelData[(i*((int)img.size.width))+j];
        }
    }
    ave = total/64;
    NSMutableString *result = [[NSMutableString alloc] init];
    for (int i = 0; i < img.size.height; i++) {
        for (int j = 0; j < img.size.width; j++) {
            int a = (int)pixelData[(i*((int)img.size.width))+j];
            if(a >= ave)
            {
                [result appendString:@"1"];
            }
            else
            {
                [result appendString:@"0"];
            }
        }
    }
    return result;
}

-(unsigned char*) grayscalePixels:(UIImage *) image
{
    // The amount of bits per pixel, in this case we are doing grayscale so 1 byte = 8 bits
#define BITS_PER_PIXEL 8
    // The amount of bits per component, in this it is the same as the bitsPerPixel because only 1 byte represents a pixel
#define BITS_PER_COMPONENT (BITS_PER_PIXEL)
    // The amount of bytes per pixel, not really sure why it asks for this as well but it's basically the bitsPerPixel divided by the bits per component (making 1 in this case)
#define BYTES_PER_PIXEL (BITS_PER_PIXEL/BITS_PER_COMPONENT)
    
    // Define the colour space (in this case it's gray)
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceGray();
    
    // Find out the number of bytes per row (it's just the width times the number of bytes per pixel)
    size_t bytesPerRow = image.size.width * BYTES_PER_PIXEL;
    // Allocate the appropriate amount of memory to hold the bitmap context
    unsigned char* bitmapData = (unsigned char*) malloc(bytesPerRow*image.size.height);
    
    // Create the bitmap context, we set the alpha to none here to tell the bitmap we don't care about alpha values
    CGContextRef context = CGBitmapContextCreate(bitmapData,image.size.width,image.size.height,BITS_PER_COMPONENT,bytesPerRow,colourSpace,kCGImageAlphaNone);
    
    // We are done with the colour space now so no point in keeping it around
    CGColorSpaceRelease(colourSpace);
    
    // Create a CGRect to define the amount of pixels we want
    CGRect rect = CGRectMake(0.0,0.0,image.size.width,image.size.height);
    // Draw the bitmap context using the rectangle we just created as a bounds and the Core Graphics Image as the image source
    CGContextDrawImage(context,rect,image.CGImage);
    // Obtain the pixel data from the bitmap context
    unsigned char* pixelData = (unsigned char*)CGBitmapContextGetData(context);
    
    // Release the bitmap context because we are done using it
    CGContextRelease(context);
    
    return pixelData;
#undef BITS_PER_PIXEL
#undef BITS_PER_COMPONENT
}


@end
