//
//  GrowthsDetailViewController.swift
//  Universal FE Randomizer
//
//  Created by Shen Lu on 10/8/15.
//  Copyright © 2015 Shen Lu. All rights reserved.
//

import Cocoa


class CustomInfoViewController: NSViewController, DetailContentViewProtocol {

    var stats: [String] = ["Base HP", "Base Str", "Base Skill", "Base Speed", "Base Def", "Base Res", "Base Luck", "Base Con", "HP Growth", "Str Growth", "Skill Growth", "Speed Growth", "Def Growth", "Res Growth", "Luck Growth", "Class"]
    
    var indexPaths: [String:Bool] = Dictionary()
    var edited: Bool?
    var playableCharacterArray: [FECharacter] = Array()
    
    func getCharacterData() -> [FECharacterData] {
        if edited == false {
            return [FECharacterData]()
        }
        modifyBaseStats(false)
        return Array(characterData.values)
    }
    
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var browserView: NSBrowser!
    func getSetStat(name: String, _ statIndex: Int, _ intValue: Int8?, _ uIntValue: UInt8? ) -> (Int8?, UInt8?) {
        let setMode = intValue != nil || uIntValue != nil
        switch  statIndex {
        case 0:
            if setMode {
                characterData[name]!.baseHP = intValue!
            }
            return (characterData[name]!.baseHP, nil)
        case 1:
            if setMode {
                characterData[name]!.baseStr = intValue!
            }
            return (characterData[name]!.baseStr, nil)
        case 2:
            if setMode {
                characterData[name]!.baseSkl = intValue!
            }
            return (characterData[name]!.baseSkl, nil)
        case 3:
            if setMode {
                characterData[name]!.baseSpd = intValue!
            }
            return (characterData[name]!.baseSpd, nil)
        case 4:
            if setMode {
                characterData[name]!.baseDef = intValue!
            }
            return (characterData[name]!.baseDef, nil)
        case 5:
            if setMode {
                characterData[name]!.baseRes = intValue!
            }
            return (characterData[name]!.baseRes, nil)
        case 6:
            if setMode {
                characterData[name]!.baseLck = intValue!
            }
            return (characterData[name]!.baseLck, nil)
        case 7:
            if setMode {
                characterData[name]!.baseCon = intValue!
            }
            return (characterData[name]!.baseCon, nil)
        case 8:
            if setMode {
                characterData[name]!.hpGrowth = uIntValue!
            }
            return (nil, characterData[name]!.hpGrowth)
        case 9:
            if setMode {
                characterData[name]!.strGrowth = uIntValue!
            }
            return (nil, characterData[name]!.strGrowth)
        case 10:
            if setMode {
                characterData[name]!.sklGrowth = uIntValue!
            }
            return (nil, characterData[name]!.sklGrowth)
        case 11:
            if setMode {
                characterData[name]!.spdGrowth = uIntValue!
            }
            return (nil, characterData[name]!.spdGrowth)
        case 12:
            if setMode {
                characterData[name]!.defGrowth = uIntValue!
            }
            return (nil, characterData[name]!.defGrowth)
        case 13:
            if setMode {
                characterData[name]!.resGrowth = uIntValue!
            }
            return (nil, characterData[name]!.resGrowth)
        case 14:
            if setMode {
                characterData[name]!.lckGrowth = uIntValue!
            }
            return (nil, characterData[name]!.lckGrowth)
        default:
            break
        }
        return (nil,nil)
        
    }
    
    var characters: [GenericFECharacterClass] = Array()
    var classNameMap : [String:UInt8] = Dictionary()
    var classIdMap : [UInt8:String] = Dictionary()
    
    var gameController: GameController?
    
    var characterData: [String: FECharacterData] = Dictionary()
    var currentCharacter: String?
    var currentStat: Int?
    var delegate : DetailContentViewDelegate?
    func modifyBaseStats(add: Bool) {
        modifyBaseStats(add, name: nil)
    }
    
    func modifyBaseStats(add: Bool, name: String?) {
        var mod: Int8 = 1
        if !add {
            mod = -1
        }
        for (c,_) in characterData {
            if name != nil && c != name {
                continue
            }
            let cName = self.classIdMap[characterData[c]!.classId]
            characterData[c]?.baseHP += (baseStats[cName!]![0] * mod)
            characterData[c]?.baseStr += (baseStats[cName!]![1] * mod)
            characterData[c]?.baseSkl += (baseStats[cName!]![2] * mod)
            characterData[c]?.baseSpd += (baseStats[cName!]![3] * mod)
            characterData[c]?.baseDef += (baseStats[cName!]![4] * mod)
            characterData[c]?.baseRes += (baseStats[cName!]![5] * mod)
            characterData[c]?.baseLck += (baseStats[cName!]![6] * mod)
            characterData[c]?.baseCon += (baseStats[cName!]![7] * mod)
        }
    }
    
    func loadGameData() {
        if gameController == nil || characterData.count > 0 {
            return
        }
        var characterD = gameController!.readCharacterData()
        var chapterData = gameController!.readChapterData(characterD)

        for c in characterD {
            var m = false
            for ch in characters {
                if ch.characterID == c.characterId  {
                    print("ID: \(ch.characterID), Name: \(ch.characterName) \(c.nameIndex)")
                    characterData[ch.characterName] = c
                    if chapterData[ch.characterID] != nil {
                        for chapt in chapterData[ch.characterID]! {
                            print("Adding Chapter data for \(ch.characterName)")
                            characterData[ch.characterName]?.chapterData.append(chapt)
                        }
                    } else {
                        print("No chapter data for \(ch.characterName)...")
                    }
                    m = true
                }
            }
            if m == false {
                print("DID NOT FIND \(c.characterId)) \(c.nameIndex)")
            }
        }
        
       modifyBaseStats(true)
    }
    
    
    override func loadView() {
        print("View Will Load???")
        let fe6 = FE6()
        playableCharacterArray = FE6.playableCharacterArray
        
        playableCharacterArray.sortInPlace{(c1:FECharacter, c2:FECharacter) -> Bool in
            c1.displayName < c2.displayName
        }
        let classes =  fe6.eligibleClasses()
        for c in classes {
            classNameMap[c.displayName] = c.classID
            classIdMap[c.classID] = c.displayName
        }
        for c in playableCharacterArray {
            let cc = GenericFECharacterClass(characterName: c.displayName, characterID: c.characterID, classID: 0, className: "")
            characters.append(cc)
        }
        // TODO: Make sure stuff is loaded if user clicks custom before clicking the game.
        loadGameData()

        let nib : NSNib? = NSNib.init(nibNamed: "CustomInfoViewController", bundle: nil)
        if (nib != nil) {
            var topLevelObjects: NSArray?
            nib!.instantiateWithOwner(self, topLevelObjects: &topLevelObjects)
            
            for object: AnyObject in topLevelObjects! {
                
                if let obj = object as? NSView {
                    self.view = obj
                    break
                }
            }
            
            self.view.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        print("View Did Load")
        browserView.delegate = self
        descriptionLabel.stringValue = "Applies a random delta between 0 and the value specified to every growth area for every character. For example, if the delta value is 20, then every growth rate can move in either direction by 20."
        
        

    }
    
    func selectedClass(sender: NSMenuItem?) {
        var cls = sender!.title
        let parent = browserView.selectedRowInColumn(0)
        let name = playableCharacterArray[parent].displayName
        
        modifyBaseStats(false, name: name)
        characterData[name]!.classId = classNameMap[cls]!
        
        modifyBaseStats(true, name: name)
        if baseStats[cls]![baseStats[cls]!.count - 2] == 0 {
            characterData[name]!.swordLevel = 0xFB
            characterData[name]!.axeLevel = 0xFB
            characterData[name]!.spearLevel = 0xFB
            characterData[name]!.bowLevel = 0xFB
            
            characterData[name]!.lightLevel = 0x00
            characterData[name]!.darkLevel = 0x00
            characterData[name]!.staffLevel = 0x00
            characterData[name]!.animaLevel = 0x00
            
            characterData[name]!.staffLevel = 0x00

        } else {
            characterData[name]!.swordLevel = 0x00
            characterData[name]!.axeLevel = 0x00
            characterData[name]!.spearLevel = 0x00
            characterData[name]!.bowLevel = 0x00
            
            characterData[name]!.lightLevel = 0xFB
            characterData[name]!.darkLevel = 0xFB
            characterData[name]!.staffLevel = 0xFB
            characterData[name]!.animaLevel = 0xFB
        }

        let item4: UInt8 = UInt8(baseStats[cls]![baseStats[cls]!.count - 1])
        print(characterData[name]!.chapterData)
        for cd in 0..<characterData[name]!.chapterData.count {
            characterData[name]!.chapterData[cd].classID = classNameMap[cls]!
            characterData[name]!.chapterData[cd].modified = true
            print("Editing Chapter Data for \(name), \(characterData[name]!.chapterData) ")
            if characterData[name]!.chapterData[cd].item2ID == 0 {
                print("Item2 Empty")
                characterData[name]!.chapterData[cd].item2ID = item4
                
            } else if characterData[name]!.chapterData[cd].item3ID == 0 {
                print("Item 3 Empty")
                characterData[name]!.chapterData[cd].item3ID = item4
                
            } else {
                print("Item 4 is where it's at.")
                characterData[name]!.chapterData[cd].item4ID = item4
            }

        }
        
        browserView.reloadColumn(2)
        
    }
    
    func editedCell(not: NSNotification) {
        var textView: NSTextView =  not.object as! NSTextView
        let stat = browserView.selectedRowInColumn(1)
        print("New Value: \(textView.string)")
        let parent = browserView.selectedRowInColumn(0)
        let name = playableCharacterArray[parent].displayName
        print("EditCell: name=\(name), stat=\(stat)")
        let uIntValue = UInt8(textView.string!)
        let intValue = Int8(textView.string!)
        if uIntValue == nil && intValue == nil {
            return
        }
        edited = true
        print(getSetStat(name, stat, intValue, uIntValue))
        
        dispatch_async(dispatch_get_main_queue(),{
        
               // self.browserView.selectRow(stat + 1, inColumn: 1)
            
        })

    }

    
    
    
    static func descriptionString() -> String {
            return "Custom."
    }
}



extension CustomInfoViewController: NSBrowserDelegate {
    
    func browser(sender: NSBrowser, numberOfRowsInColumn column: Int) -> Int {
        print("nRowsInColumn number: \(column)")
        if column == 0 {
            return playableCharacterArray.count
        }
        if column == 1 {
            return self.stats.count
        }
        if column == 2 {
            return 1
        }
        return 0
    }
    

    
    
    func browser(sender: NSBrowser, willDisplayCell cell: AnyObject, atRow row: Int, column: Int) {
        //var indexPath = sender.indexPathForColumn(column).indexPathByAddingIndex(row)
        var c = cell as! NSCell
        
        print("Row \(row), column \(column)")

        if column == 0 {
            c.stringValue = playableCharacterArray[row].displayName
        } else if column == 1 {
            let parent = sender.selectedRowInColumn(0)
            //print(parent)
            let name = playableCharacterArray[parent].displayName
           // print(self.characterData[name])
            c.stringValue = self.stats[row]
            
        } else if column == 2 {
            
            let stat = sender.selectedRowInColumn(1)
            let parent = sender.selectedRowInColumn(0)
            let name = playableCharacterArray[parent].displayName
            let path = name + String(stat)

            if stat == stats.count - 1 {
                if c.menu == nil {
                    c.menu = NSMenu()
                    for cl in classNameMap.keys {
                        c.menu!.addItem(NSMenuItem(title: cl, action: #selector(selectedClass(_:)), keyEquivalent: ""))
                    }
                }
                c.stringValue = classIdMap[characterData[name]!.classId]!
            } else {
                let (sInt, uInt) = getSetStat(name, stat, nil,nil)
                if sInt != nil {
                    
                    c.stringValue = String(sInt!)
                } else if uInt != nil {
                    c.stringValue = String(uInt!)
                } else {
                    c.stringValue = ""
                }
                c.editable = true
                if indexPaths[path] == nil {
                    print("Adding Notification")
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(editedCell(_:)), name:"NSTextDidEndEditingNotification", object: c.controlView)
                }

            }
            

            indexPaths[path] = true

            dispatch_async(dispatch_get_main_queue(),{
                    //c.controlView?.window?.makeFirstResponder(c.controlView)
            })
            
        }
    }
    
}

var baseStats: [String: [Int8]] = ["Armor Knight" : [17,5,2,0,9,0,0,13,0,0x10],
                                   "Armor Knight (F)" : [17,5,2,0,9,0,0,13,0,0x10],
                                   "Archer" : [18,4,3,3,3,0,0,6,0,0x27],
                                   "Archer (F)" : [18,4,3,3,3,0,0,6,0,0x27],
                                   "Myrmidon" : [16,4,9,9,2,0,0,8,0,0x5],
                                   "Myrmidon (F)" : [16,4,9,9,2,0,0,8,0,0x5],
                                   "Bandit" : [20,5,1,5,3,0,0,12,0,0x1B],
                                   "Pirate" : [19,4,2,6,3,0,0,10,0,0x1B],
                                   "Mercenary" : [18,4,8,8,4,0,0,9,0,0x1],
                                   "Pegasus Knight" : [14,4,5,5,3,2,0,5,0,0x10],
                                   "Wyvern Rider" : [20,7,3,5,8,0,0,10,0,0x10],
                                   "Wyvern Rider (F)" : [20,7,3,5,8,0,0,10,0,0x10],
                                   "Cleric" : [16,1,2,2,0,6,0,4,1,0x43],
                                   "Mage" : [16,1,2,3,3,3,0,6,1,0x33],
                                   "Mage (F)" : [16,1,2,3,3,3,0,6,1,0x33],
                                   "Shaman" : [16,2,1,2,2,4,0,5,1,0x3F],
                                   "Shaman (F)" : [16,2,1,2,2,4,0,5,1,0x3F],
                                   "Monk" : [18,1,1,2,1,5,0,6,1,0x3B],
                                   "Soldier" : [20,3,0,1,0,0,0,5,0,0x10],
                                   "Cavalier" : [20,5,2,5,6,0,0,9,0,0x1],
                                   "Troubadour" : [15,1,1,3,2,5,0,5,1,0x43],
                                   "Bard" : [14,1,2,7,0,1,0,4,0,0x5D],
                                   "Dancer" : [14,1,2,7,0,1,0,4,0,0x5D],
                                   "Lord" : [18,3,3,4,5,0,0,6,0,0xB],
                                   "Thief" : [16,3,1,9,0,6,2,5,0,0x1],
                                   "Thief (F)" : [16,3,1,9,0,6,2,5,0,0x1],
                                   "Priest" : [18,1,1,2,1,5,0,5,1,0x43],
                                   "Nomad" : [16,5,4,5,4,0,0,7,0,0x27],
                                   "Nomad (F)" : [16,5,4,5,4,0,0,7,0,0x27],
                                   "General" : [21,8,4,3,13,3,0,15,0,0x12],
                                   "General (F)" : [21,8,4,3,13,3,0,15,0,0x12],
                                   "Sniper" : [21,7,6,5,5,2,0,8,0,0x29],
                                   "Sniper (F)" : [21,7,6,5,5,2,0,8,0,0x29],
                                   "Nomad Trooper" : [21,7,6,7,6,3,0,8,0,0x2B],
                                   "Nomad Trooper (F)" : [21,7,6,7,6,3,0,8,0,0x2B],
                                   "Bishop" : [21,4,4,4,3,8,0,6,1,0x3C],
                                   "Bishop (F)" : [21,4,4,4,3,8,0,6,1,0x3C],
                                   "Druid" : [19,6,3,4,4,6,0,6,1,0x3F],
                                   "Druid (F)" : [19,6,3,4,4,6,0,6,1,0x3F],
                                   "Master Lord" : [22,5,6,6,7,5,0,8,0,0x9],
                                   "Berserker" : [24,7,6,7,6,0,0,13,0,0x23],
                                   "Swordmaster" : [21,6,11,10,5,2,0,9,0,0xE],
                                   "Swordmaster (F)" : [21,6,11,10,5,2,0,9,0,0xE],
                                   "Hero" : [22,6,9,10,8,2,0,10,0,0x4],
                                   "Hero (F)" : [22,6,9,10,8,2,0,10,0,0x4],
                                   "Sage" : [20,5,4,4,5,5,0,7,1,0x36],
                                   "Sage (F)" : [20,5,4,4,5,5,0,7,1,0x36],
                                   "Falcoknight" : [20,6,7,7,5,4,0,6,0,0x12],
                                   "Wyvern Lord" : [25,9,5,7,10,1,0,11,0,0x12],
                                   "Wyvern Lord (F)" : [25,9,5,7,10,1,0,11,0,0x12],
                                   "Valkyrie" : [19,4,3,5,4,8,0,8,1,0x36],
                                   "Manakete" : [20,0,0,2,1,1,0,5,0,0x53],
                                   "Manakete (F)" : [12,0,0,2,1,1,0,1,0,0x53],
                                   "Paladin" : [23,7,4,7,8,3,0,11,0,0x4],
                                   "Fighter" : [20,5,2,4,2,0,5,0,11,0,0x1B],
                                   "Warrior" : [28,8,5,6,5,0,6,0,13,0,0x7F]]
