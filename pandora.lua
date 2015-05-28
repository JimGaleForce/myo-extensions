-- General Controller/Responder for Myo Armband Controller --
-- version 1.00 - 2014-10-27 --
-- author: Jim Gale (twitter @jimgale) --
-- Copyright (c) 2014 Jim Gale --
-- license: MIT (http://opensource.org/licenses/MIT) (nice open license, even for selling) --
-- (Please let me know if you modify/reuse, so I can see what comes from this, and fix/improve required parts of this script if needed) --

scriptId = 'com.jimgale.scripts.pandora'

-- uses myocontroller.lua from (source) --
require "myocontroller"

function setupPandora()
    
    --- Pandora WEB --------------------------------------------------------------
    local responder = MyoResponder.new("pandora-web")
    responder.activateWhen = WindowTitleAction(MatchType.Contains, "Pandora One")
    responder.onPoseStartStop("fingersSpread", environment.pressAction("space"))
    responder.onPoseStartStop("waveOut", environment.pressAction("right_arrow"))
    responder.onPoseStartStop("waveIn", environment.pressAction("left_arrow"))
    controller.Add(responder)
    
    --- Pandora DESKTOP --------------------------------------------------------------
    responder = MyoResponder.new("pandora-desktop")
    responder.activateWhen = WindowTitleAction(MatchType.Equals, "Pandora")
    
    -- pause/play: fingersSpread --
    responder.onPoseStartStop("fingersSpread", environment.pressAction("space"))
    
    -- next song: waveOut --
    responder.onPoseStartStop("waveRight", environment.pressAction("right_arrow"))
    
    -- prev song: waveIn (documented but doesn't actually work on desktop version) --
    responder.onPoseStartStop("waveLeft", environment.pressAction("left_arrow"))
    
    -- volume: fist-left turns volume down, first-right up. Waits 1000ms between changing volume, with a sensitivity of 0.05 (about 33 degrees)
    responder.onPoseTurnLeftRightStable("fist", environment.pressAction("down_arrow"), environment.pressAction("up_arrow"), nil, 1000, 0.05)
    controller.Add(responder)
end

MatchType = {Equals = 0, Contains = 1} 

-- must initialize these before calling setup() as LUA is one pass --
controller = Controller.new()

setupPandora()