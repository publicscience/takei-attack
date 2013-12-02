//
//  GameLayer.mm
//  brendan game
//
//  Created by Francis Tseng on 12/1/13.
//  Copyright 2013 Francis Tseng. All rights reserved.
//

#import "GameLayer.h"

#include <stdlib.h>

enum {
	kTagParentNode = 1,
    ground = 2,
    player = 3,
    obstacle = 4
};


@implementation GameLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	GameLayer *layer = [GameLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	if( (self=[super init])) {
		
		// enable events
		
		self.touchEnabled = YES;
		self.accelerometerEnabled = YES;
		size = [CCDirector sharedDirector].winSize;
        
        // add background
        CCSprite* background = [CCSprite spriteWithFile:@"background.png"];
        background.position = ccp(size.width/2, size.height/2);
        [background setScaleX:size.width/background.contentSize.width];
        [background setScaleY:size.height/background.contentSize.height];
        [self addChild:background z:0];
        
        // Scoring
        score = 0;
        scoreLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i", score] fontName:@"Helvetica Neue" fontSize:32];
		[scoreLabel setColor:ccc3(255,255,255)];
		scoreLabel.position = ccp(size.width/2, size.height/2);
        [self addChild:scoreLabel z:0];
		
		// init physics
		[self initPhysics];
        
        // create player sprite (with physics!)
        playerSprite = [CCPhysicsSprite spriteWithFile:@"player.png"];
        float playerScale = 0.1;
        CGPoint playerPos = ccp(size.width/2, playerSprite.contentSize.height * playerScale);
        [playerSprite setScale:playerScale];
        [self addChild:playerSprite];
        playerSprite.tag = player;
        [playerSprite setPTMRatio:PTM_RATIO];
        [playerSprite setB2Body:[self setupBody:playerPos withSprite:playerSprite]];
        playerSprite.position = playerPos;  // have to set position up after the body

		// collision listening
        _contactListener = new MyContactListener();
        world->SetContactListener(_contactListener);
        
        
		//Set up sprite
		
#if 1
		// Use batch node. Faster
		CCSpriteBatchNode *parent = [CCSpriteBatchNode batchNodeWithFile:@"blocks.png" capacity:100];
		spriteTexture_ = [parent texture];
#else
		// doesn't use batch node. Slower
		spriteTexture_ = [[CCTextureCache sharedTextureCache] addImage:@"blocks.png"];
		CCNode *parent = [CCNode node];
        
#endif
		[self addChild:parent z:0 tag:kTagParentNode];
				
		[self scheduleUpdate];
        
        // Spawn blocks regularly.
        [self schedule:@selector(updateTime:) interval:1.0f];
	}
	return self;
}

-(void) dealloc
{
	delete world;
	world = NULL;
	
	delete m_debugDraw;
	m_debugDraw = NULL;
	
	[super dealloc];
}

-(b2Body*) setupBody:(CGPoint)p withSprite:(CCSprite*)sprite
{
    // Define the dynamic body.
	//Set up a 1m squared box in the physics world
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
    bodyDef.userData = sprite;
	b2Body *body = world->CreateBody(&bodyDef);
	
	// Define another box shape for our dynamic body.
	b2PolygonShape dynamicBox;
	dynamicBox.SetAsBox(.5f, .5f);//These are mid points for our 1m box
	
	// Define the dynamic body fixture.
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &dynamicBox;
	fixtureDef.density = 1.0f;
	fixtureDef.friction = 0.3f;
	body->CreateFixture(&fixtureDef);
    // body->SetGravityScale(0);
    
    return body;
}

-(void) initPhysics
{
	b2Vec2 gravity;
	gravity.Set(0.0f, -10.0f);
	world = new b2World(gravity);
	
	
	// Do we want to let bodies sleep?
	world->SetAllowSleeping(true);
	
	world->SetContinuousPhysics(true);
	
	m_debugDraw = new GLESDebugDraw( PTM_RATIO );
	world->SetDebugDraw(m_debugDraw);
	
	uint32 flags = 0;
	flags += b2Draw::e_shapeBit;
	//		flags += b2Draw::e_jointBit;
	//		flags += b2Draw::e_aabbBit;
	//		flags += b2Draw::e_pairBit;
	//		flags += b2Draw::e_centerOfMassBit;
	m_debugDraw->SetFlags(flags);
	
	
	// Define the ground body.
	b2BodyDef groundBodyDef;
	groundBodyDef.position.Set(0, 0); // bottom-left corner
	
	// Call the body factory which allocates memory for the ground body
	// from a pool and creates the ground box shape (also from a pool).
	// The body is also added to the world.
	b2Body* groundBody = world->CreateBody(&groundBodyDef);
	
	// Define the ground box shape.
	b2EdgeShape groundBox;
	
	// bottom
	
	groundBox.Set(b2Vec2(0,0), b2Vec2(size.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// top
//	groundBox.Set(b2Vec2(0,size.height/PTM_RATIO), b2Vec2(size.width/PTM_RATIO,size.height/PTM_RATIO));
//	groundBody->CreateFixture(&groundBox,0);
	
	// left
	groundBox.Set(b2Vec2(0,size.height/PTM_RATIO), b2Vec2(0,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// right
	groundBox.Set(b2Vec2(size.width/PTM_RATIO,size.height/PTM_RATIO), b2Vec2(size.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
}

//-(void) draw
//{
//	//
//	// IMPORTANT:
//	// This is only for debug purposes
//	// It is recommend to disable it
//	//
//	[super draw];
//	
//	ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
//	
//	kmGLPushMatrix();
//	
//	world->DrawDebugData();
//	
//	kmGLPopMatrix();
//}

-(void) addNewSpriteAtPosition:(CGPoint)p
{
    
	CCNode *parent = [self getChildByTag:kTagParentNode];
	
	//We have a 64x64 sprite sheet with 4 different 32x32 images.  The following code is
	//just randomly picking one of the images
//	int idx = (CCRANDOM_0_1() > .5 ? 0:1);
//	int idy = (CCRANDOM_0_1() > .5 ? 0:1);
//	CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithTexture:spriteTexture_ rect:CGRectMake(32 * idx,32 * idy,32,32)];
    CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithTexture:spriteTexture_ rect:CGRectMake(0,0,32,32)];
    sprite.tag = obstacle;

	[parent addChild:sprite];
	
	[sprite setPTMRatio:PTM_RATIO];
	[sprite setB2Body:[self setupBody:p withSprite:sprite]];
	[sprite setPosition: ccp( p.x, p.y)];
    
}

-(void) update: (ccTime) dt
{
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 8;
	int32 positionIterations = 1;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	world->Step(dt, velocityIterations, positionIterations);
    
    // do stuff on collisions
    std::vector<MyContact>::iterator pos;
    std::vector<b2Body *>toDestroy;
    for(pos = _contactListener->_contacts.begin();
        pos != _contactListener->_contacts.end(); ++pos) {
        MyContact contact = *pos;
        bool playerHit = false;
        
        b2Body *bodyA = contact.fixtureA->GetBody();
        b2Body *bodyB = contact.fixtureB->GetBody();
        
        // Detect when player is hit
        if (bodyA->GetUserData() != NULL && bodyB->GetUserData() != NULL) {
            CCSprite* bodyASprite = (CCSprite*) bodyA->GetUserData();
            CCSprite* bodyBSprite = (CCSprite*) bodyB->GetUserData();
            
            // Player was hit!
            if (bodyASprite.tag == player || bodyBSprite.tag == player) {
                playerHit = true;
                [self updateScoreBy:-10000];
            }
            
        // Detect when obstacle hits ground
        } else {
            CCSprite *sprite;
            b2Body *body;
            if (bodyA->GetUserData() != NULL) {
                sprite = (CCSprite*) bodyA->GetUserData();
                body = bodyA;
            } else if (bodyB->GetUserData() != NULL) {
                sprite = (CCSprite*) bodyB->GetUserData();
                body = bodyB;
            }
            
            if (sprite.tag == obstacle) {
                toDestroy.push_back(body);
            }
        }
        
        if (!playerHit) {
            [self updateScoreBy:10];
        }
    }
    
    std::vector<b2Body *>::iterator pos2;
    for(pos2 = toDestroy.begin(); pos2 != toDestroy.end(); ++pos2) {
        b2Body *body = *pos2;
        if (body->GetUserData() != NULL) {
            CCSprite *sprite = (CCSprite *) body->GetUserData();
            if (sprite) {
                [sprite removeFromParentAndCleanup:YES];
            }
            
        }
        world->DestroyBody(body);
    }
}

// Spawn blocks regularly.
-(void) updateTime:(ccTime)dt
{
    runningTime += 1;
    for (int i=0; i < runningTime/10 + 1; i++) {
        [self addNewSpriteAtPosition:ccp(arc4random_uniform(size.width), size.height)];
    }
}


-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView: [touch view]];
    right = location.x > size.width/2;
    [self schedule:@selector(movePlayer:) interval:0.01f];
}

-(void)movePlayer:(ccTime)dt {
    CGPoint playerPos = playerSprite.position;
    if (right) {
        if (playerPos.x + 5 < size.width) {
            playerSprite.position = ccp(playerPos.x + 5, playerPos.y);
        }
    } else {
        if (playerPos.x - 5 > 0) {
            playerSprite.position = ccp(playerPos.x - 5, playerPos.y);
        }
    }
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self unschedule:@selector(movePlayer:)];
}

-(void)updateScoreBy:(int)delta {
    score += delta;
    [scoreLabel setString:[NSString stringWithFormat:@"%i", score]];
}

@end
