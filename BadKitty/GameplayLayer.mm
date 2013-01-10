#import "GameplayLayer.h"

class GhettoContactListener : public b2ContactListener
{
public:
	void BeginContact(b2Contact* contact)
	{
       // NSLog(@"Begin Contact");
        b2Fixture *fA = (b2Fixture*)contact->GetFixtureA();
        b2Fixture *fB = (b2Fixture*)contact->GetFixtureB();
        b2Body *bA = (b2Body*)contact->GetFixtureA()->GetBody();
        b2Body  *bB = (b2Body*)contact->GetFixtureB()->GetBody();
        GameObject *oA = (__bridge GameObject*)bA->GetUserData();
        GameObject *oB = (__bridge GameObject*)bB->GetUserData();
        
        // Detect wall/ground hits and fire off appropriate animation
        if((int)fA->GetUserData() != kNonWall && (int)fB->GetUserData() == kNonWall)
        {
            if((oB.type == kCat))
            {
                int wallType = (int)fA->GetUserData();
                if(wallType == kLeftWall)
                    [oB updateSpriteWithFile:@"cat4.png"];
                else if(wallType == kRightWall)
                    [oB updateSpriteWithFile:@"cat4.png"];
                else
                {
                    oB.walkTheKitty = YES;
                }
            }
        }
        
        // Did the cat hit a bulb?
        if(oA)
        {
            if(oB)
            {
                float fBx = bB->GetLinearVelocity().x;
                //float fBy = bB->GetLinearVelocity().y;
                bA->SetLinearVelocity(b2Vec2(fBx/3.0f, 0.0f)); // this is just a number that works nicely

                
                if((oA.type == kCat && oB.type == kOrnament) || (oA.type == kOrnament && oB.type == kCat))
                    printf("cat hit a bulb: %d / %d\n", oA.type, oB.type);
            }
        }
         
	}
	
	void EndContact(b2Contact* contact)
	{
    
	}
    
	void PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
	{
    
    }
	void PostSolve(b2Contact* contact)
	{
	}
};

@implementation GameplayLayer

@synthesize theCat, gameObjects, isDragging, feedback, feedbackContainer;
@synthesize ornamentArray;
@synthesize ornament1;
@synthesize isTouching;
@synthesize ornamentsLeftOnTree;
@synthesize isReadyToJump;

+ (id)scene {
    
    CCScene *scene = [CCScene node];
    CCSprite* background = [CCSprite spriteWithFile:@"BG.png"];
    CGSize screenSize = [CCDirector sharedDirector].winSize;
	background.position = CGPointMake(screenSize.width/2, screenSize.height/2);
	[scene addChild:background];
    
    GameplayLayer *layer = [GameplayLayer node];
    [scene addChild:layer];
    return scene;
    
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
		// enable touches
		self.isTouchEnabled = YES;
		
		// enable accelerometer
		self.isAccelerometerEnabled = YES;
        
        // ornament array
        self.ornamentArray = [[NSMutableArray alloc] init];
        
        // cat is ready to jump
        self.isReadyToJump = YES;
		
		CGSize screenSize = [CCDirector sharedDirector].winSize;
		CCLOG(@"Screen width %0.2f screen height %0.2f",screenSize.width,screenSize.height);
		
		// Define the gravity vector.
		b2Vec2 gravity;
		gravity.Set(0.0f, -100.0f);
		
		// Do we want to let bodies sleep?
		// This will speed up the physics simulation
		bool doSleep = true;
		
		// Construct a world object, which will hold and simulate the rigid bodies.
		world = new b2World(gravity);
        world->SetAllowSleeping(doSleep);
        
        [self createGround:screenSize];
        
        // NOTE: figure out the contact listener
        world->SetContactListener(new GhettoContactListener());
		
		world->SetContinuousPhysics(true);
		
		// Debug Draw functions        
		m_debugDraw = new GLESDebugDraw( PTM_RATIO );        
        //world->SetDebugDraw(m_debugDraw);
        uint32 flags = 0;
        flags += b2Draw::e_shapeBit;
        flags += b2Draw::e_jointBit;
        flags += b2Draw::e_centerOfMassBit;
        flags += b2Draw::e_aabbBit;
        flags += b2Draw::e_pairBit;
        m_debugDraw->SetFlags(flags);

		//self.gameObjects = [NSMutableArray arrayWithCapacity:5];
		//[self addSpriteSheets];
		//[self addBackground];
		[self addPullbackFeedback];
		[self addHero];
		//[self addEnemies];
		//[self addDestructables];
		//[self addBoundingBoxes];
        [self addAllOrnaments];
        
		[self schedule: @selector(tick:)];
        
	}
	return self;
}

-(void) addAllOrnaments
{
    self.ornamentsLeftOnTree = 4;
    [self addOrnamentAtPosition:CGPointMake(75,50) withFile:@"smallOrnament-hd.png"];
    [self addOrnamentAtPosition:CGPointMake(-75,50) withFile:@"medOrnament-hd.png"];
    [self addOrnamentAtPosition:CGPointMake(50,-100) withFile:@"bigOrnament-hd.png"];
    [self addOrnamentAtPosition:CGPointMake(-50,-100) withFile:@"bigOrnament-hd.png"];
    
}
// Destroy all of the ornaments
-(void) destroyAllOrnaments
{
    for (b2Body* b = world->GetBodyList(); b; b = b->GetNext())
    {
        GameObject *ornamentToDestroy = (__bridge GameObject*)b->GetUserData();
        if(ornamentToDestroy.type == kOrnament)
        {
            world->DestroyBody(b);
            [ornamentToDestroy.sprite removeFromParentAndCleanup:YES];
            [self.ornamentArray removeObject:ornamentToDestroy];
        }
    }
    [self addAllOrnaments];
    
}

-(void) draw
{
    [super draw];
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
    kmGLPushMatrix();
    world->DrawDebugData();
    kmGLPopMatrix();
}

-(void) createGround:(CGSize)size {
    
	float width = size.width;
	float height = size.height;
    
	float32 margin = 1.0f;
	b2Vec2 lowerLeft = b2Vec2(margin/PTM_RATIO, (margin + FLOOR_HEIGHT)/PTM_RATIO);
	b2Vec2 lowerRight = b2Vec2((width+margin)/PTM_RATIO,(margin + FLOOR_HEIGHT)/PTM_RATIO);
	b2Vec2 upperRight = b2Vec2((width+margin)/PTM_RATIO, (height-margin)/PTM_RATIO);
	b2Vec2 upperLeft = b2Vec2(margin/PTM_RATIO, (height-margin)/PTM_RATIO);
    
    // Body Def
	b2BodyDef groundBodyDef;
	groundBodyDef.type = b2_staticBody;
	groundBodyDef.position.Set(0, 0);
	_groundBody = world->CreateBody(&groundBodyDef);
    
	// Define the ground box shape.
	b2EdgeShape groundBox;
    
    // Define the dynamic body fixture.
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &groundBox;
    fixtureDef.userData = (void*)kGround;

    
	// bottom
	groundBox.Set(lowerLeft, lowerRight);
    _groundBody->CreateFixture(&fixtureDef);
    
	// top
	groundBox.Set(upperRight, upperLeft);
    fixtureDef.userData = (void*)kGround;
	_groundBody->CreateFixture(&fixtureDef);
    
	// left
	groundBox.Set(upperLeft, lowerLeft);
    fixtureDef.userData = (void*)kLeftWall;
	_groundBody->CreateFixture(&fixtureDef);
    
	// right
	groundBox.Set(lowerRight, upperRight);
    fixtureDef.userData = (void*)kRightWall;
	_groundBody->CreateFixture(&fixtureDef);
}


-(void) tick: (ccTime) dt
{
    CGSize screenSize = [CCDirector sharedDirector].winSize;
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 8;
	int32 positionIterations = 1;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	world->Step(dt, velocityIterations, positionIterations);
    
	BOOL worldAsleep = true;
    
    //Iterate over joints inthe physics world
    for (b2Joint* j = world->GetJointList(); j; j = j->GetNext())
    {
        float radians = atan2f( j->GetAnchorA().y - j->GetAnchorB().y , j->GetAnchorA().x - j->GetAnchorB().x);
        float degrees = CC_RADIANS_TO_DEGREES(radians);
        //NSLog(@"%f", degrees);
        //NSLog(@"%f:%f %f:%f", j->GetAnchorA().x *PTM_RATIO, j->GetAnchorA().y *PTM_RATIO , j->GetAnchorB().x *PTM_RATIO, j->GetAnchorB().y *PTM_RATIO);
        if(degrees <= 45.0 || degrees >= 135.0f)  // make these constants
        {
            self.ornamentsLeftOnTree--;
            NSLog(@"Knocked Off! %f", degrees);
            world->DestroyBody(j->GetBodyA());
            j->GetBodyB()->GetFixtureList()->SetSensor(false); // <---super fucking janky...use categories!!!
            b2Filter newOrnamentFilter;
            newOrnamentFilter.maskBits = 0xfffb;
            j->GetBodyB()->GetFixtureList()->SetFilterData(newOrnamentFilter);
            if(!ornamentsLeftOnTree)
                [self destroyAllOrnaments];
        }
    }
	//Iterate over the bodies in the physics world
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext())
	{
        if(worldAsleep && b->IsAwake()){
			b2Vec2 v = b->GetLinearVelocity();
			float32 a = b->GetAngularVelocity();
			if(v.x < b2_linearSleepTolerance && v.y < b2_linearSleepTolerance && a < b2_angularSleepTolerance){
				if(b->GetUserData() != nil){
					worldAsleep = false;
				}
			}else{
				worldAsleep = false;
			}
		}
        
		if (b->GetUserData() != NULL) {
			//Synchronize the AtlasSprites position and rotation with the corresponding body
			GameObject* gameObject = (__bridge GameObject*)b->GetUserData();
			CCSprite* myActor = gameObject.sprite;
			myActor.position = CGPointMake( b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO);
			myActor.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
            
            if(gameObject.type == kCat && gameObject.walkTheKitty == YES)
            {
                self.theCat.walkTheKitty = NO;
                //[self walkBackToJumpingPosition];
                world->DestroyBody(self.theCat.body);
                
                float catXPos = self.theCat.sprite.position.x;
                CGPoint newPosition = fabsf((screenSize.width - 65) - catXPos ) <= fabsf(catXPos - 65) ? CGPointMake(screenSize.width - 65.0, 80) : CGPointMake(65.0, 80);
                bool flipX = fabsf((screenSize.width - 65) - catXPos ) <= fabsf(catXPos - 65) ? true : false;
                
                self.theCat.sprite.flipX = flipX;
                id delay = [CCDelayTime actionWithDuration: 0.1f];
                id actionMove = [CCMoveTo actionWithDuration:0.5 position:newPosition];
                id actionMoveDone = [CCCallFuncN actionWithTarget:self
                                                         selector:@selector(walkBackToJumpingPosition)];
                [self.theCat.sprite runAction: [CCSequence actions:delay, actionMove, actionMoveDone, nil]];
                
                ///// Animation test - this I need to be moved inside the cat class i think
                CCAnimation* animation = [CCAnimation animation];
                [animation addFrameWithFilename: [NSString stringWithFormat:@"cat5.png"]];
                [animation addFrameWithFilename: [NSString stringWithFormat:@"cat6.png"]];
                
                id action = [CCAnimate actionWithDuration:0.25 animation:animation restoreOriginalFrame:NO];
                id action_back = [action reverse];
                
                [self.theCat.sprite runAction:[CCRepeatForever actionWithAction:action]];
                //[self.theCat.sprite runAction: [CCSequence actions: action, action_back, nil]];

            }
		}
        
	}
	
/*
	//Iterate over gameObjects and destroy anything that has been damaged.
	for(int i=0;i<self.gameObjects.count;i++){
		GameObject* gameObject = [self.gameObjects objectAtIndex:i];
		if(gameObject.strength <= 0){
			[self removeGameObject:gameObject];
			i--;
		}
	}
*/
    
	if(worldAsleep && self.theCat == nil){
        //[self addHero];
        //[self walkBackToJumpingPosition];
	}
	/*
	if(self.theCat.body && !self.theCat.body->IsAwake()){
		 [self walkBackToJumpingPosition];
        //[self removeGameObject:self.theCat];
	}
     */
        
}
/*
- (void) addSpriteSheets
{
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/sprites1.plist"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/poof.plist"];
}
*/

-(void)removeGameObject:(GameObject*)gameObject
{
	[gameObject.sprite removeFromParentAndCleanup:YES];
	//[self.gameObjects removeObject:gameObject];
	
	world->DestroyBody(gameObject.body);
	
	if(self.theCat == gameObject){
		self.theCat = nil;
	}
    
}


- (void) addBackground
{
	//NOTE: Move back to spirtesheets eventually
    //CCSprite* background = [CCSprite spriteWithSpriteFrameName:@"BG.png"];
    CCSprite* background = [CCSprite spriteWithFile:@"BG.png"];
    CGSize screenSize = [CCDirector sharedDirector].winSize;
	background.position = CGPointMake(screenSize.width/2, screenSize.height/2);
	[self addChild:background];
    
}

- (void) walkBackToJumpingPosition
{
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    
    CGPoint newPosition = self.theCat.sprite.position.x >= screenSize.width/2 ? CGPointMake(screenSize.width - 65.0, 80) : CGPointMake(65.0, 80);
    bool flipX = self.theCat.sprite.position.x >= screenSize.width/2 ? true : false;
////////
    
    //world->DestroyBody(self.theCat.body);
    //[self.theCat walkTo];
	[self.theCat.sprite removeFromParentAndCleanup:YES];
    //self.theCat = nil;
	
/////////
    //[self removeGameObject:self.theCat];
    self.theCat = [[GameObject alloc]
                   initWithFile:@"cat.png"
                   type:kCat
                   position:newPosition];
    
    // Turn the cat around if need be
    self.theCat.sprite.flipX = flipX;
    
	[self addChild:self.theCat.sprite];
    
    self.isReadyToJump = YES;
    
}


- (void) addHero
{
    //NOTE: Move back to spirtesheets eventually
    
//	self.theCat = [[[GameObject alloc]
//                  initWithFrameName:@"ghetto_bird.png"
//                  strength:100000
//                  type:ghettoHero
//                  position:CGPointMake(235,195)]
//                 autorelease];
//  
    self.theCat = [[GameObject alloc]
                    initWithFile:@"cat.png"
                    type:kCat
                    position:CGPointMake(65,80)];

	[self addChild:self.theCat.sprite];
}

- (void) addPhysicsToUnit:(GameObject*) gameObject
{   
	// Define the dynamic body.
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
    bodyDef.fixedRotation = true;
	CGPoint p = gameObject.sprite.position;
	CGSize s = gameObject.sprite.contentSize;
    
	bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
	bodyDef.userData = (__bridge void*)gameObject;
	bodyDef.allowSleep = true;
    bodyDef.bullet = true;  // NOTE: Not sure about this
	bodyDef.linearDamping = DAMPING;
	bodyDef.angularDamping = DAMPING;
	b2Body *body = world->CreateBody(&bodyDef);
	gameObject.body = body;
	
	// Define another box shape for our dynamic body.
	b2CircleShape dynamicCircle;
	dynamicCircle.m_radius = (s.height/2) / PTM_RATIO;//These are mid points for our 1m box

	// Define the dynamic body fixture.
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &dynamicCircle;
	fixtureDef.density = 0.7f;
	fixtureDef.friction = 99.1f;
   // fixtureDef.filter.maskBits = 6;
    fixtureDef.filter.categoryBits = 0x4;
	body->CreateFixture(&fixtureDef);
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.isTouching = TRUE;
	for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];
		
		location = [[CCDirector sharedDirector] convertToGL: location];
		if([self isTouching:self.theCat atPoint:location] && self.isReadyToJump){
			NSLog(@"[CH] Touched theCat...");
            [self.theCat updateSpriteWithFile:@"cat2.png"];
			self.isDragging = true;
			[self updatePullbackFeedback:location];
		}
	}
}

-(BOOL)isTouching:(GameObject*)gameObject atPoint:(CGPoint)point
{
	CGPoint gPos = gameObject.sprite.position;
	CGSize gSize = gameObject.sprite.contentSize;
	
	CGRect hitArea = CGRectMake(gPos.x - gSize.width/2, gPos.y - gSize.height/2, gSize.width, gSize.height);
	if(CGRectContainsPoint(hitArea, point)){
		return YES;
	}
	return NO;
}

-(void)updatePullbackFeedback:(CGPoint)point
{
    if([self isTouching:self.theCat atPoint:point]){
		self.feedbackContainer.visible = false;
	}else{
		self.feedbackContainer.visible = true;
		// [CH] Draw the dots within the container in a line between the theCat and the touch point
		CGFloat magnitude = 0.0;
		CGPoint theCatPos = self.theCat.sprite.position;
		// [CH] Get the (negative) slope of the line.
		CGPoint slope = CGPointMake(point.x - theCatPos.x, point.y - theCatPos.y);
		CGFloat increment = 1.0 / self.feedback.count;
		for(CCSprite* sprite in self.feedback){
			CGPoint p = CGPointMake((magnitude * slope.x) + theCatPos.x, (magnitude * slope.y)  + theCatPos.y);
			sprite.position = p;
			magnitude -= increment;
		}
	}
}


- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	//Add a new body/atlas sprite at the touched location
	for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];
		location = [[CCDirector sharedDirector] convertToGL: location];
		if(self.isDragging){
			[self updatePullbackFeedback:location];
		}
	}
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
     self.isTouching = FALSE;
	//Add a new body/atlas sprite at the touched location
	for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];
		location = [[CCDirector sharedDirector] convertToGL: location];
		if([self isTouching:self.theCat atPoint:location]){
			NSLog(@"[CH] canceling drag");
		}else{
			if(self.isDragging){
				NSLog(@"[CH] sending this bad boy flying");
                [self.theCat updateSpriteWithFile:@"cat3.png"];
				[self applyForceTotheCat:location];
                self.isReadyToJump = NO;
			}
		}
		self.feedbackContainer.visible = false;
		self.isDragging = false;
	}
}

- (void) addPullbackFeedback
{
	self.feedback = [NSMutableArray arrayWithCapacity:3];
	self.feedbackContainer = [CCNode node];
	self.feedbackContainer.visible = false;
	[self addChild:self.feedbackContainer z:10];
	for(int i=0;i<3; i++){
		CCSprite* dot = [CCSprite spriteWithFile:@"dot.png"];
		[self.feedbackContainer addChild:dot];
		[self.feedback addObject:dot];
	}
}


- (void) applyForceTotheCat:(CGPoint)touchPos
{
	[self addPhysicsToUnit:self.theCat];
	[self.gameObjects addObject:self.theCat];
    
	CGFloat forceModifier = 70.0f;
	CGPoint theCatPos = self.theCat.sprite.position;
	b2Vec2 force = b2Vec2((theCatPos.x - touchPos.x) * forceModifier, (theCatPos.y - touchPos.y)  * forceModifier);
	self.theCat.body->ApplyForce(force, self.theCat.body->GetPosition());
    
}

- (void) addOrnamentAtPosition:(CGPoint)ornamentOffset withFile:(NSString*)fileName
{
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    
    // Add anchor body
    b2BodyDef anchorBodyDef;
    anchorBodyDef.position.Set((screenSize.width + ornamentOffset.x) /PTM_RATIO*0.5f,(screenSize.width + ornamentOffset.y+200)/PTM_RATIO*0.5f); //center body on screen
    b2Body *anchorBody = world->CreateBody(&anchorBodyDef);
    
    //Set up ornament sprite
    //CCSpriteBatchNode *batch = (CCSpriteBatchNode*) [self getChildByTag:kTagBatchNode];
	//CCSprite *sprite = [CCSprite spriteWithBatchNode:batch rect:CGRectMake(32 * idx,32 * idy,32,32)];
    
    GameObject *ornament = [[GameObject alloc]
                 initWithFile:fileName
                 type:kOrnament
                 position:CGPointMake((screenSize.width + ornamentOffset.x)/2, (screenSize.height + ornamentOffset.y)/2)];
    
    
    [self.ornamentArray addObject:ornament];
    [self addChild:[[self.ornamentArray lastObject] sprite]];
    CCSprite *szSprite = [[self.ornamentArray lastObject] sprite];
	 	
	// Define the dynamic body.
	//Set up a 1m squared box in the physics world
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
    bodyDef.fixedRotation = false;
	bodyDef.position.Set((screenSize.width + ornamentOffset.x)/PTM_RATIO/2, (screenSize.height + ornamentOffset.y)/PTM_RATIO/2);
	bodyDef.userData = (__bridge void*)[self.ornamentArray lastObject];
	b2Body *body = world->CreateBody(&bodyDef);
	
	// Define another box shape for our dynamic body.
	//b2PolygonShape dynamicBox;
	//dynamicBox.SetAsBox(20.0f *.5f/PTM_RATIO,20.0f * .5f/PTM_RATIO);//These are mid points for our 1m box
    
    // Define another box shape for our dynamic body.
	b2CircleShape dynamicCircle;
	dynamicCircle.m_radius = 10 / PTM_RATIO;//These are mid points for our 1m box
	
	// Define the dynamic body fixture.
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &dynamicCircle;
	fixtureDef.density = 2500.0f;
	fixtureDef.friction = 0.3f;
    fixtureDef.restitution = 0.3f;
    //fixtureDef.filter.maskBits = 0xf;
    fixtureDef.filter.categoryBits = 2;
    fixtureDef.isSensor = true;
	body->CreateFixture(&fixtureDef);
	
	// +++ Create box2d joint
	b2RopeJointDef jd;
    jd.bodyB=body;
	jd.bodyA=anchorBody; //define bodies
	jd.localAnchorA = b2Vec2(0,0); //define anchors
	jd.localAnchorB = b2Vec2(0,10.0/PTM_RATIO);
	//jd.maxLength= (body->GetPosition() - anchorBody->GetPosition()).Length(); //define max length of joint = current distance between bodies
    jd.maxLength= 24.0/PTM_RATIO; //define max length of joint = current distance between bodies
	
    world->CreateJoint(&jd); //create joint

    
}

@end