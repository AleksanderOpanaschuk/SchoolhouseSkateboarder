//
//  GameScene.swift
//  SchoolhouseSkateboarder
//
//  Created by Sasha Opanashchuk on 25.09.2021.
//

import SpriteKit

// Эта структура содержит различные физичиские категории и мы можем определить, какие типы объектов сталкиваються или контактируют друг с другом
struct PhysicsCaategory {
    static let skater: UInt32 = 0x1 << 0
    static let brick: UInt32 = 0x1 << 1
    static let gem: UInt32 = 0x1 << 2
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    // Enum для положения секции по y
    // Секции на земле низкие, а секции на верхней платформе высокие
    enum BrickLevel: CGFloat {
        case low = 0.0
        case high = 100.0
    }
    // Этот enum определяет состояние, в котором может находиться игра
    enum GameState {
        case notRunning
        case running
    }
    
    // Массив, содержащий все текущие секции тротуара
    var bricks = [SKSpriteNode] ()
    
    //  Массив, содержащий все активные алмазы
    var gems = [SKSpriteNode] ()
    
    // Размер секций на тротуаре
    var brickSize = CGSize.zero
    
    // Текущий уровень определяет положение по оси y для новых секций
    var brickLevel = BrickLevel.low
    
    // Отслеживаем текущее состояние игры
    var gameState = GameState.notRunning
    
    //Настройка скорости движения направо для игры
    //Это значение может увеличиваться по мере продвижения пользователя в игре
    var scrollSpeed: CGFloat = 5.0
    let startingScrollSpeed: CGFloat = 5.0
    
    //Константа для гравитации (того, как быстро обекты падают на Землю)
    let gravitySpeed: CGFloat = 1.5
    
    // Сойства для отслеживания результата
    var score: Int = 0
    var highScore: Int = 0
    var lastScoreUpdateTime: TimeInterval = 0.0
    
    //Время последнего вызова для метода обновления
    var lastUpdateTime: TimeInterval?
    
    // Здесь мы создаем героя игры - скуйтбордистку
    let skater = Skater(imageNamed: "skater")
    
    // MARK:- Setup and Lifecycle Methods
    override func didMove(to view: SKView) {
        run(SKAction.playSoundFileNamed("KSLV Noh - Disaster.mp3", waitForCompletion: false ))
        physicsWorld.gravity = CGVector (dx: 0.0, dy: -6.0)
        physicsWorld.contactDelegate = self
       
        anchorPoint = CGPoint.zero
        
        let background = SKSpriteNode(imageNamed: "background")
        let xMid = frame.midX
        let yMid = frame.midY
        background.position = CGPoint(x: xMid, y: yMid)
        addChild(background)
        
        setupLabels()
        // Создаем скейтбордистку и добавляем ее к сцене
        skater.setupPhysicsBody()
        //Настраиваем свойства скейтбордистки и добавляем ее в сцену resetSkater()
       // resetSkater()
        addChild(skater)
        
        // Добавляем распознаватель нажатия, чтобы знать, когда пользователь нажимает на экран
        let tapMethod = #selector(GameScene.handleTap(tapGesture:))
        let tapGesture = UITapGestureRecognizer(target: self, action: tapMethod)
        view.addGestureRecognizer(tapGesture)
        
        // Добавляем слой меню с текстом "Нажмите, чтобы играть"
        let menuBackgraundColor = UIColor.black.withAlphaComponent(0.4)
        let menuLayer = MenuLayer(color: menuBackgraundColor, size: frame.size)
        menuLayer.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        menuLayer.position = CGPoint(x: 0.0, y: 0.0)
        menuLayer.zPosition = 30
        menuLayer.name = "menuLayer"
        menuLayer.display(message: "Нажмите, чтобы играть", score: nil)
        addChild(menuLayer)
    }
    
    func resetSkater() {
         let skaterX = frame.midX / 2.0
         let skaterY = skater.frame.height / 2.0 + 64.0
         skater.position = CGPoint (x: skaterX, y: skaterY)
         skater.zPosition = 10
         skater.minimumY = skaterY
        
        skater.zRotation = 0.0
        skater.physicsBody?.velocity = CGVector (dx: 0.0, dy: 0.0)
        skater.physicsBody?.angularVelocity = 0.0
    }
    
    func setupLabels() {
        
        // Надпись со словами "очки" в верхнем левом углу
        let scoreTextLabel: SKLabelNode = SKLabelNode  (text: "очки")
        scoreTextLabel.position = CGPoint(x: 14.0, y: frame.size.height - 20.0)
        scoreTextLabel.horizontalAlignmentMode = .left
        scoreTextLabel.fontName = "Courier-Bold"
        scoreTextLabel.fontSize = 14.0
        scoreTextLabel.zPosition = 20
        addChild(scoreTextLabel)
        
        // Надпись с количеством очков игрока в текущей игре
        
        let scoreLable: SKLabelNode = SKLabelNode (text: "0")
        scoreLable.position = CGPoint(x: 14.0, y: frame.size.height - 40.0)
        scoreLable.horizontalAlignmentMode = .left
        scoreLable.fontName = "Courier-Bold"
        scoreLable.fontSize = 18.0
        scoreLable.name = "scoreLabel"
        scoreLable.zPosition = 20
        addChild(scoreLable)
        
        // Надпись "лучший результат" в правом верхнем углу
        let highScoreTextLabel: SKLabelNode = SKLabelNode(text: "лучший результат")
        highScoreTextLabel.position = CGPoint (x: frame.size.width - 14.0, y: frame.size.height - 20.0)
        highScoreTextLabel.horizontalAlignmentMode = .right
        highScoreTextLabel.fontName = "Courier-Bold"
        highScoreTextLabel.fontSize = 14.0
        highScoreTextLabel.zPosition = 20
        addChild(highScoreTextLabel)
        
        // Надпись с максимумом набраных игроком очков
        let highScoreLabel: SKLabelNode = SKLabelNode(text: "0")
        highScoreLabel.position = CGPoint(x: frame.size.width - 14.0, y: frame.size.height - 40.0)
        highScoreLabel.horizontalAlignmentMode = .right
        highScoreLabel.fontName = "Courier-Bold"
        highScoreLabel.fontSize = 18.0
        highScoreLabel.name = "highScoreLabel"
        highScoreLabel.zPosition = 20
        addChild(highScoreLabel)
    }
    func updateScoreLabelText() {
        if let scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode {
            scoreLabel.text = String(format: "%04d", score)
        }
    }
    func updateHighScoreLabelText() {
        if let highScoreLabel = childNode(withName: "highScoreLabel") as? SKLabelNode {
            highScoreLabel.text = String(format: "%04d", highScore)
        }
    }
    func startGame() {

// Перезагрузка начальных условий при запуске новой игры
        
        gameState = .running
        
        // Возращение к начальным условиям при запуске нововой игры
        resetSkater()
        
        score = 0
        
        scrollSpeed = startingScrollSpeed
        brickLevel = .low
        lastUpdateTime = nil
        
        for brick in bricks {
            brick.removeFromParent()
        }
        
        bricks.removeAll(keepingCapacity: true)
        for gem in gems {
            removeGem(gem)
            
        }
    }
    func gameOver() {
        
        // После окончания игры проверяем, добился ли игрок нового рекорда
        
        gameState = .notRunning
        
        // По завершению игры проверяем, добился ли игрок нового рекорда
        if score > highScore {
            highScore = score
            updateHighScoreLabelText()
        }
        // Показываем надпись "Игра окончена!"
        let menuBackgroundColor = UIColor.black.withAlphaComponent(0.4)
        let menuLayer = MenuLayer (color: menuBackgroundColor, size: frame.size)
        menuLayer.anchorPoint = CGPoint.zero
        menuLayer.position = CGPoint.zero
        menuLayer.zPosition = 30
        menuLayer.name = "menuLayer"
        menuLayer.display(message: "Игра окончена!", score: score)
        addChild(menuLayer)
        
    }
    //Задаем начальное положение скейтбордистки, zPosition и minimumY
        func spawnBrick (atPosition position: CGPoint) -> SKSpriteNode {
        //Создаем спрайт секций и добавляем его к сцене
            let brick = SKSpriteNode(imageNamed: "sidewalk")
            brick.position = position
            brick.zPosition = 8
            addChild(brick)
        
            //Обновляем свойство brickSize реальным значением размера секции
            brickSize = brick.size
            
            //Добавляем новую секцию к масиву
            bricks.append(brick)
        
            // Настройка физического тела секции
            let center = brick.centerRect.origin
            brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size, center: center)
            brick.physicsBody?.affectedByGravity = false
            brick.physicsBody?.categoryBitMask = PhysicsCaategory.brick
            brick.physicsBody?.collisionBitMask = 0
            
            //Возвращаем новую секцию вызывающему коду
            return brick
        }
    func spawnGem (atPosition position: CGPoint) {
        
        //Создаем спрайт для алмаза и добавляем его к сцене
        let gem = SKSpriteNode(imageNamed: "gem")
        gem.position = position
        gem.zPosition = 9
        addChild(gem)
        gem.physicsBody = SKPhysicsBody (rectangleOf: gem.size, center: gem.centerRect.origin)
        gem.physicsBody?.categoryBitMask = PhysicsCaategory.gem
        gem.physicsBody?.affectedByGravity = false
        
        // Добавляем новый алмаз к массиву
        gems.append(gem)
    }
    func removeGem (_ gem: SKSpriteNode) {
        
        gem.removeFromParent()
        
        if let gemIndex = gems.firstIndex(of: gem) {
        gems.remove(at: gemIndex)
    }
}
        
    func updateBricks (withScrollAmount currentScrollAmount: CGFloat) {
            //Отслеживаем самое большое значение по оси x для всех существующих секций
            var farthestRigtBrickX: CGFloat = 0.0
            for brick in bricks {
                let newX = brick.position.x - currentScrollAmount
                //Если секция сместилась слишком далеко влево (за пределы экрана), удалите ее
                if newX < -brickSize.width {
                    
                    brick.removeFromParent ()
                    
                    if let brickIndex = bricks.firstIndex(of: brick) {
                        bricks.remove(at: brickIndex)
                    }
                } else {
                    
                    //Для секции, оставшейся на экране, обновляем положение
                    brick.position = CGPoint(x: newX, y: brick.position.y)
                    
                    //Обновляем значение для крайней правой секции
                    if brick.position.x > farthestRigtBrickX {
                        farthestRigtBrickX = brick.position.x
                    }
                }
            }
            // Цикл while, обеспечивающий постоянное наполнение экрана секциями
            while farthestRigtBrickX < frame.width {
                var brickX = farthestRigtBrickX + brickSize.width + 1.0
                let brickY = (brickSize.height / 2.0) + brickLevel.rawValue
                // время от времени мы оставляем разрывы, через котрые герой должен перепрыгнуть
                let randomNumber = arc4random_uniform(99)
                
                if randomNumber < 2 && score > 10 {
                    // 2-процентный шанс на то, что уровень у нас возникнет разрыв между
                    // секциями после того, как игрок набрал 10 призовых очков
                    let gap = 20.0 * scrollSpeed
                    brickX += gap
                 
                    // На каждом разрыве добавляем алмаз
                    let randomGemYAmount = CGFloat(arc4random_uniform(150))
                    let newGemY = brickY + skater.size.height + randomGemYAmount
                    let newGemX = brickX - gap / 2.0
                    
                    spawnGem(atPosition: CGPoint(x: newGemX, y: newGemY))
                }
                else if randomNumber < 4 && score > 20 {
                    // 2-процентный шанс на то, что уровень секции Y изменится
                    // после того, как игрок набрал 20 призовых очков
                    if brickLevel == .high {
                    brickLevel = .low
                }
                    else if brickLevel == .low {
                brickLevel = .high
            }
        }
                //Добавляем новую секцию и обновляем положение самой правой
                let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))
                farthestRigtBrickX = newBrick.position.x
            }
        }
    func updateGems(withScrollAmount currentScrollAmount: CGFloat) {
        
        for gem in gems {
            
            // Обновляем положение каждого алмаза
            let thisGemX = gem.position.x - currentScrollAmount
            gem.position = CGPoint(x: thisGemX, y: gem.position.y)
            
            // Удаляем любые алмазы, ушедшие с экрана
            if gem.position.x < 0.0 {
                
                removeGem(gem)
            }
        }
    }
    func updateSkater () {
       // Определяем, находится ли скейтбордистка на земле
        if let velocityY = skater.physicsBody?.velocity.dy {
            if velocityY < -100.0 || velocityY > 100.0 {
                skater.isOnGround = false
            }
        }
        // Проверяем, должна ли игра закончиться
        let isOffScreen = skater.position.y < 0.0 || skater.position.x < 0.0
        
        let maxRotation = CGFloat (GLKMathDegreesToRadians(85.0))
        let isTippedOver = skater.zRotation > maxRotation || skater.zRotation < -maxRotation
        
        if isOffScreen || isTippedOver {
            gameOver()
        }
    }
    func updateScore(withCurrentTime currentTime: TimeInterval) {
        // Количество очков игрока увеличивется по мере игры
        // Счет обновляется каждую секунду
        
        let elapsedTime = currentTime - lastScoreUpdateTime
        
        if elapsedTime > 1.0 {
            
            // Увеличиваем количество очков
            score += Int(scrollSpeed)
            
            // Присваиваем свойству lastScoreUpdateTime значение текущего времени
            lastScoreUpdateTime = currentTime
            
            updateScoreLabelText()
        }
    }
        /*if !skater.isOnGround {
            
            //Устанавливаем новое значение скорости скейтбордистки с учетом влияния гравитации
            let velocityY = skater.velocity.y - gravitySpeed
            skater.velocity = CGPoint(x: skater.velocity.x, y: velocityY)
            //Устанавливаем новое положение скейтбордистки по оси y на основе ее скорости
            let newSkaterY: CGFloat = skater.position.y + skater.velocity.y
            skater.position = CGPoint (x: skater.position.x, y: newSkaterY)
            if skater.position.y < skater.minimumY {
                
                skater.position.y = skater.minimumY
                skater.velocity = CGPoint.zero
                skater.isOnGround = true
                
            }
            
        }*/
    
    @objc override func update(_ currentTime: TimeInterval) {
        if gameState != .running {
            return
        }
        // Медлено увеличиваем значение scrollSpeed по мере развития игры
        scrollSpeed += 0.01
        // Called before each frame is rendered
        //Определяем время, прошедшее с момента последнего вызова update
        var elapsedTime: TimeInterval = 0.0
        if let lastTimeStamp = lastUpdateTime {
            elapsedTime = currentTime - lastTimeStamp
        }
        lastUpdateTime = currentTime
        let expectedElapsedsedTime: TimeInterval = 1.0 / 60.0
        
        // Расчитываем, насколько далеко должны сдвинутся объекты при данном обновлении
        let scrollAdjustmen = CGFloat (elapsedTime / expectedElapsedsedTime)
        let currentScrollAmount = scrollSpeed * scrollAdjustmen
        
        updateBricks (withScrollAmount: currentScrollAmount)
        
        updateSkater()
        updateGems(withScrollAmount: currentScrollAmount)
        updateScore(withCurrentTime: currentTime)
    }
    
    @objc func handleTap (tapGesture: UITapGestureRecognizer) {
        
        if gameState == .running {
        //Заставим скейтбордистку прыгнуть нажатием на экран, пока она находится на земле
        if skater.isOnGround {
            skater.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 260.0))
            run(SKAction.playSoundFileNamed("jump.wav", waitForCompletion: false))
        //Скейтбордистка прыгает, если игрок нажимает на экран, пока находиться на земле
        //if skater.isOnGround {
            //Задаем для скейтбордистки скорость по оси y, равную ее начальной скорости прыжка
            //skater.velocity = CGPoint(x: 0.0, y: skater.jumpSpeed)            // Отмечаем, что скейтбордистка уже не находится на земле
           // skater.isOnGround = false
        }
    } else {
    // Если игра не запущена, нажмите на экран запускаем новую игру
    if let menuLayer: SKSpriteNode = childNode(withName: "menuLayer") as? SKSpriteNode {
    menuLayer.removeFromParent()
    }
        startGame()
    }
}
        //MARK:- SKPhysicsContactDelegate Methods
        func didBegin (_ contact: SKPhysicsContact) {
            //Проверяем, есть ли контакт между скейтбордисткой и секцией
            if contact.bodyA.categoryBitMask == PhysicsCaategory.skater && contact.bodyB.categoryBitMask == PhysicsCaategory.brick {
            
                if let velocitiY = skater.physicsBody?.velocity.dy {
                    if !skater.isOnGround && velocitiY < 100.0 {
                        skater.createSparks()
                    }
                }
                
                skater.isOnGround = true
            }
            else if contact.bodyA.categoryBitMask == PhysicsCaategory.skater && contact.bodyB.categoryBitMask == PhysicsCaategory.gem {
                
                //Скейтбордистка коснулась алмаза, поэтому мы его убираем
                if let gem = contact.bodyB.node as? SKSpriteNode {
                    removeGem(gem)
                    // Даем игроку 50 очков за собраный алмаз
                    score += 50
                    updateScoreLabelText()
                    
                    run(SKAction.playSoundFileNamed("gem.wav", waitForCompletion: false ))
                }
            }
        }
    }
