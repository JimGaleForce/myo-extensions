-- General Controller/Responder for Myo Armband Controller --
-- version 1.00 - 2014-10-27 --
-- author: Jim Gale (twitter @jimgale) --
-- Copyright (c) 2014 Jim Gale --
-- license: MIT (http://opensource.org/licenses/MIT) (nice open license, even for selling) --
-- (Please let me know if you modify/reuse, so I can see what comes from this, and fix/improve required parts of this script if needed) --

scriptId = 'com.jimgale.scripts.controller'

------------------------------------------------------------------------------------------------------------------------------------------------------

-- MyoResponder - handles specific responses to different applications --
-- Controllers can have multiple responders --
MyoResponder = {}
function MyoResponder.new(name) 
    local self = {}
    
    self.name = name                        -- name: for debugging --
    self.debug = false                      -- debug: allows debugging (reporting specific actions, poses, etc) --
    self.StayUnlockedDuringPoses = true     -- StayUnlockedDuringPoses: (default for all responders) false=timeout, only set to false when the unlockLockTimeout() function is used --
    self.inPose = false                     -- inPose: are we currently in a pose (not at rest) --
    self.poseKeepsUnlock = false            -- poseKeepsUnlock: sets from StayUnlockedDuringPoses in unlockLockTimeout() --
    self.unlockPose = ""                    -- unlockPose: the pose to unlock this responder --
    self.lockPose = ""                      -- lockPose: the pose to lock this responder --
    self.unlockTimeout = 0                  -- unlockTimeout: timeout (if any) to auto-lock this responder --
    self.isLocked = false                   -- isLocked: true=this responder is locked and not recognizing poses --
    self.lastUnlockTimeStamp = 0            -- lastUnlockTimeStamp: internal to allow timeouts --
    self.isActive = false                   -- isActive: true=this responder is currently active (when window title matches OR has no activateWhen condition (i.e. global on)) 
    
    -- sends a message to the myo debug console if this responder's debug is true. todo: become controller specific --
    self.debugMsg = function(msg)
        if self.debug then
          myo.debug(self.name..":"..msg)
        end
    end
    
    -- manages poses for onPoseStartStop(): pose to recognize, onAction = when pose started, offAction(optional) = when pose relaxed --
    self.onPoses = {}
    self.onPoseStartStop = function(pose, onAction, offAction)
        if not offAction then
            offAction = nil
        end
      
        local poseSet = {pose, onAction, offAction}
        table.insert(self.onPoses, poseSet)
    end
    
    -- manages poses for duringPose(): pose to recognize, action to implement per interval (default every 50ms) --
    self.duringPoses = {}
    self.duringPose = function(pose, action, interval)
        if not interval then
            interval = 50
        end
        
        local poseSet = {pose, false, action, interval, 0}
        table.insert(self.duringPoses, poseSet)
    end
    self.DuringPose = {Pose = 1, IsActive = 2, Action = 3, Interval = 4, LastActiveTimeStamp = 5}
    
    -- specifies the unlockPose and lockPose with optional unlockTimeout --
    self.unlockLockTimeout = function(unlockPose, lockPose, unlockTimeout)
        self.unlockPose = unlockPose
        self.poseKeepsUnlock = self.StayUnlockedDuringPoses
        
        --set lock pose to unlock pose if not specified
        if lockPose == nil then self.lockPose = unlockPose else self.lockPose = lockPose end
        
        --set unlock timeout to 0 (no timeout) if not specified
        if lockPose == nil then self.unlockTimeout = 0 else self.unlockTimeout = unlockTimeout end
        
        --set locked only if there is a pose to lock/unlock
        self.isLocked = self.unlock ~= nil
        
        self.debugMsg("locked=" .. tostring(self.isLocked))
    end
    
    -- manages the onPoseTurnLeftRightStable(): pose to recognize, leftAction (action to take when rotating left per repeatActionInterval),
    --    rightAction (action to take when rotating right per repeatActionInterval), stableAction (action to take when not rotating left or right),
    --    repeatActionInterval (how often to execute the actions, in ms), delta (how sensitive to recognize a rotation (0.02 is sensitive, 0.07 is far less sensitive)
    self.turnPoses = {}
    self.onPoseTurnLeftRightStable = function(pose, leftAction, rightAction, stableAction, repeatActionInterval, delta)
        local poseTurn = {pose, false, leftAction, rightAction, stableAction, repeatActionInterval, delta, 0, 0}
        table.insert(self.turnPoses, poseTurn)
    end
    self.TurnPose = {Pose = 1, IsActive = 2, LeftAction = 3, RightAction = 4, StableAction = 5, RepeatActionInterval = 6, Delta = 7, OriginalYaw = 8, LastActiveTimeStamp = 9}
	
	  return self
end

-- Environment - handles global/external items beyond specific controllers --
Environment = {}
function Environment.new() 
    local self = {}
    
    -- called when the foreground window changes --
    self.onForegroundWindowChange = function(app, title)
        environment.app = app
        environment.title = title
        environment.activeApp = ""

        -- currently only Windows --
        if platform ~= "Windows" then
            return false 
        end
      
        -- check each responder to active or deactivate --
        local foundActive = false
        for i=1, #controller.responders, 1 do
            local responder = controller.responders[i]
            if responder.activateWhen then
               local wasActive = responder.isActive
               responder.isActive = responder.activateWhen()
               if responder.isActive then
                   environment.activeApp = title
                   foundActive = true
                   responder.debugMsg("activated")
               elseif wasActive then
                   responder.debugMsg("deactivated")
               end
            else
               responder.isActive = true
               environment.activeApp = title
               foundActive = true
            end
        end

        return foundActive
    end
    
    -- called when the active script changes --
    self.onActiveChange = function(isActive)
    end
    
    -- sends a keypress --
    self.press = function(key, modifier)
        if modifier then 
            myo.keyboard(key, "press", modifier)
        else
            myo.keyboard(key, "press")
        end
    end
    
    -- 'action' wrapper for the press() function --
    self.pressAction = function(key, modifier)
        return
          function()
              self.press(key, modifier)
          end
    end
    
    -- types the text (one keystroke at a time) --
    self.type = function(text) 
        for i=1, string.len(text), 1 do
            local key = string.lower(string.sub(text, i, i))
            
            if key == " " then key = "space" end
            if key == "." then key = "period" end
            
            myo.keyboard(key, "press")
        end
        
        -- with a return --
        myo.keyboard("return", "press")
    end
    
    -- called per myo Periodic iteration --
    self.onPeriodic = function()
    end
    
    return self
end

-- Controller - holds responders, handles individual controllers --
-- currently only one controller exists in this implemention --
-- todo: add a Manager and allow multiple Controllers to handle more than one Myo or other device --
Controller = {}
function Controller.new() 
    local self = {}
    
    self.responders = {}
    
    self.debugAction = function(msg)
        return 
          function(parm) 
            if parm ~= nil then
              myo.debug(msg..":parm="..tostring(parm))
            else
              myo.debug(msg)
            end
          end
    end
    
    self.arm = ""                           -- arm: current arm wearing the controller --
    self.otherArm = ""                      -- otherArm: alternate arm name in order to invert wave poses to allow waveLeft and waveRight virtual poses --
    
    -- called when the active script changes --
    self.onActiveChange = function(isActive)
      
        -- returns Titlecase (first character uppercase, rest lowercase)
        local function tchelper(first, rest)
            return first:upper()..rest:lower()
        end
        
        self.arm = string.gsub(myo.getArm(), "(%a)([%w_']*)", tchelper) -- make it Titlecase
        if self.arm == "Left" then
            self.otherArm = "Right"
        elseif self.arm == "Right" then
            self.otherArm = "Left"
        end
    end
    
    -- allowed poses and virtual poses --
    self.Poses = {fingersSpread = "fingersSpread", fist = "fist", thumbToPinky = "thumbToPinky", waveOut = "waveOut", waveIn = "waveIn", rest = "rest", waveLeft = "waveLeft", waveRight = "waveRight"} 
    
    -- does-nothing function for testing (called as controller.nothingAction()) --
    self.nothingAction = function()
        return 
          function() 
            return ""
          end
    end
    
    -- add a responder to this controller --
    self.Add = function(responder)
        if responder.activateWhen == nil then
            responder.isActive = true
        end
        
        table.insert(self.responders, responder)
    end
    
    -- lock a responder for this controller --
    self.lockResponder = function(responder)
        responder.isLocked = true
        myo.vibrate("short")
        myo.vibrate("short")
        responder.debugMsg("isLocked")
    end
    
    -- unlock a responder for this controller --
    self.unlockResponder = function(responder)
        responder.isLocked = false
        myo.vibrate("short")
        responder.debugMsg("isUnlocked")
        responder.lastUnlockTimeStamp =  myo.getTimeMilliseconds()
    end
    
    -- check if the actual pose matches the expected one (includes virtualPoses) --
    self.poseMatches = function(actual, expected)
        if not expected or string.len(expected) == 0 then
            return false
        end
        
        local index = string.find(actual, expected)
        return index ~= nil and index > 0
    end
    
    -- change a real pose into a combination of real pose and virtual pose for later recogniztion (i.e. waveIn (on left arm) to waveIn:waveRight)
    self.addDirectional = function(pose)
        if string.find(pose, "wave") == 1 and self.arm and self.arm ~= "unknown" then
            local directionalPose = ""
            if pose == self.Poses.waveOut then
                directionalPose = ":wave" .. self.arm
            elseif pose == self.Poses.waveIn then
                directionalPose = ":wave" .. self.otherArm
            end
            pose = pose .. directionalPose 
        end
        
        return pose
    end
    
    -- called when a pose turns 'on' or 'off' (edge) --
    self.onPoseEdge = function(pose, edge)
       --suffix the pose with the directional version--
       pose = self.addDirectional(pose)
      
       for r=1, #controller.responders, 1 do
          local responder = controller.responders[r]
          
          if responder.isActive then
            if not self.poseMatches(pose, self.Poses.rest) then
                responder.inPose = edge == "on"
            end
            
            -- check to lock/unlock the responder --
            if responder.isLocked and edge == "on" and self.poseMatches(pose, responder.unlockPose) then
                self.unlockResponder(responder)
            elseif not responder.isLocked and edge == "on" and self.poseMatches(pose, responder.lockPose) then
                self.lockResponder(responder)
            end
            
            if not responder.isLocked then
              -- handle all onPoses --
              for p=1, #responder.onPoses, 1 do
                  if self.poseMatches(pose, responder.onPoses[p][1]) then
                     local poseIndex = -1
                     
                     if edge == "on" then poseIndex = 2
                     elseif edge == "off" then poseIndex = 3
                     end
                   
                     responder.debugMsg(pose..":"..edge..":index="..poseIndex)
                     
                     if poseIndex > -1 then
                         local poseAction = responder.onPoses[p][poseIndex]
                         responder.debugMsg(pose..":"..edge..":action="..tostring(poseAction))
                         if poseAction then
                             responder.debugMsg(pose..":"..edge..":activated")
                             poseAction()
                         end
                     end
                  end
              end
              
              -- handle all duringPoses --
              for p=1, #responder.duringPoses, 1 do
                  if self.poseMatches(pose, responder.duringPoses[p][1]) then
                      responder.debugMsg(pose..":"..edge..":during")
                      responder.duringPoses[p][2] = responder.inPose
                  end
              end
              
              -- handle all turnPoses --
              for p=1, #responder.turnPoses, 1 do
                  if self.poseMatches(pose, responder.turnPoses[p][responder.TurnPose.Pose]) then
                     responder.debugMsg(pose..":"..edge..":turnStart")
                     responder.turnPoses[p][responder.TurnPose.IsActive] = responder.inPose
                     responder.turnPoses[p][responder.TurnPose.OriginalYaw] = myo.getYaw() --start yaw
                  end
              end
              
            end
        end
      end
    end
    
    -- called for each myo Periodic interation --
    self.onPeriodic = function()
        local now = myo.getTimeMilliseconds()
        
        for r=1, #controller.responders, 1 do
            local responder = controller.responders[r]
            
            -- check to timeout the responder --
            if not responder.isLocked and responder.unlockTimeout > 0 then
                if responder.poseKeepsUnlock and responder.inPose then
                    responder.lastUnlockTimeStamp = now
                end
                
                if now - responder.lastUnlockTimeStamp >= responder.unlockTimeout then
                    self.lockResponder(responder)
                end
            end

            if responder.isActive and not responder.isLocked then 
                -- handle all duringPoses --
                for p=1, #responder.duringPoses, 1 do
                  local poseSet = responder.duringPoses[p]
                  if poseSet[responder.DuringPose.IsActive] then
                      local latest = poseSet[responder.DuringPose.LastActiveTimeStamp] + poseSet[responder.DuringPose.Interval]
                      if latest < now then
                          poseSet[responder.DuringPose.LastActiveTimeStamp] = now
                          poseSet[responder.DuringPose.Action]()
                      end
                  end
                end
            
                -- handle all turnPoses --
                for p=1, #responder.turnPoses, 1 do
                      local turnPose = responder.turnPoses[p] 
                      if turnPose[responder.TurnPose.IsActive] then
                          
                          --check for interval
                          local isValidInterval = turnPose[responder.TurnPose.RepeatActionInterval] == 0 
                          
                          if not isValidInterval then
                              local deltaDifference = now - turnPose[responder.TurnPose.LastActiveTimeStamp]
                              isValidInterval = deltaDifference >= turnPose[responder.TurnPose.RepeatActionInterval]
                          end
                        
                          if isValidInterval then
                              turnPose[responder.TurnPose.LastActiveTimeStamp] = now
                        
                              -- calculate the yaw difference between now (periodic) and when the pose began (onPoseEdge/OriginalYaw) --
                              local yawNow = myo.getYaw()
                              local yawStart = turnPose[responder.TurnPose.OriginalYaw]
                              local yawDiff = yawNow - yawStart
                              local yawTrip = turnPose[responder.TurnPose.Delta]
                              
                              local angle = math.deg(yawDiff) * 10 -- project that the hand is 10x turned more than the myo -- 
                              if yawDiff > yawTrip and turnPose[responder.TurnPose.LeftAction] ~= nil then
                                  turnPose[responder.TurnPose.LeftAction](angle)
                              elseif yawDiff < -yawTrip and turnPose[responder.TurnPose.RightAction] ~= nil then
                                  turnPose[responder.TurnPose.RightAction](angle)
                              elseif turnPose[responder.TurnPose.StableAction] ~= nil then
                                  turnPose[responder.TurnPose.StableAction](angle)
                              end
                          end
                      end
                  end
            end
        end
    end
    
    -- handle 'common' controllers so that each one doesn't have to be specified in detail --
    self.ResponderType = {Scroller = 1, Editor = 2}
    self.AddCommonResponder = function(responderType, name, matchType, title, speed)      
        local responder = MyoResponder.new(name)
        responder.activateWhen = WindowTitleAction(matchType, title)
        
        if responderType == self.ResponderType.Scroller then
            responder.duringPose("waveIn", environment.pressAction("down_arrow"), speed)
            responder.duringPose("waveOut", environment.pressAction("up_arrow"), speed)
        end
        
        if responderType == self.ResponderType.Editor then
            responder.onPoseTurnLeftRightStable(controller.Poses.fist, environment.pressAction("down_arrow", "control"), environment.pressAction("up_arrow", "control"), nil, speed, 0.02)
        end
        
        self.Add(responder)
        return responder
    end
	
	  return self
end

Manager = {}
function Manager.new() 
    local self = {}
    
    self.controllers = {}
    self.Add = function(controller)
        table.insert(self.controllers, controller)
    end
    
    self.debugAction = function(message)
        for c=1, #self.controllers, 1 do
            self.controllers[c].debugAction(message)
        end
    end
    
    self.onPoseEdge = function(pose, edge)
        for c=1, #self.controllers, 1 do
            self.controllers[c].onPoseEdge(pose, edge)
        end
    end
    
    self.onPeriodic = function()
        for c=1, #self.controllers, 1 do
            self.controllers[c].onPeriodic()
        end
    end
    
    self.onActiveChange = function()
        for c=1, #self.controllers, 1 do
            self.controllers[c].onActiveChange()
        end
    end
    
    return self
end
    
-------- Core Myo Functions --------

function onForegroundWindowChange(app, title)
    myo.debug(title)
    return environment.onForegroundWindowChange(app, title)
end

function onPoseEdge(pose, edge)
    manager.debugAction("pose")
    manager.onPoseEdge(pose, edge)
end

function onPeriodic()
    environment.onPeriodic()
    manager.onPeriodic()
end

function activeAppName()
    return environment.activeApp
end

function onActiveChange(isActive)
    environment.onActiveChange(isActive)
    manager.onActiveChange(isActive)
end

-------- Helper functions --------

-- 'action' wrapper for WindowTitle -- 
function WindowTitleAction(matchType, value)
    return 
      function() 
        return WindowTitle(matchType, value) 
      end
end

-- allows an Equals and Contains match for the window title and a value to test --
function WindowTitle(matchType, value) 
    local active = false
    
    if matchType == MatchType.Equals then
        active = string.match(environment.title, value)
    elseif matchType == MatchType.Contains then
        local index = string.find(environment.title, value)
        active = index ~= nil and index > 0
    end
    
    return active
end

MatchType = {Equals = 0, Contains = 1} 

-- must initialize these before calling setup() as LUA is one pass --
environment = Environment.new()
controller = Controller.new()
manager = Manager.new()
manager.Add(controller)

