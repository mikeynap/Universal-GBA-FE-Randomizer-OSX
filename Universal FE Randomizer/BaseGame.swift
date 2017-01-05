//
//  BaseGame.swift
//  Universal FE Randomizer
//
//  Created by Shen Lu on 10/11/15.
//  Copyright © 2015 Shen Lu. All rights reserved.
//

import Foundation

protocol BaseGame : class {
    func gameTitle() -> String
    func cleanCRC32() -> UInt32
    func japaneseCRC32() -> UInt32 // Really only applies to FE6.
    
    func characterTableOffsetAddress() -> UInt32
    func defaultCharacterTableOffset() -> UInt32
    func defaultCharacterCount() -> Int
    func characterObjectSize() -> Int // In bytes
    
    func playableCharacterList() -> [FECharacter]
    func bossCharacterList() -> [FECharacter]
    func isCharacterPlayable(characterObject: FECharacterData) -> Bool
    func isCharacterABoss(characterObject: FECharacterData) -> Bool
    
    func eligibleClasses() -> [FEClass]
    func chapterTableOffsetAddress() -> UInt32
    func chapterObjectSize() -> Int
    func createChapterObjectFromData(chapterData: NSData) -> FEChapterData?
    func standardCharacterList() -> [FECharacter]
    func lordCharacterList() -> [FECharacter]
    func thiefCharacterList() -> [FECharacter]
    
    func standardClassList() -> [FEClass]
    func extendedClassList() -> [FEClass]
    func lordClassList() -> [FEClass]
    func thiefClassList() -> [FEClass]
    
    func chapterPointers() -> [UInt32]
    func charactersInChapter() -> [Int] 
    func characterLinksForCharacter(character: FECharacter) -> [FECharacter]
    
    func createCharacterObjectFromData(characterData: NSData) -> FECharacterData?
    func dataForCharacterObject(characterData: FECharacterData) -> NSData?
    func dataForChapterObject(chapterData: FEChapterData) -> NSData?
}

extension BaseGame {
    func nameFrom(id: UInt8) -> String {
        for pcl in playableCharacterList() {
            if id == pcl.characterID {
                return pcl.displayName
            }
        }
        return ""
    }
    
    func classNameFrom(id: UInt8) -> FEClass? {
        for pcl in eligibleClasses() {
            if id == pcl.classID {
                return pcl
            }
        }
        return nil
    }

}
