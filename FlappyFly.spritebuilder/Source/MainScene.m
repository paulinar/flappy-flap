//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"
#import "Obstacle.h"

static const CGFloat scrollSpeed = 80.f;
static const CGFloat firstObstaclePosition = 280.f;
static const CGFloat distanceBetweenObstacles = 160.f;

// enum to force ground to be drawn above the pipes
typedef NS_ENUM(NSInteger, DrawingOrder) {
    DrawingOrderPipes,
    DrawingOrderGround,
    DrawingOrdeHero
};

NSInteger _points;
CCLabelTTF *_scoreLabel;

@implementation MainScene {
    CCSprite *_hero;
    CCPhysicsNode *_physicsNode;
    CCNode *_ground1;
    CCNode *_ground2;
    NSArray *_grounds; // an array to store & loop over ground pieces
    NSTimeInterval _sinceTouch; // keep track of time since last touch
    NSMutableArray *_obstacles; // keep track of obstacles created
    CCButton *_restartButton;
    BOOL _gameOver;
    CGFloat _scrollSpeed;
}

- (void)didLoadFromCCB {
    self.userInteractionEnabled = TRUE;
    _grounds = @[_ground1, _ground2];
    for (CCNode *ground in _grounds) {
        // set collision txpe
        ground.physicsBody.collisionType = @"level";
        ground.zOrder = DrawingOrderGround;
    }
    // set this class as delegate
    _physicsNode.collisionDelegate = self;
    // set collision txpe
    _hero.physicsBody.collisionType = @"hero";
    _hero.zOrder = DrawingOrdeHero;
    _obstacles = [NSMutableArray array];
    [self spawnNewObstacle];
    [self spawnNewObstacle];
    [self spawnNewObstacle];
    _scrollSpeed = 80.f;
}

- (void)update:(CCTime)delta {
    
    // to move the fly
    _hero.position = ccp(_hero.position.x + delta * scrollSpeed, _hero.position.y);
    
    // to scroll the game
    _physicsNode.position = ccp(_physicsNode.position.x - (scrollSpeed *delta), _physicsNode.position.y);
    
    // loop the ground & check for each ground piece to see if it has moved off the screen
    for (CCNode *ground in _grounds) {
        // get the world position of the ground
        // convertToNodeSpace method gets position in the MainScene (self)
        CGPoint groundWorldPosition = [_physicsNode convertToWorldSpace:ground.position];
        // get the screen position of the ground
        CGPoint groundScreenPosition = [self convertToNodeSpace:groundWorldPosition];
        // if the left corner is one complete width off the screen, move it to the right
        if (groundScreenPosition.x <= (-1 * ground.contentSize.width)) {
            ground.position = ccp(ground.position.x + 2 * ground.contentSize.width, ground.position.y);
        }
    }
    
    // clamp velocity so flappy fly doesn't fly off the screen
    float yVelocity = clampf(_hero.physicsBody.velocity.y, -1 * MAXFLOAT, 200.f);
    _hero.physicsBody.velocity = ccp(0, yVelocity);
    
    // add rotation functionality
    _sinceTouch += delta;
    _hero.rotation = clampf(_hero.rotation, -30.f, 90.f);
    if (_hero.physicsBody.allowsRotation) {
        float angularVelocity = clampf(_hero.physicsBody.angularVelocity, -2.f, 1.f);
        _hero.physicsBody.angularVelocity = angularVelocity;
    }
    if ((_sinceTouch > 0.5f)) {
        [_hero.physicsBody applyAngularImpulse:-40000.f*delta];
    }
    
    // check which obstacles flew offscreen, and which ones to add
    NSMutableArray *offScreenObstacles = nil;
    for (CCNode *obstacle in _obstacles) {
        CGPoint obstacleWorldPosition = [_physicsNode convertToWorldSpace:obstacle.position];
        CGPoint obstacleScreenPosition = [self convertToNodeSpace:obstacleWorldPosition];
        if (obstacleScreenPosition.x < -obstacle.contentSize.width) {
            if (!offScreenObstacles) {
                offScreenObstacles = [NSMutableArray array];
            }
            [offScreenObstacles addObject:obstacle];
        }
    }
    for (CCNode *obstacleToRemove in offScreenObstacles) {
        [obstacleToRemove removeFromParent];
        [_obstacles removeObject:obstacleToRemove];
        // for each removed obstacle, add a new one
        [self spawnNewObstacle];
    }
}

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    if (!_gameOver) {
        [_hero.physicsBody applyImpulse:ccp(0, 400.f)];
        [_hero.physicsBody applyAngularImpulse:10000.f];
        _sinceTouch = 0.f;
    }
}

// takes care of generating new obstacles
- (void)spawnNewObstacle {
    CCNode *previousObstacle = [_obstacles lastObject];
    CGFloat previousObstacleXPosition = previousObstacle.position.x;
    if (!previousObstacle) {
        // this is the first obstacle
        previousObstacleXPosition = firstObstaclePosition;
    }
    Obstacle *obstacle = (Obstacle *)[CCBReader load:@"Obstacle"];
    obstacle.position = ccp(previousObstacleXPosition + distanceBetweenObstacles, 0);
    [obstacle setupRandomPosition];
    [_physicsNode addChild:obstacle];
    [_obstacles addObject:obstacle];
    
    obstacle.zOrder = DrawingOrderPipes;
}

// gets called when fly collides with an object
-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair hero:(CCNode *)hero level:(CCNode *)level {
    [self gameOver];
    return TRUE;
}

- (void)restart {
    CCScene *scene = [CCBReader loadAsScene:@"MainScene"];
    [[CCDirector sharedDirector] replaceScene:scene];
}

- (void)gameOver {
    if (!_gameOver) {
        _scrollSpeed = 0.f;
        _gameOver = TRUE;
        _restartButton.visible = TRUE;
        _hero.rotation = 90.f;
        _hero.physicsBody.allowsRotation = FALSE;
        [_hero stopAllActions];
        CCActionMoveBy *moveBy = [CCActionMoveBy actionWithDuration:0.2f position:ccp(-2, 2)];
        CCActionInterval *reverseMovement = [moveBy reverse];
        CCActionSequence *shakeSequence = [CCActionSequence actionWithArray:@[moveBy, reverseMovement]];
        CCActionEaseBounce *bounce = [CCActionEaseBounce actionWithAction:shakeSequence];
        [self runAction:bounce];
    }
}

// another collision handler for when the player reaches the goal

@end