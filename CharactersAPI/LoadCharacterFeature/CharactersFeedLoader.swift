//
//  CharactersFeedLoader.swift
//  CharactersAPI
//
//  Created by Hugo Alonso on 16/11/2020.
//

import Foundation

public protocol CharacterFeedLoader {
    func load(id: Int?, completion: @escaping (Result<MarvelCharacter, Error>) -> Void)
}
