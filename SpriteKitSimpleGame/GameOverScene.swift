//
//  GameOverScene.swift
//  SpriteKitSimpleGame
//
//  Created by João Marcos on 04/05/15.
//  Copyright (c) 2015 João Marcos. All rights reserved.
//

import Foundation
import SpriteKit

class GameOverScene: SKScene {
    
    init(size: CGSize, won:Bool) {
        
        super.init(size: size)
        
        // 1
        
        if won == true {
        backgroundColor = SKColor.greenColor()
        } else {
        backgroundColor = SKColor.redColor()
        }
    
        // 2
        var message = won ? "You Won! 😁" : "You Lose! 😕"
        
        // 3
        let labell = SKLabelNode(fontNamed: "Chalkduster")
        labell.text = message
        labell.fontSize = 60
        labell.fontColor = SKColor.blackColor()
        labell.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(labell)
        
        let button = SKSpriteNode(color: SKColor.yellowColor(), size: CGSize(width: 100, height: 40))
        button.position = CGPoint(x: size.width/2 , y: size.height/2 - 100)
        addChild(button)
        
        // 4
        runAction(SKAction.sequence([
            SKAction.waitForDuration(3.0),
            SKAction.runBlock() {
                // 5
                let reveal = SKTransition.flipHorizontalWithDuration(0.5)
                let scene = GameScene(size: size)
                self.view?.presentScene(scene, transition:reveal)
            }
            ]))
    }
    // 6
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
//        for touch: AnyObject in touches {
//            let location = touch.locationInNode(self)
//            if button
//        }
//    }
}
