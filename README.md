Manual base/growth/class assigner for FE6. Instead of randomizing, this allows fine tuning of stats and classes. 

I've bastardized Lushen's code to get this working in the short term -- my eventual goal would be to make it an option for his randomizer and get it merged upstream (which will require me to do some refactoring).

This was a quick and dirty implementation for fun. 

##TODO: 
1. Figure out the chapter data stuff. Some characters are not getting their classes properly changed (which I BELIEVE is determined in the chapter data section). I don't think I fully understand it.
2. Refactor to make the data-flow from viewcontroller ->  gamecontroller more like Lushen's code.
3. Add support for FE7/FE8. This is a big task, since Lushen's OS X client does not have randomization support for FE7/8 at all. That might be something I submit as a PR to his main branch in the short term.
4. Upgrade his swift 2.2->swift 3.
