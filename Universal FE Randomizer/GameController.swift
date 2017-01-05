//
//  GameController.swift
//  Universal FE Randomizer
//
//  Created by Shen Lu on 5/15/16.
//  Copyright © 2016 Shen Lu. All rights reserved.
//

import Foundation

var MAXWEAPON: UInt8 = 0xFB

class GameController : NSObject {
    
    var fsUrl : NSURL!
    var rawData : NSMutableData?
    
    var baseGame : BaseGame?
    
    init(fileURL: NSURL) {
        fsUrl = fileURL;
        
        super.init();
    }
    
    func readChapterData(characters: [FECharacterData]) -> [UInt8: FEChapterData] {
        //var chapterTableOffset : UInt32 = readPointerFromDataAtOffset(self.baseGame!.chapterTableOffsetAddress())
        // Remember addresses in game are mapped starting from 0x8000000.
     //   var chapterTableOffset : UInt32 = self.baseGame!.chapterTableOffsetAddress()
        //chapterTableOffset -= 0x08000000;
        
        let chapters = self.baseGame!.chapterPointers()
        var chapterDataObjects : [UInt8: FEChapterData] = [UInt8: FEChapterData]()
        let nCharacters = self.baseGame!.charactersInChapter()
        var i = 0
        for offset in chapters {
            var currentOffset : UInt32 = offset
            for _ in nCharacters {
                let chapterRawData : NSData = self.rawData!.subdataWithRange(NSRange.init(location: Int(currentOffset), length: self.baseGame!.chapterObjectSize()));
                var chapterObjectData : FEChapterData? = self.baseGame!.createChapterObjectFromData(chapterRawData)
                if (chapterObjectData != nil && chapterObjectData!.characterID != 0 && chapterObjectData!.levelAlliance != 0) {
                    var found: Bool = false
                    for c in characters {
                        if c.characterId == chapterObjectData!.characterID && (c.classId == chapterObjectData!.classID || chapterObjectData!.classID == 0) {
                            found = true
                            break
                        }
                    }
                    if !found {
                        print("Not a match! Got \(chapterObjectData!.characterID)/\(chapterObjectData!.classID), \(chapterObjectData)")
                        currentOffset += UInt32(self.baseGame!.chapterObjectSize());
                        continue
                    }
                    
                    if chapterDataObjects[chapterObjectData!.characterID] == nil {
                        chapterObjectData!.offset = currentOffset
                        chapterDataObjects[chapterObjectData!.characterID] = chapterObjectData!;
                    } else {
                        print("Already Set \(chapterObjectData!.characterID) -- \(chapterObjectData)")
                    }
                }
                currentOffset += UInt32(self.baseGame!.chapterObjectSize());
            }
            i += 1
        }
        return chapterDataObjects
    }
    
    func readCharacterData() -> [FECharacterData] {
        var characterTableOffset : UInt32 = readPointerFromDataAtOffset(self.baseGame!.characterTableOffsetAddress());
        // Remember addresses in game are mapped starting from 0x8000000.
        characterTableOffset -= 0x08000000;
        if (characterTableOffset != self.baseGame!.defaultCharacterTableOffset()) {
            // The offset has changed. (Game hacked?)
            assertionFailure();
        }
        
        var characterDataObjects : [FECharacterData] = [FECharacterData]()
        
        var currentOffset : UInt32 = characterTableOffset;
        for _ in 1...self.baseGame!.defaultCharacterCount() {
            let characterRawData : NSData = self.rawData!.subdataWithRange(NSRange.init(location: Int(currentOffset), length: self.baseGame!.characterObjectSize()));
            currentOffset += UInt32(self.baseGame!.characterObjectSize());
            let characterObjectData : FECharacterData? = self.baseGame!.createCharacterObjectFromData(characterRawData)
            if (characterObjectData != nil) {
                if (self.baseGame!.isCharacterPlayable(characterObjectData!)) {
                    characterDataObjects.append(characterObjectData!);
                }
            }
        }
        return characterDataObjects

    }
    
    func validate() -> Bool {
        rawData = NSMutableData.init(contentsOfFile: fsUrl.path!);
        
        if (rawData != nil && rawData!.length > 0xB0) {
            let gameCode : NSData = rawData!.subdataWithRange(NSRange.init(location: 0xAC, length: 4));
        
            let gameCodeString : String = String(data: gameCode, encoding: NSUTF8StringEncoding)!;
            
            if (gameCodeString == "AFEJ") {
                baseGame = FE6()
            }
            if (gameCodeString == "AE7E") {
                baseGame = FE7()
            }
            if (gameCodeString == "BE8E") {
                baseGame = FE8()
            }
        }
        
        if (baseGame == nil) { return false; }
        
        // Check CRC32
        let checksum : CRC32 = CRC32.init(data: rawData!);
        if (checksum.crc == baseGame!.cleanCRC32()) {
            return true;
        }
        else if (checksum.crc == baseGame!.japaneseCRC32() && baseGame! is FE6) {
            
            // Attempt to patch.
            let patchPath : String? = NSBundle.mainBundle().pathForResource("FE6-TLRedux-v1.0", ofType: "ups");
            
            let patchedData :NSMutableData = UPSPatcher.sharedInstance.patch(rawData!, patchFilePath:patchPath!)!;

            rawData = patchedData;
//            let components : NSURLComponents = NSURLComponents.init(string: fsUrl.absoluteString)!;
//            let path : String = components.path!;
//            let pathComponents : NSMutableArray = NSMutableArray.init(array:path.componentsSeparatedByString("/"));
//            pathComponents.replaceObjectAtIndex(pathComponents.count - 1, withObject: "Patched2.gba");
//            components.path = pathComponents.componentsJoinedByString("/");
//            
//            
//            patchedData.writeToFile(components.path!, atomically: true);
            
            return true;
        }
        // CHANGE TO FALSE
        return true;
        //return false;
    }
    
    func randomizeWithRandomizationSettings(settings: RandomizationSettings) {
        if (settings.randomizeGrowthsEnabled) {
            var characterDataObjects : [FECharacterData] = [FECharacterData]()

            
            var updatedCharacters : [FECharacterData] = [FECharacterData]()
            
            switch (settings.growthsMethod) {
            case GrowthMethod.Variance:
                for index in 1...characterDataObjects.count {
                    var characterData : FECharacterData = characterDataObjects[index - 1];
                    // Randomize HP Growth
                    var targetHPGrowth : Int = Int(characterData.hpGrowth) + randomDelta(settings.varianceGrowthsVarianceAmount, offset: 0);
                    targetHPGrowth = min(max(targetHPGrowth, 0), 255);
                    
                    
                    characterData.hpGrowth = UInt8(targetHPGrowth);
                    
                    // Randomize STR/MAG Growth
                    var targetSTRGrowth : Int = Int(characterData.strGrowth) + randomDelta(settings.varianceGrowthsVarianceAmount, offset: 0);
                    targetSTRGrowth = min(max(targetSTRGrowth, 0), 255);
                    characterData.strGrowth = UInt8(targetSTRGrowth);
                    
                    // Randomize SKL Growth
                    var targetSKLGrowth : Int = Int(characterData.sklGrowth) + randomDelta(settings.varianceGrowthsVarianceAmount, offset: 0);
                    targetSKLGrowth = min(max(targetSKLGrowth, 0), 255);
                    characterData.sklGrowth = UInt8(targetSKLGrowth);
                    
                    // Randomize SPD Growth
                    var targetSPDGrowth : Int = Int(characterData.spdGrowth) + randomDelta(settings.varianceGrowthsVarianceAmount, offset: 0);
                    targetSPDGrowth = min(max(targetSPDGrowth, 0), 255);
                    characterData.spdGrowth = UInt8(targetSPDGrowth);
                    
                    // Randomize LCK Growth
                    var targetLCKGrowth : Int = Int(characterData.lckGrowth) + randomDelta(settings.varianceGrowthsVarianceAmount, offset: 0);
                    targetLCKGrowth = min(max(targetLCKGrowth, 0), 255);
                    characterData.lckGrowth = UInt8(targetLCKGrowth);
                    
                    // Randomize DEF Growth
                    var targetDEFGrowth : Int = Int(characterData.defGrowth) + randomDelta(settings.varianceGrowthsVarianceAmount, offset: 0);
                    targetDEFGrowth = min(max(targetDEFGrowth, 0), 255);
                    characterData.defGrowth = UInt8(targetDEFGrowth);
                    
                    // Randomize RES Growth
                    var targetRESGrowth : Int = Int(characterData.resGrowth) + randomDelta(settings.varianceGrowthsVarianceAmount, offset: 0);
                    targetRESGrowth = min(max(targetRESGrowth, 0), 255);
                    characterData.resGrowth = UInt8(targetRESGrowth);
                    
                    
                    
                    /* MIKEY: TODO: DELETE TESTING ONLY
                    characterData.classId = 0x09
                    characterData.axeLevel = 0xFB
                    characterData.swordLevel = 0xFB
                    characterData.bowLevel = 0xFB
                    characterData.lightLevel = 0xFB
                    characterData.darkLevel = 0xFB
                    characterData.spearLevel = 0xFB
                    characterData.staffLevel = 0xFB
                    characterData.baseHP = 100
                    characterData.baseStr = 100
                    characterData.baseSpd = 100
                    characterData.baseSkl = 100
                    characterData.baseLck = 100
                    
                    
                    characterData.animaLevel = 0xFB
                    
                    
                    // END MIKEY TODO TESTING ONLY 
                    */

                    
                    updatedCharacters.append(characterData);
                }
                break
            case GrowthMethod.Redistribution:
                for index in 1...characterDataObjects.count {
                    var characterData : FECharacterData = characterDataObjects[index - 1];
                    // Add up all of the character's growths.
                    var totalGrowths : Int = 0;
                    totalGrowths += Int(characterData.hpGrowth);
                    totalGrowths += Int(characterData.strGrowth);
                    totalGrowths += Int(characterData.sklGrowth);
                    totalGrowths += Int(characterData.spdGrowth);
                    totalGrowths += Int(characterData.lckGrowth);
                    totalGrowths += Int(characterData.defGrowth);
                    totalGrowths += Int(characterData.resGrowth);
                    
                    totalGrowths += randomDelta(settings.redistributionGrowthsVarianceAmount, offset: 0);
                    
                    var targetHPGrowth : Int = 0;
                    var targetSTRGrowth : Int = 0;
                    var targetSKLGrowth : Int = 0;
                    var targetSPDGrowth : Int = 0;
                    var targetLCKGrowth : Int = 0;
                    var targetDEFGrowth : Int = 0;
                    var targetRESGrowth : Int = 0;
                    
                    while (totalGrowths > 0) {
                        // There's 7 areas, but we'll weight HP 3 of them to bias a higher growth there.
                        let growthArea : UInt32 = arc4random_uniform(9);
                        switch (growthArea) {
                        case 0...2:
                            if (targetHPGrowth <= 250) {
                                targetHPGrowth += 5;
                                totalGrowths -= 5;
                            }
                            break
                        case 3:
                            if (targetSTRGrowth <= 250) {
                                targetSTRGrowth += 5;
                                totalGrowths -= 5;
                            }
                            break
                        case 4:
                            if (targetSKLGrowth <= 250) {
                                targetSKLGrowth += 5;
                                totalGrowths -= 5;
                            }
                            break
                        case 5:
                            if (targetSPDGrowth <= 250) {
                                targetSPDGrowth += 5
                                totalGrowths -= 5;
                            }
                            break
                        case 6:
                            if (targetLCKGrowth <= 250) {
                                targetLCKGrowth += 5;
                                totalGrowths -= 5;
                            }
                            break
                        case 7:
                            if (targetDEFGrowth <= 250) {
                                targetDEFGrowth += 5;
                                totalGrowths -= 5;
                            }
                            break
                        case 8:
                            if (targetRESGrowth <= 250) {
                                targetRESGrowth += 5;
                                totalGrowths -= 5;
                            }
                            break
                        default:
                            break
                        }
                    }
                    
                    characterData.hpGrowth = UInt8(targetHPGrowth);
                    characterData.strGrowth = UInt8(targetSTRGrowth);
                    characterData.sklGrowth = UInt8(targetSKLGrowth);
                    characterData.spdGrowth = UInt8(targetSPDGrowth);
                    characterData.lckGrowth = UInt8(targetLCKGrowth);
                    characterData.defGrowth = UInt8(targetDEFGrowth);
                    characterData.resGrowth = UInt8(targetRESGrowth);
                    
                    updatedCharacters.append(characterData);
                }
                break
            case GrowthMethod.Full:
                for index in 1...characterDataObjects.count {
                    var characterData : FECharacterData = characterDataObjects[index - 1];
                    // Randomize HP Growth
                    characterData.hpGrowth = UInt8(randomAbsolute(settings.minimumAllowedGrowth, maxValue: settings.maximumAllowedGrowth));

                    // Randomize STR/MAG Growth
                    characterData.strGrowth = UInt8(randomAbsolute(settings.minimumAllowedGrowth, maxValue: settings.maximumAllowedGrowth));
                    
                    // Randomize SKL Growth
                    characterData.sklGrowth = UInt8(randomAbsolute(settings.minimumAllowedGrowth, maxValue: settings.maximumAllowedGrowth));
                    
                    // Randomize SPD Growth
                    characterData.spdGrowth = UInt8(randomAbsolute(settings.minimumAllowedGrowth, maxValue: settings.maximumAllowedGrowth));
                    
                    // Randomize LCK Growth
                    characterData.lckGrowth = UInt8(randomAbsolute(settings.minimumAllowedGrowth, maxValue: settings.maximumAllowedGrowth));
                    
                    // Randomize DEF Growth
                    characterData.defGrowth = UInt8(randomAbsolute(settings.minimumAllowedGrowth, maxValue: settings.maximumAllowedGrowth));
                    
                    // Randomize RES Growth
                    characterData.resGrowth = UInt8(randomAbsolute(settings.minimumAllowedGrowth, maxValue: settings.maximumAllowedGrowth));
                    
                    updatedCharacters.append(characterData);
                }
                break
            }
            
            commitGrowthsChangesForCharacters(updatedCharacters);
        }
        else if settings.randomizeCustomValues.count > 0 {
            commitGrowthsChangesForCharacters(settings.randomizeCustomValues);
            
            for c in settings.randomizeCustomValues {
                if c.chapterData != nil {
                    commitChapterChanges(c.chapterData!)
                }
            }
        }
    }
    
    private func commitChapterChanges(c: FEChapterData){
        let updatedRawData : NSData? = self.baseGame!.dataForChapterObject(c);
        if (updatedRawData != nil) {
            print("Commiting: \(c)")
            self.rawData!.replaceBytesInRange(NSRange.init(location: Int(c.offset), length: self.baseGame!.chapterObjectSize()), withBytes: updatedRawData!.bytes);
        }
            
    }
    
    private func commitGrowthsChangesForCharacters(characterArray: [FECharacterData]) {
        // Create a dictionary first for easier lookup.
        var characterLookup : [UInt8 : FECharacterData] = [UInt8 : FECharacterData]();
        
        for characterData in characterArray {
            characterLookup[characterData.characterId] = characterData;
        }
        let characterTableOffset : UInt32 = readPointerFromDataAtOffset(self.baseGame!.characterTableOffsetAddress()) - 0x8000000;
        
        var currentOffset : UInt32 = characterTableOffset;
        for _ in 1...self.baseGame!.defaultCharacterCount() {
            let characterRawData : NSData = self.rawData!.subdataWithRange(NSRange.init(location: Int(currentOffset), length: self.baseGame!.characterObjectSize()));
            let characterObjectData : FECharacterData? = self.baseGame!.createCharacterObjectFromData(characterRawData)
            if (characterObjectData != nil) {
                let updatedData : FECharacterData? = characterLookup[characterObjectData!.characterId];
                if (updatedData != nil) {
                    let updatedRawData : NSData? = self.baseGame!.dataForCharacterObject(updatedData!);
                    if (updatedRawData != nil) {
                        self.rawData!.replaceBytesInRange(NSRange.init(location: Int(currentOffset), length: self.baseGame!.characterObjectSize()), withBytes: updatedRawData!.bytes);
                    }
                }
            }
            
            currentOffset += UInt32(self.baseGame!.characterObjectSize());
        }

    }
    
    private func randomDelta(maxMagnitude: Int, offset: Int) -> Int {
        let randomMagnitude : UInt32 = arc4random_uniform(UInt32(maxMagnitude));
        let isNegative : Bool = arc4random_uniform(2) == 0;
        
        return Int(randomMagnitude) * (isNegative ? -1 : 1) + offset;
    }
    
    private func randomAbsolute(minValue: Int, maxValue: Int) -> Int {
        let randomMagnitude : UInt32 = arc4random_uniform(UInt32(maxValue - minValue));

        return Int(randomMagnitude + UInt32(minValue));
    }
    
    func readPointerFromDataAtOffset(offset: UInt32) -> UInt32 {
        if (self.rawData != nil) {
            let unwrappedData : NSMutableData! = self.rawData!;
            var value : UInt32 = 0;
            var currentByte : UInt8 = 0;
            unwrappedData.getBytes(&currentByte, range: NSRange.init(location: Int(offset), length: 1));
            value = UInt32(currentByte);
            unwrappedData.getBytes(&currentByte, range: NSRange.init(location: Int(offset+1), length: 1));
            value = value | (UInt32(currentByte) << 8);
            unwrappedData.getBytes(&currentByte, range: NSRange.init(location: Int(offset+2), length: 1));
            value = value | (UInt32(currentByte) << 16);
            unwrappedData.getBytes(&currentByte, range: NSRange.init(location: Int(offset+3), length: 1));
            value = value | (UInt32(currentByte) << 24);
            
            return value;
        }
        
        return 0;
    }
}

