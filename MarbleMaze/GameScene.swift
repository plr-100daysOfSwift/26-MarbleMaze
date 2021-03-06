//
//  GameScene.swift
//  MarbleMaze
//
//  Created by Paul Richardson on 10/06/2021.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {

	// MARK:-  Properties

	var level = 0
	var player: SKSpriteNode!
	var maze: SKNode!
	var teleports: [SKSpriteNode]!
	var teleportsOpen = true
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

		teleports = []
		maze = SKNode()
		addChild(maze)

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

	fileprivate func loadLevel() {
		guard let levelURL = Bundle.main.url(forResource: "level\(level)", withExtension: "txt") else {
			fatalError("Could not find level1.txt in the app bundle.")
		}
		guard let levelString = try? String(contentsOf: levelURL) else {
			fatalError("Could not load level1.txt from the app bundle")
		}

		let lines = levelString.components(separatedBy: "\n").filter({ !$0.isEmpty })
		let cellSize = (width: 64, height: 64)

		for (row, line) in lines.reversed().enumerated() {
			for (column, letter) in line.enumerated() {
				let position = CGPoint(x: (cellSize.width * column) + (cellSize.width / 2), y: (cellSize.height * row) + (cellSize.height / 2))
				guard let nodeType = NodeType(rawValue: letter) else {
					fatalError("Unknown letter: \(letter)")
				}
				loadNode(nodeType, at: position)
			}
		}
	}

	fileprivate func loadNode(_ type: NodeType, at position: CGPoint) {
		guard type != NodeType.space else { return }
		let name = type.name
		let node = SKSpriteNode(imageNamed: name)
		node.position = position
		node.name = name

		switch type {
		case .block:
			node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
		default:
			node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
		}

		node.physicsBody?.contactTestBitMask = type.contactBitMask
		node.physicsBody?.collisionBitMask = type.collisionBitMask
		node.physicsBody?.categoryBitMask = type.categoryBitMask

		switch type {
		case .vortex:
			node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
		case .teleport:
			teleports.append(node)
		default:
			break
		}

		node.physicsBody?.isDynamic = false
		maze.addChild(node)
	}

	fileprivate func createPlayer() {
		let node = NodeType.player
		player = SKSpriteNode(imageNamed: node.name)
		player.position = CGPoint(x: 96, y: 672)
		player.zPosition = 1
		player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
		player.physicsBody?.allowsRotation = false
		player.physicsBody?.linearDamping = 0.5
		player.physicsBody?.categoryBitMask = node.categoryBitMask
		player.physicsBody?.contactTestBitMask = node.contactBitMask
		player.physicsBody?.collisionBitMask = node.collisionBitMask
		player.alpha = 0
		player.scale(to: CGSize(width: 0, height: 0))
		addChild(player)
		let scale = SKAction.scale(to: 1.0, duration: 0.25)
		let fadeIn = SKAction.fadeIn(withDuration: 0.25)
		let group = SKAction.group([scale, fadeIn])
		player.run(group)
	}

	fileprivate func playerCollided(with node: SKNode) {
		let name = node.name
		switch name {
		case NodeType.vortex.name:
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
				self?.teleportsOpen = true
			}
		case NodeType.star.name:
			node.removeFromParent()
			score += 1
		case NodeType.teleport.name:
			guard teleportsOpen else {
				return
			}
			teleportsOpen.toggle()
			let destination: CGPoint!
			if node == teleports[0] {
				destination = teleports[1].position
			} else {
				destination = teleports[0].position
			}
			let move = SKAction.move(to: node.position, duration: 0.25)
			let fadeOut = SKAction.fadeOut(withDuration: 0.25)
			let wait = SKAction.wait(forDuration: 0.25)
			let shift = SKAction.move(to: destination, duration: 0.0)
			let fadeIn = SKAction.fadeIn(withDuration: 0.25)
			let sequence = SKAction.sequence([move, fadeOut, shift, wait, fadeIn])
			player.run(sequence, completion: { [weak self] in
				self?.teleportsOpen.toggle()
			})
		case NodeType.finish.name:
			let move = SKAction.move(to: node.position, duration: 0.25)
			let scale = SKAction.scale(to: 0.0001, duration: 0.25)
			let remove = SKAction.removeFromParent()
			let sequence = SKAction.sequence([move, scale, remove])
			player.run(sequence) { [weak self] in
				self?.moveToNextLevel()
			}
		default:
			break
		}
	}

	fileprivate func moveToNextLevel() {
		isGameOver = true
		level += 1
		maze.removeAllChildren()
		teleports.removeAll()
		loadLevel()

		run(SKAction.wait(forDuration: 1.0)) { [weak self] in
			self?.createPlayer()
			self?.isGameOver = false
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
