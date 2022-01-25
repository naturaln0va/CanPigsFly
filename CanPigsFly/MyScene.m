//
//  MyScene.m
//  CanPigsFly
//
//  Created by Ryan Ackermann on 3/3/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import "MyScene.h"
#import "ViewController.h"
#import "BannerViewController.h"

typedef NS_ENUM(int, Layer) {
    LayerBackground,
    LayerObstacle,
    LayerForeground,
    LayerPlayer,
    LayerUI,
    LayerFlash,
};

typedef NS_OPTIONS(int, EntityCategory) {
    EntityCategoryPlayer = 1 << 0,
    EntityCategoryObstacle = 1 << 1,
    EntityCategoryGround = 1 << 2,
};

// Gameplay - pig movment
static const float kGravity = -1870;
static const float kImpulse = 485.0;
static const float kAngularVelocity = 895;

// Gameplay - ground speed
static const float kGroundSpeed = 128.0f;
static const float kBackgroundSpeed = 42.0f;

// Gameplay - obstacle positioning
static const float kGapMultiplier = 3.1;
static const float kBottomObstacleMinFraction = 0.1;
static const float kBottomObstacleMaxFraction = 0.55;

// Gameplay - obstacle timing
static const float kFirstSpawnDelay = 1.82;
static const float kEverySpawnDelay = 1.58;

// Looks
static const int kNumForegrounds = 2;
static const int kNumFrames = 3;
static const float kMargin = 35;
static const float kAnimDelay = 0.3;
static const float kMinDegrees = -90;
static const float kMaxDegrees = 25;

static NSString *const kFontName = @"04b 30";

// App ID
static const int APP_STORE_ID = 840326296;

@interface MyScene() <SKPhysicsContactDelegate>
@end

@implementation MyScene {
    SKNode *_worldNode;
    SKTextureAtlas *_atlas;
    
    float _playableStart;
    float _playableHeight;
    
    SKSpriteNode *_player;
    CGPoint _playerVelocity;
    float _playerAngularVelocity;
    
    NSTimeInterval _lastTouchTime;
    float _lastTouchY;
    
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    
    SKAction *_oinkAction;
    SKAction *_jumpAction;
    SKAction *_hitAction;
    SKAction *_boomAction;
    SKAction *_popAction;
    SKAction *_coinAction;
    SKAction *_menuAction;
    
    SKSpriteNode *_okButton;
    SKSpriteNode *_shareButton;
    
    BOOL _hitGround;
    BOOL _hitObstacle;
    
    GameState _gameState;
    
    SKLabelNode *_scoreLabel;
    
    int _score;
}

-(id)initWithSize:(CGSize)size delegate:(id<MySceneDelegate>)delegate state:(GameState)state{
    if (self = [super initWithSize:size]) {
        
        self.delegate = delegate;
        
        _worldNode = [SKNode node];
        [self addChild:_worldNode];
        
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
        _atlas = [SKTextureAtlas atlasNamed:@"sprites"];
        
        if (state == GameStateMainMenu) {
            [self switchToMainMenu];
        } else {
            [self switchToTutorial];
        }
    }
    return self;
}

#pragma mark - Setup methods

- (void)setupBackground {
    for (int i = 0; i < kNumForegrounds; ++i) {
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"sky"];
        background.anchorPoint = CGPointMake(0, 1);
        background.position = CGPointMake(i * background.size.width, self.size.height);
        background.zPosition = LayerBackground;
        background.name = @"Background";
        [_worldNode addChild:background];
        
        _playableStart = self.size.height - background.size.height;
        _playableHeight = background.size.height;
        
        SKSpriteNode *front = [SKSpriteNode spriteNodeWithTexture:[_atlas textureNamed:@"frontBG"]];
        front.anchorPoint = CGPointMake(0, 1);
        front.position = CGPointMake(0, -(background.size.height - front.size.height));
        front.zPosition = LayerBackground;
        front.name = @"Front";
        [background addChild:front];
    }
    
    CGPoint lowerLeft = CGPointMake(0, _playableStart);
    CGPoint lowerRight = CGPointMake(self.size.width, _playableStart);
    
    self.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:lowerLeft toPoint:lowerRight];
    
    self.physicsBody.categoryBitMask = EntityCategoryGround;
    self.physicsBody.collisionBitMask = 0;
    self.physicsBody.contactTestBitMask = EntityCategoryPlayer;
}

- (void)setupForeground {
    for (int i = 0; i < kNumForegrounds; ++i) {
        SKSpriteNode *foreground =
        [SKSpriteNode spriteNodeWithImageNamed:@"ground"];
        foreground.anchorPoint = CGPointMake(0, 1);
        foreground.position = CGPointMake(i * self.size.width, _playableStart);
        foreground.zPosition = LayerForeground;
        foreground.name = @"Foreground";
        [_worldNode addChild:foreground];
    }
}

- (void)setupPlayer {
    _player = [SKSpriteNode spriteNodeWithImageNamed:@"pig0"];
    _player.position = CGPointMake(self.size.width * 0.3,
                                   _playableHeight * 0.4 + _playableStart);
    _player.zPosition = LayerPlayer;
    _player.xScale = 1.25;
    _player.yScale = 1.25;
    [_worldNode addChild:_player];
    
    CGFloat offsetX = _player.frame.size.width * _player.anchorPoint.x;
    CGFloat offsetY = _player.frame.size.height * _player.anchorPoint.y;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 4 - offsetX, 0 - offsetY);
    CGPathAddLineToPoint(path, NULL, 0 - offsetX, 24 - offsetY);
    CGPathAddLineToPoint(path, NULL, 9 - offsetX, 33 - offsetY);
    CGPathAddLineToPoint(path, NULL, 32 - offsetX, 33 - offsetY);
    CGPathAddLineToPoint(path, NULL, 44 - offsetX, 23 - offsetY);
    CGPathAddLineToPoint(path, NULL, 35 - offsetX, 2 - offsetY);
    CGPathAddLineToPoint(path, NULL, 33 - offsetX, 0 - offsetY);
    CGPathAddLineToPoint(path, NULL, 29 - offsetX, 0 - offsetY);
    CGPathAddLineToPoint(path, NULL, 29 - offsetX, 4 - offsetY);
    CGPathAddLineToPoint(path, NULL, 12 - offsetX, 5 - offsetY);
    CGPathAddLineToPoint(path, NULL, 8 - offsetX, 0 - offsetY);
    CGPathCloseSubpath(path);
    
    _player.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    
    _player.physicsBody.categoryBitMask = EntityCategoryPlayer;
    _player.physicsBody.collisionBitMask = 0;
    _player.physicsBody.contactTestBitMask = EntityCategoryObstacle | EntityCategoryGround;
    
    SKAction *moveUp = [SKAction moveByX:0 y:10 duration:0.4];
    moveUp.timingMode = SKActionTimingEaseInEaseOut;
    SKAction *moveDown = [moveUp reversedAction];
    SKAction *sequence = [SKAction sequence:@[moveUp, moveDown]];
    SKAction *repeat = [SKAction repeatActionForever:sequence];
    [_player runAction:repeat withKey:@"Wobble"];
}

- (void)setupSounds {
    _oinkAction = [SKAction playSoundFileNamed:@"oink.wav"
                             waitForCompletion:NO];
    _jumpAction = [SKAction playSoundFileNamed:@"hipHop.wav"
                            waitForCompletion:NO];
    _hitAction = [SKAction playSoundFileNamed:@"smash.wav"
                            waitForCompletion:NO];
    _boomAction = [SKAction playSoundFileNamed:@"boom.wav"
                             waitForCompletion:NO];
    _popAction = [SKAction playSoundFileNamed:@"popy.wav"
                            waitForCompletion:NO];
    _coinAction = [SKAction playSoundFileNamed:@"newCoin.wav"
                             waitForCompletion:NO];
    _menuAction = [SKAction playSoundFileNamed:@"menuSound.wav"
                             waitForCompletion:NO];
}

- (void)setupScoreLabel {
    _scoreLabel = [[SKLabelNode alloc] initWithFontNamed:kFontName];
    _scoreLabel.fontColor = [SKColor blackColor];
    _scoreLabel.position = CGPointMake(self.size.width/2,
                                       self.size.height - (kMargin + 42));
    _scoreLabel.text = @"0";
    _scoreLabel.verticalAlignmentMode =
        SKLabelVerticalAlignmentModeTop;
    _scoreLabel.zPosition = LayerUI;
    [_worldNode addChild:_scoreLabel];
}

- (void)setupScoreCard {
    if (_score > [self bestScore]) {
        [self setBestScore:_score];
    }
    
    SKSpriteNode *scorecard = [SKSpriteNode
                               spriteNodeWithImageNamed:@"Scorecard"];
    scorecard.position = CGPointMake(self.size.width * 0.5,
                                     self.size.height * 0.5);
    scorecard.name = @"Tutorial";
    scorecard.zPosition = LayerUI;
    [_worldNode addChild:scorecard];
    
    SKLabelNode *lastScore = [[SKLabelNode alloc] 
                              initWithFontNamed:kFontName];
    lastScore.fontColor = [SKColor colorWithRed:36.0/255
                                          green:45.0/255
                                           blue:23.0/255
                                          alpha:1.0];
    lastScore.position = CGPointMake(-scorecard.size.width * 0.25,
                                     -scorecard.size.height * 0.2);
    lastScore.text = [NSString stringWithFormat:@"%d", _score];
    [scorecard addChild:lastScore];
    
    SKLabelNode *bestScore = [[SKLabelNode alloc]
        initWithFontNamed:kFontName];
    bestScore.fontColor = [SKColor colorWithRed:36.0/255
          green:45.0/255
           blue:23.0/255
          alpha:1.0];
    bestScore.position = CGPointMake(scorecard.size.width * 0.25,
        -scorecard.size.height * 0.2);
    bestScore.text = [NSString stringWithFormat:@"%ld", [self bestScore]];
    [scorecard addChild:bestScore];
    
    SKSpriteNode *gameOver = [SKSpriteNode
        spriteNodeWithImageNamed:@"GameOver"];
    gameOver.position = CGPointMake(self.size.width/2,
        self.size.height/2 + scorecard.size.height/2 + kMargin + gameOver.size.height/2);
    gameOver.zPosition = LayerUI;
    [_worldNode addChild:gameOver];
    
    _okButton = [SKSpriteNode spriteNodeWithImageNamed:@"Button"];
    _okButton.name = @"OK";
    _okButton.position = CGPointMake(self.size.width * 0.25,
        self.size.height/2 - scorecard.size.height/2 - kMargin - _okButton.size.height/2);
    _okButton.zPosition = LayerUI;
    [_worldNode addChild:_okButton];
    
    SKSpriteNode *ok = [SKSpriteNode spriteNodeWithImageNamed:@"OK"];
    ok.position = CGPointMake(0, 5);;
    ok.zPosition = LayerUI;
    [_okButton addChild:ok];
    
    _shareButton = [SKSpriteNode spriteNodeWithImageNamed:@"Button"];
    _shareButton.name = @"Share";
    _shareButton.position = CGPointMake(self.size.width * 0.75,
                                    self.size.height/2 - scorecard.size.height/2 - kMargin - _okButton.size.height/2);
    _shareButton.zPosition = LayerUI;
    [_worldNode addChild:_shareButton];
    
    SKSpriteNode *share = [SKSpriteNode spriteNodeWithImageNamed:@"share"];
    share.position = CGPointMake(0, 5);
    share.zPosition = LayerUI;
    [_shareButton addChild:share];
    
    gameOver.scale = 0;
    gameOver.alpha = 0;
    SKAction *group = [SKAction group:@[
        [SKAction fadeInWithDuration:kAnimDelay],
        [SKAction scaleTo:1.0 duration:kAnimDelay]
    ]];
    group.timingMode = SKActionTimingEaseInEaseOut;
    [gameOver runAction:[SKAction sequence:@[
         [SKAction waitForDuration:kAnimDelay],
         group
     ]]];
    
    scorecard.position = CGPointMake(self.size.width * 0.5,
         -scorecard.size.height/2);
    SKAction *moveTo = [SKAction moveTo:CGPointMake(self.size.width/2, self.size.height/2)
                               duration:kAnimDelay];
    moveTo.timingMode = SKActionTimingEaseInEaseOut;
    [scorecard runAction:[SKAction sequence:@[
        [SKAction waitForDuration:kAnimDelay*2],
        moveTo
      ]]];
    
    _okButton.alpha = 0;
    _shareButton.alpha = 0;
    SKAction *fadeIn = [SKAction sequence:@[
          [SKAction waitForDuration:kAnimDelay*3],
          [SKAction fadeInWithDuration:kAnimDelay]
       ]];
    [_okButton runAction:fadeIn];
    [_shareButton runAction:fadeIn];
    
    SKAction *dingaLings = [SKAction sequence:@[
        [SKAction waitForDuration:kAnimDelay],
        _menuAction,
        [SKAction waitForDuration:kAnimDelay],
        _menuAction,
        [SKAction waitForDuration:kAnimDelay],
        _menuAction,
        [SKAction runBlock:^{
            [self switchToGameOver];
        }]
    ]];
    [self runAction:dingaLings];
}

- (void)setupTutorial {
    SKSpriteNode *tutorial = [SKSpriteNode
        spriteNodeWithImageNamed:@"Tutorial"];
    tutorial.position = CGPointMake((int)self.size.width * 0.59, (int)
        _playableHeight * 0.4 + _playableStart);
    tutorial.name = @"Tutorial";
    tutorial.zPosition = LayerUI;
    [_worldNode addChild:tutorial];
    
    SKSpriteNode *ready = [SKSpriteNode spriteNodeWithImageNamed:@"Ready"];
    ready.position = CGPointMake(self.size.width * 0.5, _playableHeight * 0.7 + (_playableStart - 22));
    ready.name = @"Tutorial";
    ready.zPosition = LayerUI;
    [_worldNode addChild:ready];
}

- (void)setupMainMenu {
    float scaleLogo = 2.0;
    SKSpriteNode *logo = [SKSpriteNode spriteNodeWithImageNamed:@"logo"];
    logo.xScale = scaleLogo;
    logo.yScale = scaleLogo;
    logo.position = CGPointMake(self.size.width/2, self.size.height * 0.75);
    logo.zPosition = LayerUI;
    [_worldNode addChild:logo];
    
    SKSpriteNode *version = [SKSpriteNode spriteNodeWithImageNamed:@"version"];
    version.position = CGPointMake(self.size.width * 0.815, logo.position.y - 75);
    version.zPosition = LayerUI;
    [_worldNode addChild:version];
    
//    SKSpriteNode *devIndacator = [SKSpriteNode spriteNodeWithImageNamed:@"dev"];
//    devIndacator.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.38);
//    devIndacator.zPosition = LayerUI;
//    [_worldNode addChild:devIndacator];
    
    SKSpriteNode *playButton = [SKSpriteNode spriteNodeWithImageNamed:@"Button"];
    playButton.position = CGPointMake(self.size.width * 0.25, self.size.height * 0.25);
    playButton.zPosition = LayerUI;
    [_worldNode addChild:playButton];
    
    SKSpriteNode *play = [SKSpriteNode spriteNodeWithImageNamed:@"start"];
    play.position = CGPointMake(0, 3);
    [playButton addChild:play];
    
    SKSpriteNode *rateButton = [SKSpriteNode spriteNodeWithImageNamed:@"Button"];
    rateButton.position = CGPointMake(self.size.width * 0.75, self.size.height * 0.25);
    rateButton.zPosition = LayerUI;
    [_worldNode addChild:rateButton];
    
    SKSpriteNode *rate = [SKSpriteNode spriteNodeWithImageNamed:@"rate"];
    rate.position = CGPointMake(0, 3);
    [rateButton addChild:rate];
    
    SKAction *pulseUp = [SKAction moveByX:0 y:10 duration:0.4];
    pulseUp.timingMode = SKActionTimingEaseInEaseOut;
    SKAction *pulseDown = [pulseUp reversedAction];
    [logo runAction:[SKAction repeatActionForever:
                     [SKAction sequence:@[pulseUp, pulseDown]]]];
    [version runAction:[SKAction repeatActionForever:
                        [SKAction sequence:@[pulseUp, pulseDown]]]];
//    [devIndacator runAction:[SKAction repeatActionForever:
//                             [SKAction sequence:@[pulseUp, pulseDown]]]];
}

- (void)setupPlayerAnimation {
    NSMutableArray *textures = [NSMutableArray array];
    
    for (int i = 0; i < kNumFrames; i++) {
        NSString *textureName = [NSString stringWithFormat:@"pig%d",i];
        [textures addObject:[_atlas textureNamed:textureName]];
    }
    
    for (int i = kNumFrames - 2; i > 0; i--) {
        NSString *textureName = [NSString stringWithFormat:@"pig%d",i];
        [textures addObject:[_atlas textureNamed:textureName]];
    }
    
    SKAction *playerAnimation = [SKAction animateWithTextures:textures timePerFrame:0.1];
    [SKAction scaleBy:1.3 duration:0];
    [_player runAction:[SKAction repeatActionForever:playerAnimation]];
}

#pragma mark - Gameplay

- (SKSpriteNode *)createObstacle {
    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"baconWall"];
    sprite.userData = [NSMutableDictionary dictionary];
    sprite.zPosition = LayerObstacle;
    
//    SKColor *randomColor = SKColorWithRGB(RandomFloatRange(43, 222), RandomFloatRange(43, 222),       RandomFloatRange(43, 222));
//    [sprite runAction:[SKAction colorizeWithColor:randomColor colorBlendFactor:1 duration:0]];
    
    CGFloat offsetX = sprite.frame.size.width * sprite.anchorPoint.x;
    CGFloat offsetY = sprite.frame.size.height * sprite.anchorPoint.y;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, 7 - offsetX, 14 - offsetY);
    CGPathAddLineToPoint(path, NULL, 2 - offsetX, 186 - offsetY);
    CGPathAddLineToPoint(path, NULL, 25 - offsetX, 257 - offsetY);
    CGPathAddLineToPoint(path, NULL, 52 - offsetX, 253 - offsetY);
    CGPathAddLineToPoint(path, NULL, 63 - offsetX, 232 - offsetY);
    CGPathAddLineToPoint(path, NULL, 53 - offsetX, 152 - offsetY);
    CGPathAddLineToPoint(path, NULL, 68 - offsetX, 137 - offsetY);
    CGPathAddLineToPoint(path, NULL, 66 - offsetX, 34 - offsetY);
    CGPathAddLineToPoint(path, NULL, 29 - offsetX, 3 - offsetY);
    CGPathAddLineToPoint(path, NULL, 12 - offsetX, 1 - offsetY);
    
    CGPathCloseSubpath(path);
    
    sprite.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    
    
//    sprite.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:sprite.size];
    sprite.physicsBody.categoryBitMask = EntityCategoryObstacle;
    sprite.physicsBody.collisionBitMask = 0;
    sprite.physicsBody.contactTestBitMask = EntityCategoryPlayer;
    return sprite;
}

- (void)spawnObstacle {
    SKSpriteNode *bottomObstacle = [self createObstacle];
    float startX = self.size.width + bottomObstacle.size.width/2;
    
    float bottomObstacleMin = (_playableStart - bottomObstacle.size.height/2) +
    _playableHeight * kBottomObstacleMinFraction;
    float bottomObstacleMax = (_playableStart - bottomObstacle.size.height/2) +
    _playableHeight * kBottomObstacleMaxFraction;
    
    bottomObstacle.position = CGPointMake(startX, RandomFloatRange(bottomObstacleMin,
                                                                   bottomObstacleMax));
    bottomObstacle.name = @"BottomObstacle";
    [_worldNode addChild:bottomObstacle];
    
    SKSpriteNode *topObstacle = [self createObstacle];
//    topObstacle.zRotation = DegreesToRadians(180);
    topObstacle.position = CGPointMake(startX, bottomObstacle.position.y + bottomObstacle.size.height/2 + topObstacle.size.height/2 + _player.size.height * kGapMultiplier);
    topObstacle.name = @"TopObstacle";
    [_worldNode addChild:topObstacle];
    
    float moveX = self.size.width + topObstacle.size.width;
    float moveDuration = moveX / kGroundSpeed;
    SKAction *sequence = [SKAction sequence:@[
        [SKAction moveByX:-moveX y:0 duration:moveDuration],
        [SKAction removeFromParent]
    ]];
    
    [topObstacle runAction:sequence];
    [bottomObstacle runAction:sequence];
}

- (void)startSpawning {
    SKAction *firstDelay = [SKAction waitForDuration:kFirstSpawnDelay];
    SKAction *spawn = [SKAction performSelector:@selector(spawnObstacle) onTarget:self];
    SKAction *everyDelay = [SKAction waitForDuration:kEverySpawnDelay];
    SKAction *spawnSequence = [SKAction sequence:@[spawn, everyDelay]];
    SKAction *foreverSpawn = [SKAction repeatActionForever:spawnSequence];
    SKAction *overallSequence = [SKAction sequence:@[firstDelay, foreverSpawn]];
    [self runAction:overallSequence withKey:@"Spawn"];
}

- (void)stopSpawning {
    [self removeActionForKey:@"Spawn"];
    [_worldNode enumerateChildNodesWithName:@"TopObstacle" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeAllActions];
    }];
    [_worldNode enumerateChildNodesWithName:@"BottomObstacle" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeAllActions];
    }];
}

- (void)bouncePiggy {
    // Play Sound
    [self runAction:_jumpAction];
    
    // Apply Impulse
    _playerVelocity = CGPointMake(0, kImpulse);
    
    _playerAngularVelocity = DegreesToRadians(kAngularVelocity);
    _lastTouchTime = _lastUpdateTime;
    _lastTouchY = _player.position.y;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    
    switch (_gameState) {
        case GameStateMainMenu:
            if (touchLocation.y < self.size.height * 0.15) {
                // about me
            } else if (touchLocation.x < self.size.width * 0.6) {
                [self switchToNewGame:GameStateTutorial];
            } else {
                [self rateApp];
            }
            break;
        case GameStateTutorial:
            [self switchToPlay];
            break;
        case GameStatePlay:
            [self bouncePiggy];
            break;
        case GameStateFalling:
            break;
        case GameStateShowingScore:
            break;
        case GameStateGameOver:
            if (touchLocation.x < self.size.width/2) {
                [self switchToNewGame:GameStateMainMenu];
            } else {
                [self shareScore];
            }
            break;
    }
}

#pragma mark - Switch state

- (void)switchToShowScore {
    _gameState = GameStateShowingScore;
    
    [_player removeAllActions];
    [self stopSpawning];
    
    [self setupScoreCard];
}

- (void)switchToFalling {
    _gameState = GameStateFalling;
    
    // Screen shake
    SKAction *shake = [SKAction skt_screenShakeWithNode:_worldNode
                                                 amount:CGPointMake(0, 7.0)
                                           oscillations:10
                                               duration:1.0];
    [_worldNode runAction:shake];
    
    SKSpriteNode *whiteNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:self.size];
    whiteNode.position = CGPointMake(self.size.width/2, self.size.height/2);
    whiteNode.zPosition = LayerFlash;
    [_worldNode addChild:whiteNode];
    [whiteNode runAction:[SKAction sequence:@[
        [SKAction waitForDuration:0.01],
        [SKAction removeFromParent]
    ]]];
    
    [self runAction:[SKAction sequence:@[
        _boomAction,
        [SKAction waitForDuration:0.1],
        _hitAction
    ]]];
    
    [_player removeAllActions];
    SKAction *fadeOut = [SKAction fadeAlphaTo:0.0 duration:0.05];
    SKAction *fadeIn = [SKAction fadeAlphaTo:1.0 duration:0.09];
    SKAction *switchToBacon = [SKAction setTexture:
                               [SKTexture textureWithImageNamed:@"baconTransform"]
                                            resize:YES];
    
    [_player runAction:[SKAction sequence:@[fadeOut,
                                            switchToBacon,
                                            fadeIn]]];
    _player.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(20, 50)];
    // Testing of the bacon collision size
    //[_player skt_attachDebugRectWithSize:CGSizeMake(20, 50) color:[SKColor redColor]];
    [self stopSpawning];
}

- (void)switchToGameOver {
    _gameState = GameStateGameOver;
    
}

- (void)switchToNewGame:(GameState)state {
    [self runAction:_popAction];
    
    SKScene *newScene = [[MyScene alloc] initWithSize:self.size delegate:self.delegate state:state];
    SKTransition *transition = [SKTransition fadeWithColor:[SKColor blackColor] duration:0.5];
    [self.view presentScene:newScene transition:transition];
}

- (void)switchToTutorial {
    _gameState = GameStateTutorial;
    [self setupBackground];
    [self setupForeground];
    [self setupPlayer];
    [self setupSounds];
    [self setupScoreLabel];
    [self setupTutorial];
    [self setupPlayerAnimation];

}

- (void)switchToPlay {
    // Set state
    _gameState = GameStatePlay;
    
    // Remove tutorial
    [_worldNode enumerateChildNodesWithName:@"Tutorial" usingBlock:^(SKNode *node, BOOL *stop) {
        [node runAction:[SKAction sequence:@[
                                             [SKAction fadeOutWithDuration:0.5],
                                             [SKAction removeFromParent]
                                             ]]];
    }];
    
    // Remove wobble
    [_player removeActionForKey:@"Wobble"];
    
    // Start spawning
    [self startSpawning];
    
    // Move player
    [self bouncePiggy];
}

- (void)switchToMainMenu {
    _gameState = GameStateMainMenu;
    
    [self setupBackground];
    [self setupForeground];
    [self setupPlayer];
    [self setupSounds];
    [self setupMainMenu];
    [self setupPlayerAnimation];
    
}

#pragma mark - Share 

- (void)shareScore {
    NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%d?mt=8", APP_STORE_ID];
    NSURL *url = [NSURL URLWithString:urlString];
    
    UIImage *screenshot = [self.delegate screenShot];
    
    NSString *initialTextString = [NSString stringWithFormat:@"Woohoo!! I scored %d points in Wiggly Piggly", _score];
    [self.delegate shareString:initialTextString url:url image:screenshot];
}

- (void)rateApp {
    NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%d?mt=8", APP_STORE_ID];
    NSURL *url = [NSURL URLWithString:urlString];
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - Updates

- (void)checkHitObstacle {
    if (_hitObstacle) {
        _hitObstacle = NO;
        [self switchToFalling];
    }
}

- (void)checkHitGround {
    if (_hitGround) {
        //NSLog(@"Ouch, that's the ground!");
        _hitGround = NO;
        _playerVelocity = CGPointZero;
        _player.position = CGPointMake(_player.position.x, _playableStart + _player.size.width / 2);
        _player.zRotation = DegreesToRadians(-90);
        [self runAction:_oinkAction];
        [self switchToShowScore];
    }
}

- (void)updatePlayer {
    
    // Apply gravity
    CGPoint gravity = CGPointMake(0, kGravity);
    CGPoint gravityStep = CGPointMultiplyScalar(gravity, _dt);
    _playerVelocity = CGPointAdd(_playerVelocity, gravityStep);
    
    // Apply Velocity
    CGPoint velocityStep = CGPointMultiplyScalar(_playerVelocity, _dt);
    _player.position = CGPointAdd(_player.position, velocityStep);
    _player.position = CGPointMake(_player.position.x, MIN(_player.position.y, self.size.height));
    
    // Temp hault
//    if (_player.position.y - _player.size.height/2 <= _playableStart) {
//        _player.position = CGPointMake(_player.position.x,
//                                       _playableStart + _player.size.height/2);
//        return;
//    }
    
    if (_player.position.y < _lastTouchY) {
        _playerAngularVelocity = -DegreesToRadians(kAngularVelocity);
    }
    
    // Rotate player
    float angularStep = _playerAngularVelocity *_dt;
    _player.zRotation += angularStep;
    _player.zRotation = MIN(MAX(_player.zRotation, DegreesToRadians(kMinDegrees)), DegreesToRadians(kMaxDegrees));
}

- (void)updateScore {
    
    [_worldNode enumerateChildNodesWithName:@"BottomObstacle" usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *obstacle = (SKSpriteNode *)node;
        
        NSNumber *passed = obstacle.userData[@"Passed"];
        if (passed && passed.boolValue) return;
        
        if (_player.position.x > obstacle.position.x + obstacle.size.width/2){
            _score++;
            _scoreLabel.text = [NSString stringWithFormat:@"%d",
                                _score];
            [self runAction:_coinAction];
            obstacle.userData[@"Passed"] = @YES;
        }
    }];
    
}

- (void)updateBackground {
    [_worldNode enumerateChildNodesWithName:@"Background" usingBlock:^(SKNode *node, BOOL *stop){
        SKSpriteNode *background = (SKSpriteNode *)node;
        
        CGPoint moveAmt = CGPointMake(-(kBackgroundSpeed / 1.5) * _dt, 0);
        background.position = CGPointAdd(background.position, moveAmt);
        
        if (background.position.x < -background.size.width) {
            background.position = CGPointAdd(background.position,
                                             CGPointMake(background.size.width * kNumForegrounds, 0));
        }
    }];
}

- (void)updateForeground{
    [_worldNode enumerateChildNodesWithName:@"Foreground" usingBlock:^(SKNode *node, BOOL *stop){
        SKSpriteNode *foreground = (SKSpriteNode *)node;
        CGPoint moveAmt = CGPointMake(-kGroundSpeed * _dt, 0);
        foreground.position = CGPointAdd(foreground.position, moveAmt);
        
        if (foreground.position.x < -foreground.size.width) {
            foreground.position = CGPointAdd(foreground.position,
                                             CGPointMake(foreground.size.width * kNumForegrounds, 0));
        }
    }];
}

-(void)update:(CFTimeInterval)currentTime {
    if (_lastUpdateTime) {
        _dt = currentTime - _lastUpdateTime;
    } else {
        _dt = 0;
    }
    _lastUpdateTime = currentTime;
    
    switch (_gameState) {
        case GameStateMainMenu:
            break;
        case GameStateTutorial:
            break;
        case GameStatePlay:
            [self checkHitGround];
            [self checkHitObstacle];
            [self updateForeground];
            [self updateBackground];
            [self updatePlayer];
            [self updateScore];
            break;
        case GameStateFalling:
            [self updatePlayer];
            [self checkHitGround];
            break;
        case GameStateShowingScore:
            break;
        case GameStateGameOver:
            break;
    }
}

#pragma mark - Score


- (long)bestScore {
    return [[NSUserDefaults standardUserDefaults]
            integerForKey:@"BestScore"];
}

- (void)setBestScore:(int)bestScore {
    [[NSUserDefaults standardUserDefaults] setInteger:bestScore
                                               forKey:@"BestScore"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Collision Detection

- (void)didBeginContact:(SKPhysicsContact *)contact {
    SKPhysicsBody *other = (contact.bodyA.categoryBitMask == EntityCategoryPlayer ? contact.bodyB : contact.bodyA);
    if (other.categoryBitMask == EntityCategoryGround) {
        _hitGround = YES;
        return;
    }
    if (other.categoryBitMask == EntityCategoryObstacle) {
        _hitObstacle = YES;
        return;
    }
}

@end
