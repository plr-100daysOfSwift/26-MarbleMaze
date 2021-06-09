//
//  GameScene.swift
//  MarbleMaze
//
//  Created by Paul Richardson on 10/06/2021.
//

import SpriteKit
import GameplayKit

enum CategoryTypes: UInt32 {
	case player = 1
	case wall = 2
	case star = 4
	case vortex = 8
	case finish = 16
}

class GameScene: SKScene {

	override func didMove(to view: SKView) {
		loadLevel()
	}

	func loadLevel() {
		guard let levelURL = Bundle.main.url(forResource: "level1", withExtension: "txt") else {
			fatalError("Could not find level1.txt in the app bundle.")
		}
		guard let levelString = try? String(contentsOf: levelURL) else {
			fatalError("Could not load level1.txt from the app bundle")
		}

		let lines = levelString.components(separatedBy: "\n")

		for (row, line) in lines.reversed().enumerated() {
			for (column, letter) in line.enumerated() {
				if letter == "x" {
					// load wall
				} else if letter == "v" {
					// load vortex
				} else if letter == "s" {
					// load star
				} else if letter == "f" {
					// load finish
				} else if letter == " " {
					// this is an empty space - do nothing
				} else {
					fatalError("Unknown letter: \(letter)")
				}

			}
		}

	}

}
