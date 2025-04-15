//
//  GTRVDTO.swift
//  UpdateGTA5Meta
//
//  Created by Alexey Vorobyov on 15.04.2025.
//

import Foundation

public struct RadioStation: Identifiable, Codable {
    let index: Int
    let number: Int
    let name: String
    let image: String
    let imagePosition: Position
    let randomize: Bool
    let rotate: Bool
    let root: String?
    let songs: [Song]?
    let general: [String]?
    let sid: [String]?
    let mono_solo: [String]?
    let time: [String: [String]]?
    let to: [String: [String]]?
    public var id: Int {
        number
    }
}

struct Song: Codable {
    let file: String
    let root: String
    let labels: [Label]
    let set: String?
    let intros: [Intro]
}

struct Label: Codable {
    let artist: String
    let title: String
    let time: TimeInterval
}


struct Intro: Codable {
    let file: String
    let delay: Double
}


struct Position: Codable {
    let row: Int
    let column: Int
}
