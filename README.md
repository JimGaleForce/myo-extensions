# myo-extensions
Sample myo extensions using a near-object-oriented myocontroller and responders. 

Allows for easy control of the myo band including default handlers.
For example, this line tells the myo to recognize Google Chrome as a common scroller:
```lua   
     controller.AddCommonResponder(controller.ResponderType.Scroller, "chrome", MatchType.Contains, "Google Chrome")
```

this tells myo that Visual Studio is an editor:
```lua
    controller.AddCommonResponder(controller.ResponderType.Editor, "visual studio", MatchType.Contains, "Microsoft Visual Studio", 25) 
```

For manual control, these lines (for example) tell the myo band that Pandora (web) responds to three poses:
```lua
    --- Pandora WEB --------------------------------------------------------------
    local responder = MyoResponder.new("pandora-web")
    responder.activateWhen = WindowTitleAction(MatchType.Contains, "Pandora One")
    responder.onPoseStartStop("fingersSpread", environment.pressAction("space"))
    responder.onPoseStartStop("waveOut", environment.pressAction("right_arrow"))
    responder.onPoseStartStop("waveIn", environment.pressAction("left_arrow"))
    controller.Add(responder)
```
The myocontroller.lua handles all these so that you can add as many responders in as few lines of code and they all work at the same time.
