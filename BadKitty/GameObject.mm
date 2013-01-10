//
//  GameObject.m
//  GhettoBirdsin30
//
//  Created by Chris Hill on 11/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GameObject.h"

@implementation GameObject
@synthesize sprite, type, body;
@synthesize walkTheKitty;

-(id)initWithFrameName:(NSString*)frameName type:(ObjectTypes)objType position:(CGPoint)objPos
{
	self = [super init];
	if(self){
		self.sprite = [CCSprite spriteWithSpriteFrameName:frameName];
		self.sprite.position = objPos;
		self.type = objType;
	}
	return self;
}

-(id)initWithFile:(NSString*)fileName type:(ObjectTypes)objType position:(CGPoint)objPos
{
    self = [super init];
	if(self){
		self.sprite = [CCSprite spriteWithFile:fileName];
		self.sprite.position = objPos;
		self.type = objType;
	}
	return self;
}

-(void)updateSpriteWithFile:(NSString*)fileName
{
    CCTexture2D* tex = [[CCTextureCache sharedTextureCache] addImage:fileName];
    [self.sprite setTexture: tex];
    //self.sprite = [CCSprite spriteWithFile:fileName];
}

-(void)walkTo
{
    id actionMove = [CCMoveTo actionWithDuration:0.5 position:ccp(65.0f, 80.0f)];
    id actionMoveDone = [CCCallFuncN actionWithTarget:self
                                             selector:@selector(spriteMoveFinished:)];
    [self.sprite runAction: [CCSequence actions:actionMove, actionMoveDone, nil]];
}

-(void)spriteMoveFinished:(id)sender {
    NSLog(@"sprite move finished");
}


@end
