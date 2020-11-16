//
//  MarvelAPIRouteTests.swift
//  CharactersAPITests
//
//  Created by Hugo Alonso on 16/11/2020.
//

import XCTest
@testable import CharactersAPI

class MarvelAPIRouteTests: XCTestCase {
    func testGetRouteListCharacters() {
        let sut = RouteComposer(url: URL(string: "https://gateway.marvel.com:443/v1/public/")!)
        XCTAssertEqual(sut.characters(), URL(string: "https://gateway.marvel.com:443/v1/public/characters")!)
    }

    func testGetRouteFetchSingleCharacter() {
        let sut = RouteComposer(url: URL(string: "https://gateway.marvel.com:443/v1/public/")!)
        XCTAssertEqual(sut.character(withId: 1), URL(string: "https://gateway.marvel.com:443/v1/public/characters/1")!)
    }
}