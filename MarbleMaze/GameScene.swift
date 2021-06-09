//
//  GameScene.swift
//  MarbleMaze
//
//  Created by Paul Richardson on 10/06/2021.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {

	override func didMove(to view: SKView) {
		loadLevel()
	}

	loadLevel() {
		guard let levelURL = Bundle.main.url(forResource: "level1", withExtension: "txt") else { return }
		guard let levelString = try? String(contentsOf: levelURL) else { return }

		let lines = levelString.components(separatedBy: "\n")

		for (row, line) in lines.reversed().enumerated() {
			for (column, letter) in line.enumerated() {
				if letter == "x" {
					// load wall
				} else if letter = "v" {
					// load vortex
				} else if letter = "s" {
					// load star
				} else if letter = "f" {
					// load finish
				} else if letter = " " {
					// this is an empty space - do nothing
				}
			}
		}

	}

}
