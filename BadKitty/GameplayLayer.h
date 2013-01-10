#import "cocos2d.h"
#import "Box2D.h"
#import "GameObject.h"
#import "GLES-Render.h"

#define PTM_RATIO 32.0
#define DAMPING 0.0f
#define FLOOR_HEIGHT 39.0f
#define SCREEN_WIDTH [CCDirector sharedDirector].winSize.width
#define SCREEN_HEIGHT [CCDirector sharedDirector].winSize.height
#define LEFT_RESPAWN 65.0f
#define RIGHT_RESPAWN SCREEN_WIDTH - LEFT_RESPAWN

@interface GameplayLayer : CCLayer {
    b2World* world;
	GLESDebugDraw *m_debugDraw;
    
    // The border
    b2Body *_groundBody;
    b2Fixture *_bottomFixture;
    
    int ornamentsLeftOnTree;
}

enum FixtureTypes
{
    kNonWall,
	kLeftWall,
	kRightWall,
    kGround
};

@property (nonatomic, strong)GameObject *theCat;
@property (nonatomic, strong)NSMutableArray *ornamentArray;
@property (nonatomic, strong)GameObject *ornament1;
@property (nonatomic, strong) NSMutableArray* gameObjects;
@property (nonatomic) BOOL isDragging;
@property (nonatomic, strong) CCNode* feedbackContainer;
@property (nonatomic, strong) NSMutableArray* feedback;
@property (nonatomic,assign) BOOL isTouching;
@property (nonatomic,assign) int ornamentsLeftOnTree;
@property (nonatomic) BOOL isReadyToJump;

+ (id) scene;
- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;

@end