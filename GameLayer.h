//
//  GameLayer.h
//  brendan game
//
//  Created by Francis Tseng on 12/1/13.
//  Copyright 2013 Francis Tseng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"
#import "CCPhysicsSprite.h"
#import "MyContactListener.h"

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 32

@interface GameLayer : CCLayer {
    CCTexture2D *spriteTexture_;	// weak ref
	b2World* world;					// strong ref
	GLESDebugDraw *m_debugDraw;		// strong ref
    CGSize size;
    CCPhysicsSprite *playerSprite;
    BOOL right;                     // direction player is moving
    MyContactListener* _contactListener;
    int score;
    CCLabelTTF *scoreLabel;
    int runningTime;
}

+(CCScene *) scene;

@end
