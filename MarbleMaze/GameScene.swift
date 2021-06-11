//
//  GameScene.swift
//  MarbleMaze
//
//  Created by Paul Richardson on 10/06/2021.
//

import SpriteKit
import CoreMotion

enum CollisionTypes: UInt32 {
	case player = 1
	case wall = 2
	case star = 4
	case vortex = 8
	case finish = 16
}

class GameScene: SKScene, SKPhysicsContactDelegate {

	// MARK:-  Properties

	var player: SKSpriteNode!
	var lastTouchPosition: CGPoint?
	var motionManager: CMMotionManager!
	var scoreLabel: SKLabelNode!
	var score = 0 {
		didSet {
			scoreLabel.text = "Score: \(score)"
		}
	}
	var isGameOver = false

	// MARK:-  Life Cycle

	override func didMove(to view: SKView) {
		let background = SKSpriteNode(imageNamed: "background")
		background.position = CGPoint(x: 512, y: 384)
		background.blendMode = .replace
		background.zPosition = -1
		addChild(background)

		scoreLabel = SKLabelNode(text: "Score: \(score)")
		scoreLabel.fontName = "Chalkduster"
		scoreLabel.horizontalAlignmentMode = .left
		scoreLabel.position = CGPoint(x: 16, y: 16)
		scoreLabel.zPosition = 2
		addChild(scoreLabel)

		physicsWorld.contactDelegate = self
		physicsWorld.gravity = .zero

		loadLevel()
		createPlayer()
		motionManager = CMMotionManager()
		motionManager.startAccelerometerUpdates()

	}

	override func update(_ currentTime: TimeInterval) {
		guard isGameOver == false else { return }
		#if targetEnvironment(simulator)
		if let currentTouch = lastTouchPosition {
			let diff = CGPoint(x: currentTouch.x - player.position.x, y: currentTouch.y - player.position.y)
			physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
		}
		#else
		if let acceleromterData = motionManager.accelerometerData {
			physicsWorld.gravity = CGVector(dx: acceleromterData.acceleration.y * -50, dy: acceleromterData.acceleration.x * 50)
		}
		#endif
	}

	// MARK:- Private Methods

	fileprivate func loadWall(_ position: CGPoint) {
		// load wall
		let node = SKSpriteNode(imageNamed: "block")
		node.position = position

		node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
		node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
		node.physicsBody?.isDynamic = false
		addChild(node)
	}

	fileprivate func loadVortex(_ position: CGPoint) {
		// load vortex
		let node = SKSpriteNode(imageNamed: "vortex")
		node.name = "vortex"
		node.position = position
		node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
		node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
		node.physicsBody?.isDynamic = false

		node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
		node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
		node.physicsBody?.collisionBitMask = 0
		addChild(node)
	}

	fileprivate func loadStar(_ position: CGPoint) {
		// load star
		let node = SKSpriteNode(imageNamed: "star")
		node.name = "star"
		node.position = position
		node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
		node.physicsBody?.isDynamic = false

		node.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
		node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
		node.physicsBody?.collisionBitMask = 0
		addChild(node)
	}

	fileprivate func loadFinish(_ position: CGPoint) {
		// load finish
		let node = SKSpriteNode(imageNamed: "finish")
		node.name = "finish"
		node.position = position
		node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
		node.physicsBody?.isDynamic = false

		node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
		node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
		node.physicsBody?.collisionBitMask = 0
		addChild(node)
	}

	fileprivate func loadLevel() {
		guard let levelURL = Bundle.main.url(forResource: "level1", withExtension: "txt") else {
			fatalError("Could not find level1.txt in the app bundle.")
		}
		guard let levelString = try? String(contentsOf: levelURL) else {
			fatalError("Could not load level1.txt from the app bundle")
		}

		let lines = levelString.components(separatedBy: "\n")

		for (row, line) in lines.reversed().enumerated() {
			for (column, letter) in line.enumerated() {
				let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)
				switch letter {
				case "x":
					loadWall(position)
				case "v":
					loadVortex(position)
				case "s":
					loadStar(position)
				case "f":
					loadFinish(position)
				case " ":
					break
				default:
					fatalError("Unknown letter: \(letter)")
				}

			}
		}

	}

	fileprivate func createPlayer() {
		player = SKSpriteNode(imageNamed: "player")
		player.position = CGPoint(x: 96, y: 672)
		player.zPosition = 1
		player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
		player.physicsBody?.allowsRotation = false
		player.physicsBody?.linearDamping = 0.5
		player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
		player.physicsBody?.contactTestBitMask = CollisionTypes.star.rawValue | CollisionTypes.vortex.rawValue |
			CollisionTypes.finish.rawValue
		player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
		addChild(player)
	}

	fileprivate func playerCollided(with node: SKNode) {
		if node.name == "vortex" {
			player.physicsBody?.isDynamic = false
			isGameOver = true
			score -= 1
			let move = SKAction.move(to: node.position, duration: 0.25)
			let scale = SKAction.scale(to: 0.0001, duration: 0.25)
			let remove = SKAction.removeFromParent()
			let sequence = SKAction.sequence([move, scale, remove])
			player.run(sequence) { [weak self] in
				self?.createPlayer()
				self?.isGameOver = false
			}
		} else if node.name == "star" {
			node.removeFromParent()
			score += 1
		} else if node.name == "finish" {
			// go to next level
		}
	}

	// MARK:-  Touches

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return	}
		let location = touch.location(in: self)
		lastTouchPosition = location
	}

	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return	}
		let location = touch.location(in: self)
		lastTouchPosition = location
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		lastTouchPosition = nil
	}

	// MARK:- PhysicsWorldContactDelegate Methods

	func didBegin(_ contact: SKPhysicsContact) {
		guard let nodeA = contact.bodyA.node else { return }
		guard let nodeB = contact.bodyB.node else { return }

		if nodeA == player {
			playerCollided(with: nodeB)
		} else if nodeB == player {
			playerCollided(with: nodeA)
		}
	}
}
