//
//  GameScene.swift
//  GagRoll
//
//  Created by Aditya Sharma on 16/01/18.
//  Copyright © 2018 Aditya. All rights reserved.
//

import SpriteKit
import GameplayKit
import AudioToolbox
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var mainCar = SKSpriteNode()
    var opponentCar = SKSpriteNode()
    var gameScene = SKScene()
    var carDrivingPlayer: AVAudioPlayer?
    var crashingPlayer:AVAudioPlayer?

    var canMove = false
    var carAtRight = true
    var toMoveLeft = false
    
    var centerPoint: CGFloat!
    let carMinimumX: CGFloat = -160
    let carMaximumX: CGFloat = 160
    var level = 1
    
    var countDown = 1
    var stopEverything = true
    var scoreText = SKLabelNode()
    var levelLabel = SKLabelNode()

    var score = 0
    var gameSpeed: CGFloat = 20
    
    var createRoadStripTimer : Timer?
    var startCountDownTimer: Timer?
    var trafficTimer: Timer?
    
    var gameSettings = Settings.sharedInstance
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        setUp()
        physicsWorld.contactDelegate = self
        createRoadStrip()
        showLevel()

        createRoadStripTimer = Timer.scheduledTimer(timeInterval: TimeInterval(0.2), target: self, selector: #selector(GameScene.createRoadStrip), userInfo: nil, repeats: true)
        startCountDownTimer =  Timer.scheduledTimer(timeInterval: TimeInterval(1), target: self, selector: #selector(GameScene.startCountDown), userInfo: nil, repeats: true)

        trafficTimer = Timer.scheduledTimer(timeInterval: TimeInterval(Helper().randomBetweenTwoNumbers(firstNumber: 0.8, secondNumber: 1.8)), target: self, selector: #selector(GameScene.traffic), userInfo: nil, repeats: true)
        Timer.scheduledTimer(timeInterval: TimeInterval(0.5), target: self, selector: #selector(GameScene.removeItems), userInfo: nil, repeats: true)
        let deadTime = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: deadTime) {
            Timer.scheduledTimer(timeInterval: TimeInterval(1), target: self, selector: #selector(GameScene.increaseScore), userInfo: nil, repeats: true)
        }

    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody = SKPhysicsBody()
        
        if contact.bodyA.node?.name == "mainCar" {
            firstBody = contact.bodyA
        }else {
            firstBody = contact.bodyB
        }
        
        firstBody.node?.removeFromParent()
        afterCollision()
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches{
//            let touchLocation = touch.location(in: self)
//            if touchLocation.x > centerPoint {
            if carAtRight {
                carAtRight = false
                toMoveLeft = true
            }else {
                carAtRight = true
                toMoveLeft = false
            }
            canMove = true
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if canMove {
            move(leftSide: toMoveLeft)
        }
        if !stopEverything {
            showRoadStrip(speedControl: gameSpeed)
        }
    }
    
    func setUp() {
        mainCar = self.childNode(withName: "mainCar") as! SKSpriteNode
        centerPoint = self.frame.size.width / self.frame.size.height
        
        mainCar.physicsBody?.categoryBitMask = ColliderType.CAR_COLLIDER
        mainCar.physicsBody?.contactTestBitMask = ColliderType.ITEM_COLLIDER
        mainCar.physicsBody?.collisionBitMask = 0
        
        let scoreBackground = SKShapeNode(rect: CGRect(x: self.size.width/4, y: self.size.height/2 - 200, width: self.size.width/4 - 20, height: 70), cornerRadius: 20)
        scoreBackground.zPosition = 4
        scoreBackground.fillColor = SKColor.black.withAlphaComponent(0.4)
        scoreBackground.strokeColor = SKColor.black.withAlphaComponent(0.4)
        addChild(scoreBackground)
        
        scoreText.name = "score"
        scoreText.fontName = "AvenirNext-Bold"
        scoreText.text = "0"
        scoreText.fontColor = SKColor.white
        scoreText.position = CGPoint(x: self.size.width/4 + (self.size.width/4)/2, y: self.size.height/2 - 185)
        scoreText.zPosition = 4
        scoreText.fontSize = 50
        addChild(scoreText)
    }
    
    @objc func createRoadStrip() {
        let roadStrip = SKShapeNode(rectOf: CGSize(width: 10, height: 40))
        roadStrip.strokeColor = SKColor.white
        roadStrip.fillColor = SKColor.white
        roadStrip.alpha = 0.4
        roadStrip.name = "roadStrip"
        roadStrip.zPosition = 10
        roadStrip.position.x = 0
        roadStrip.position.y = 700
        addChild(roadStrip)
    }
    
    func showRoadStrip(speedControl: CGFloat) {
        enumerateChildNodes(withName: "roadStrip") { (roadStrip, stop) in
            let strip = roadStrip
            strip.position.y -= speedControl
        }
        enumerateChildNodes(withName: "orangeCar") { (leftCar, stop) in
            let car = leftCar as! SKSpriteNode
            car.position.y -= speedControl
        }
        enumerateChildNodes(withName: "greenCar") { (rightCar, stop) in
            let car = rightCar as! SKSpriteNode
            car.position.y -= speedControl
        }
    }
    
    @objc func removeItems() {
        for child in children {
            if child.position.y < -self.size.height - 100{
                child.removeFromParent()
            }
        }
    }
    
    func move(leftSide: Bool){
        if leftSide{
            mainCar.position.x -= 100
            if mainCar.position.x < carMinimumX {
                mainCar.position.x = carMinimumX
            }
        }else {
            mainCar.position.x += 100
            if mainCar.position.x > carMaximumX {
                mainCar.position.x = carMaximumX
            }
        }
    }
    
    @objc func traffic() {
        if !stopEverything {
            if carDrivingPlayer == nil {
                if gameSettings.audioSetting {
                    playCarDrivingSound()
                }
            }

            let trafficItem: SKSpriteNode!
            let randomNumber = Helper().randomBetweenTwoNumbers(firstNumber: 1, secondNumber: 8)
            switch Int(randomNumber) {
            case 1...4:
                trafficItem = SKSpriteNode(imageNamed: "orangeCar")
                trafficItem.name = "orangeCar"
                break
            case 5...8:
                trafficItem = SKSpriteNode(imageNamed: "greenCar")
                trafficItem.name = "greenCar"
                break
            default:
                trafficItem = SKSpriteNode(imageNamed: "greenCar")
                trafficItem.name = "greenCar"
                break
            }
            trafficItem.anchorPoint = CGPoint(x:0.5, y: 0.5)
            trafficItem.zPosition = 10
            
            let randomNum = Helper().randomBetweenTwoNumbers(firstNumber: 1, secondNumber: 10)
            switch Int(randomNum) {
            case 1...4:
                trafficItem.position.x = -160
                break
            case 5...10:
                trafficItem.position.x = 160
                break
            default:
                trafficItem.position.x = 160
                break
            }
            trafficItem.position.y = 700
            
            trafficItem.physicsBody = SKPhysicsBody(circleOfRadius: trafficItem.size.height/2)
            trafficItem.physicsBody?.categoryBitMask = ColliderType.ITEM_COLLIDER
            trafficItem.physicsBody?.collisionBitMask = 0
            trafficItem.physicsBody?.affectedByGravity = false
            
            addChild(trafficItem)
        }
    }
    
    fileprivate func saveGameScore() {
        gameSettings.gameScore = score
        
        if gameSettings.highScore < score {
            gameSettings.highScore = score
            UserDefaults().set(gameSettings.highScore, forKey: "GameHighScore")
        }
    }
    
    func afterCollision() {
        saveGameScore()
        vibrateEffect()
        
        if gameSettings.audioSetting {
            playCarCrashingSound()
        }
        stopSound()
        trafficTimer?.invalidate()
        createRoadStripTimer?.invalidate()
        startCountDownTimer?.invalidate()
        
        let menuScene = SKScene(fileNamed: "GameMenuScene")!
        menuScene.scaleMode = .aspectFill
        view?.presentScene(menuScene, transition: SKTransition.doorsCloseHorizontal(withDuration: TimeInterval(1.5)))
    }
    
    func vibrateEffect() {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    @objc func startCountDown() {
        if countDown>0 {
            if countDown < 4 {
//                let countDownLabel = SKLabelNode()
//                countDownLabel.fontName = "AvenirNext-Bold"
//                countDownLabel.fontSize = 300
//                countDownLabel.text = String(countDown)
//                countDownLabel.position = CGPoint(x: 0, y: 0)
//                countDownLabel.name = ""
//                countDownLabel.horizontalAlignmentMode = .center
//                addChild(countDownLabel)
                
//                let deadTime = DispatchTime.now() + 0.5
//                DispatchQueue.main.asyncAfter(deadline: deadTime, execute: {
//                    countDownLabel.removeFromParent()
//                })
            }
            countDown += 1
            if countDown == 4 {
                self.stopEverything = false
            }
        }
        print(countDown)
        switch countDown {
        case 30, 60, 90, 120, 150, 180, 210, 240, 270, 300:
            gameSpeed += 5
            stopEverything = true
            showLevel()
        default:
            return
        }
        print("Speed:", gameSpeed)
      
    }
    
    @objc func increaseScore() {
        if !stopEverything {
            score += 1
            scoreText.text = String(score)
        }
    }

    
    func playCarDrivingSound() {
        guard let url = Bundle.main.url(forResource: "drivingSound", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            carDrivingPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let player = carDrivingPlayer else { return }
            
            player.play()
            player.numberOfLoops = -1

        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func playCarCrashingSound() {
        guard let url = Bundle.main.url(forResource: "brakeSound", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            crashingPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let player = crashingPlayer else { return }
            
            player.play()
            player.numberOfLoops = 0
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func stopSound() {
        carDrivingPlayer?.stop()
        carDrivingPlayer = nil
    }
    
    func showLevel() {
        levelLabel.text = "Level \(level)"
        level += 1
        levelLabel.fontName = "AvenirNext-Bold"
        levelLabel.fontSize = 150
        levelLabel.position = CGPoint(x: 0, y: 0)
        levelLabel.zPosition = 100
        levelLabel.name = "levelLabel"
        levelLabel.horizontalAlignmentMode = .center
        addChild(levelLabel)
        
        removeItems()
        self.isUserInteractionEnabled = false
        let deadTime = DispatchTime.now() + 3
        DispatchQueue.main.asyncAfter(deadline: deadTime, execute: {
            self.levelLabel.removeFromParent()
            self.stopEverything = false
            self.isUserInteractionEnabled = true
        })
    }
}




















