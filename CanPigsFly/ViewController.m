//
//  ViewController.m
//  CanPigsFly
//
//  Created by Ryan Ackermann on 3/3/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import "ViewController.h"
#import "MyScene.h"

@interface ViewController() <MySceneDelegate>
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = NO;
    skView.showsNodeCount = NO;
    
    // Create and configure the scene.
    SKScene * scene = [[MyScene alloc]initWithSize:skView.bounds.size delegate:self state:GameStateMainMenu];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:scene];
    
    // iAd jargon
    //ADBannerView *adView = [[ADBannerView alloc] initWithFrame:CGRectZero];
//    UIView *adView = [[UIView alloc] initWithFrame:CGRectZero];
//
//    [skView addSubview:adView];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (UIImage *)screenShot{
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, 1.0);
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
- (void)shareString:(NSString *)string url:(NSURL *)url image:(UIImage *)image{
    UIActivityViewController *vc = [[UIActivityViewController alloc]
                                    initWithActivityItems:@[string, url, image]
                                    applicationActivities:nil];
    vc.excludedActivityTypes = @[UIActivityTypeAddToReadingList,
                                 UIActivityTypeAirDrop,
                                 UIActivityTypeAssignToContact,
                                 UIActivityTypePrint];
    [self presentViewController:vc animated:YES completion:nil];
    
}

#pragma mark - iAd Delegate method

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    [UIView beginAnimations:nil context:nil];
    
    [UIView setAnimationDuration:1];
    
    [banner setAlpha:1];
    
    [UIView commitAnimations];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    [UIView beginAnimations:nil context:nil];
    
    [UIView setAnimationDuration:1];
    
    [banner setAlpha:0];
    
    [UIView commitAnimations];
}

@end
