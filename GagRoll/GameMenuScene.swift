//
//  GameMenuScene.swift
//  GagRoll
//
//  Created by Maneesh Madan on 17/01/18.
//  Copyright © 2018 Aditya. All rights reserved.
//

import UIKit
import SpriteKit

class GameMenuScene: SKScene {
    
    var startGame = SKLabelNode()
    var bestScore = SKLabelNode()
    var gameScore = SKLabelNode()
    var audioNode = SKSpriteNode()

    let gameSettings = Settings.sharedInstance
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        startGame = self.childNode(withName: "startGame") as! SKLabelNode
        bestScore = self.childNode(withName: "bestScore") as! SKLabelNode
        gameScore = self.childNode(withName: "gameScore") as! SKLabelNode

        
        gameSettings.highScore = UserDefaults().integer(forKey: "GameHighScore")
        
        bestScore.text = "Best Score: \(gameSettings.highScore)"
        gameScore.text = "Game Score: \(gameSettings.gameScore)"
        
        
        audioNode = self.childNode(withName: "audioNode") as! SKSpriteNode
//        audioNode = SKSpriteNode(imageNamed: "audio")
        gameSettings.audioSetting = true


    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            if atPoint(touchLocation).name == "startGame" {
                let menuScene = SKScene(fileNamed: "GameScene")!
                menuScene.scaleMode = .aspectFill
                view?.presentScene(menuScene, transition: SKTransition.doorsOpenHorizontal(withDuration: TimeInterval(1.5)))
            }
            
            if atPoint(touchLocation).name == "audioNode" {
                if gameSettings.audioSetting == true {
                    audioNode.texture = SKTexture(imageNamed: "noAudio")
                    gameSettings.audioSetting = false
                }else {
                    audioNode.texture = SKTexture(imageNamed: "audio")
                    gameSettings.audioSetting = true
                }
            }
        }
    }
}
