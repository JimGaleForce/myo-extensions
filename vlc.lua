scriptId = 'com.jimgale.scripts.vlc'

require "myocontroller"

function setupVLC() -- source of keyboard shortcuts: http://www.shortcutworld.com/en/win/VLC-Media-Player.html --
    local responder = MyoResponder.new("vlc-player")
    responder.activateWhen = WindowTitleAction(MatchType.Contains, "VLC media player")
    
    -- pause/play: fingersSpread --
    responder.onPoseStartStop("fingersSpread", environment.pressAction("space"))
    
    -- forward 10 seconds --
    --responder.onPoseStartStop("waveRight", environment.pressAction("right_arrow", "control"))
    
    -- back 10 seconds --
    --responder.onPoseStartStop("waveLeft", environment.pressAction("left_arrow", "control"))
    
    -- volume: fist-left turns volume down, first-right up. Waits 1000ms between changing volume, with a sensitivity of 0.05 (about 33 degrees)
    responder.onPoseTurnLeftRightStable("fist", environment.pressAction("down_arrow", "control"), environment.pressAction("up_arrow", "control"), nil, 1000, 0.05)
    controller.Add(responder)
end

setupVLC()