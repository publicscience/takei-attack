//
//  MenuLayer.m
//  brendan game
//
//  Created by Francis Tseng on 12/1/13.
//  Copyright 2013 Francis Tseng. All rights reserved.
//

#import "MenuLayer.h"
#import "GameLayer.h"

@interface MenuLayer()
-(void) createMenu;
@end

@implementation MenuLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	MenuLayer *layer = [MenuLayer node];
	
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
		CGSize s = [CCDirector sharedDirector].winSize;
		
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"sup" fontName:@"Helvetica Neue" fontSize:32];
		[label setColor:ccc3(255,255,255)];
		label.position = ccp(s.width/2, s.height/2);

        [self addChild:label z:0];
        
        [self createMenu];
	}
	return self;
}

-(void) createMenu
{
	// Default font size will be 22 points.
	[CCMenuItemFont setFontSize:22];
    [CCMenuItemFont setFontName:@"Helvetica Neue"];
	
	// New Game Button
	CCMenuItemLabel *newGame = [CCMenuItemFont itemWithString:@"New Game" block:^(id sender){
		[[CCDirector sharedDirector] replaceScene: [GameLayer scene]];
	}];
    
	CCMenu *menu = [CCMenu menuWithItems: newGame, nil];
	
	[menu alignItemsVertically];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	[menu setPosition:ccp( size.width/2, size.height/2 - 50)];
	
	
	[self addChild: menu z:-1];
}

@end
