//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"
static const CGFloat scrollSpeed = 80.f;
@implementation MainScene {
    CCSprite *_hero;
    CCPhysicsNode *_physicsNode;
    CCNode *_ground1;
    CCNode *_ground2;
    NSArray *_grounds; // an array to store & loop over ground pieces
}

- (void)didLoadFromCCB {
    // an array to store & loop over ground pieces
    _grounds = @[_ground1, _ground2];
    self.userInteractionEnabled = TRUE;
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
}
@end