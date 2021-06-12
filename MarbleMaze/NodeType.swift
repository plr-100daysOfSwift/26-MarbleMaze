//
//  NodeType.swift
//  MarbleMaze
//
//  Created by Paul Richardson on 12/06/2021.
//

import Foundation

enum NodeType: Character {
	
	case player = "p"
	case block = "x"
	case vortex = "v"
	case star = "s"
	case finish = "f"
	case space = " "

	var name: String {
		switch self {
		case .player:
			return "player"
		case .block:
			return "block"
		case .vortex:
			return "vortex"
		case .star:
			return "star"
		case .finish:
			return "finish"
		default:
			return ""
		}
	}

	var categoryBitMask: UInt32 {
		switch self {
		case .player:
			return  1
		case .block:
			return  2
		case .vortex:
			return  4
		case .star:
			return  8
		case .finish:
			return  16
		default:
			return 0
		}
	}

	var collisionBitMask: UInt32 {
		switch self {
		case .vortex, .star, .finish:
			return 0
		case.player:
			return NodeType.block.categoryBitMask
		default:
			return 1
		}
	}

	var contactBitMask: UInt32 {
		switch self {
		case .vortex, .star, .finish:
			return NodeType.player.categoryBitMask
		case .player:
			return NodeType.star.categoryBitMask | NodeType.vortex.categoryBitMask | NodeType.finish.categoryBitMask
		default:
			return 1
		}
	}

}
