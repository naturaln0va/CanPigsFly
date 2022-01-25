//
//  MyScene.h
//  CanPigsFly
//

//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef NS_ENUM(int, GameState) {
    GameStateMainMenu,
    GameStateTutorial,
    GameStatePlay,
    GameStateFalling,
    GameStateShowingScore,
    GameStateGameOver,
};

@protocol MySceneDelegate
- (UIImage *)screenShot;
- (void)shareString:(NSString *)string url:(NSURL *)url image:(UIImage *)image;
@end

@interface MyScene : SKScene

- (id)initWithSize:(CGSize)size delegate:(id<MySceneDelegate>)delegate state:(GameState)state;

@property (strong, nonatomic) id <MySceneDelegate> delegate;

@end
