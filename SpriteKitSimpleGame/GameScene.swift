//
//  GameScene.swift
//  SpriteKitSimpleGame
//
//  Created by João Marcos on 04/05/15.
//  Copyright (c) 2015 João Marcos. All rights reserved.
//

import SpriteKit
import AVFoundation

var backgroundMusicPlayer: AVAudioPlayer!
var monstersDestroyed = 0
var highScore = 0

func playBackgroundMusic(filename: String) {
    
    let url = NSBundle.mainBundle().URLForResource(
        filename, withExtension: nil)
    if (url == nil) {
        println("Could not find file: \(filename)")
        return
    }
    
    var error: NSError? = nil
    backgroundMusicPlayer =
        AVAudioPlayer(contentsOfURL: url, error: &error)
    if backgroundMusicPlayer == nil {
        println("Could not create audio player: \(error!)")
        return
    }
    
    backgroundMusicPlayer.numberOfLoops = -1
    backgroundMusicPlayer.prepareToPlay()
    backgroundMusicPlayer.play()
}

struct PhysicsCategory {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Monster   : UInt32 = 0b1       // 1
    static let Projectile: UInt32 = 0b10      // 2
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var labelScore = SKLabelNode()
    var labelHighScore = SKLabelNode()
    
    // Example of Sprite
    let player = SKSpriteNode(imageNamed: "Iron-Man")
    
    
    override func didMoveToView(view: SKView) {
        // Background Color
        backgroundColor = SKColor.grayColor()
        
        // Music Background
        playBackgroundMusic("background-music-aac.caf")
        
        // Position of Sprite
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        // To make the sprite appear
        addChild(player)
        
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([
                SKAction.runBlock(addMonster),
                SKAction.waitForDuration(1.0)
                ])
            ))
        
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        
        monstersDestroyed = 0
        highScore = NSUserDefaults.standardUserDefaults().integerForKey("HighScore")
        
        //if NSUserDefaults.integerForKey("HighScore") == 0 {
            //labelHighScore.text = "High Score = 0"
        //} else {
            labelHighScore.text = "High Score = \(highScore)"
        //}
        labelHighScore.fontSize = 15
        labelHighScore.fontColor = SKColor.blackColor()
        labelHighScore.position = CGPoint(x: 70, y: size.height - 20)
        addChild(labelHighScore)
        
        labelScore.text = "Score = \(monstersDestroyed)"
        labelScore.fontSize = 25
        labelScore.fontColor = SKColor.blackColor()
        labelScore.position = CGPoint(x: size.width/2, y: size.height - 40)
        addChild(labelScore)
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(#min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addMonster() {
        // Create Sprite
        let monster = SKSpriteNode(imageNamed: "ultron")
        
        // Determine where to spawn the monster along the Y axis
        let actualY = random(min: monster.size.height/2 , max: size.height - monster.size.height/2)
        
        // Position the monster slightly off-screen along the right edge, and along a random position along the Y axis as calculated above
        monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
        
        // Add the monster to the scene
        addChild(monster)
        
        // Determine speed of the monster
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        // Create the actions
        let actionMove = SKAction.moveTo(CGPoint(x: -monster.size.width/2, y: actualY), duration: NSTimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        
        let loseAction = SKAction.runBlock() {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            if monstersDestroyed >  highScore {
            NSUserDefaults.standardUserDefaults().setInteger(monstersDestroyed, forKey: "HighScore")
            }
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        monster.runAction(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
        
        // Collisions
        // Create a physics body
        monster.physicsBody = SKPhysicsBody(rectangleOfSize: monster.size)
        // Set the sprite to dynamic
        monster.physicsBody?.dynamic = true
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None
    }

    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        // Choose one of the touches to work with
        let touch = touches.first as! UITouch
        let touchLocation = touch.locationInNode(self)
        
        // Set up initial location of projectile
        let projectile = SKSpriteNode(imageNamed: "blue")
        projectile.position = CGPoint(x: player.position.x+27, y: player.position.y+32)
        
        // Determine offset of location to projectile
        let offset = touchLocation - projectile.position
        
        // Bail out if you are shooting down or backwards
        if (offset.x < 0) { return }
        
        // OK to add now - you've double checked position
        addChild(projectile)
        
        // Get the direction of where to shoot
        let direction = offset.normalized()
        
        // Make it shoot far enough to be guaranteed off screen
        let shootAmount = direction * 1000
        
        // Add the shoot amount to the current position
        let realDest = shootAmount + projectile.position
        
        // Create the actions
        let actionMove = SKAction.moveTo(realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody?.dynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        
        runAction(SKAction.playSoundFileNamed("laser.mp3", waitForCompletion: false))
    }
    
    func projectileDidCollideWithMonster(projectile:SKSpriteNode, monster:SKSpriteNode) {
        runAction(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        println("Hit")
        projectile.removeFromParent()
        monster.removeFromParent()
        
        monstersDestroyed++
        labelScore.text = "Score = \(monstersDestroyed)"
        
//        if (monstersDestroyed > 15) {
//            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
//            let gameOverScene = GameOverScene(size: self.size, won: true)
//            self.view?.presentScene(gameOverScene, transition: reveal)
//        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
    
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
                projectileDidCollideWithMonster(firstBody.node as! SKSpriteNode, monster: secondBody.node as! SKSpriteNode)
        }
        
    }
}