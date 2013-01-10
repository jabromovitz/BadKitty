//
//  GameObject.h
//  BadKitty
//

#import <Foundation/Foundation.h>
#import "Box2D.h"
#import "cocos2d.h"

@interface GameObject : NSObject
{
    CCSprite* sprite;
    NSInteger type;
    b2Body* body;
    BOOL walkTheKitty;
}

enum ObjectTypes
{
	kCat,
	kOrnament,
};	


-(id)initWithFrameName:(NSString*)frameName type:(ObjectTypes)objType position:(CGPoint)objPos;
-(id)initWithFile:(NSString*)fileName type:(ObjectTypes)objType position:(CGPoint)objPos;
-(void)updateSpriteWithFile:(NSString*)fileName;
-(void)walkTo;
-(void)spriteMoveFinished:(id)sender;

@property (nonatomic) CCSprite* sprite;
@property (nonatomic) NSInteger type;
@property (nonatomic) b2Body* body;
@property (nonatomic, assign) BOOL walkTheKitty;

@end
