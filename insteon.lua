-- General Controller/Responder for Myo Armband Controller --
-- version 1.00 - 2014-10-27 --
-- author: Jim Gale (twitter @jimgale) --
-- Copyright (c) 2014 Jim Gale --
-- license: MIT (http://opensource.org/licenses/MIT) (nice open license, even for selling) --
-- (Please let me know if you modify/reuse, so I can see what comes from this, and fix/improve required parts of this script if needed) --

scriptId = 'com.jimgale.scripts.insteon'

-- uses myocontroller.lua from (source) --
require "myocontroller"

function setupINSTEON() 
    --- INSTEON ------------------------------------------------------------------
    local responder = MyoResponder.new("insteon")
    local insteonDevice = "1A.CD.53"
    
    responder.activateWhen = WindowTitleAction(MatchType.Equals, "INSTEON")
    
    responder.unlockLockTimeout("thumbToPinky", "thumbToPinky", 5000)
    
    -- fingersSpread to turn ON, fist to turn OFF --
    responder.onPoseStartStop("fingersSpread", insteon.sendAction(insteonDevice, "ON"))
    responder.onPoseStartStop("fist", insteon.sendAction(insteonDevice, "OFF"))

    -- waveOut to BRIGHTEN, waveIn to DIM --
    responder.onPoseStartStop("waveOut", insteon.sendAction(insteonDevice, "UP"), insteon.sendAction(insteonDevice, "STOP"))
    responder.onPoseStartStop("waveIn", insteon.sendAction(insteonDevice, "DOWN"), insteon.sendAction(insteonDevice, "STOP"))
    
    -- fingersSpread, then turn the lights up and down based on the angle --
    --responder.onPoseTurnLeftRightStable("fingersSpread", insteon.sendAction(insteonDeviddce, "DOWN"), insteon.sendAction(insteonDevice, "UP"), insteon.sendAction(insteonDevice, "STOP"), 500, 0.03)

    controller.Add(responder)
end

-- Insteon Controller - provides sendAction for devices --
-- currently works with a textual interface to the PLM (hacky, but doesn't add LUA dependencies) --
-- todo: take additional socket dependency and connect to HUB without textual interface --
Insteon = {}
function Insteon.new()
    local self = {}
    
    -- send an INSTEON command by typing the command into a textual command window which sends PLM commands --
    self.send = function(address, command, angle)
        if angle then
          -- convert the arm's angle to a 0(off) to 255(full on) byte to allow the arm's angle to determine the light level --
          local byte = 255/90 * (math.max(math.min(angle, 45),-45) + 45) 
          environment.type(address .. " ON " .. math.floor(byte));
        else
          environment.type(address .. " " .. command)
        end
    end
    
    -- the Action version of send - also receives the Yaw as an angle --
    self.sendAction = function(address, command)
        return 
          function(angle) 
            self.send(address, command, angle) 
          end
    end
    
    return self
end