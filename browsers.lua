-- General Controller/Responder for Myo Armband Controller --
-- version 1.00 - 2014-10-27 --
-- author: Jim Gale (twitter @jimgale) --
-- Copyright (c) 2014 Jim Gale --
-- license: MIT (http://opensource.org/licenses/MIT) (nice open license, even for selling) --
-- (Please let me know if you modify/reuse, so I can see what comes from this, and fix/improve required parts of this script if needed) --

scriptId = 'com.jimgale.scripts.browsers'

-- uses myocontroller.lua from (source) --
require "myocontroller"

function setupBrowsersAndEditors()
    -- Facebook, Gmail, Bing, Google, any web page, etc (standard scrolling responder) --------------------------------------------------------------
    controller.AddCommonResponder(controller.ResponderType.Scroller, "chrome", MatchType.Contains, "Google Chrome")
    controller.AddCommonResponder(controller.ResponderType.Scroller, "internet explorer", MatchType.Contains, "Internet Explorer", 100)
    
    controller.AddCommonResponder(controller.ResponderType.Editor, "visual studio", MatchType.Contains, "Microsoft Visual Studio", 25)    
end

MatchType = {Equals = 0, Contains = 1} 

-- must initialize these before calling setup() as LUA is one pass --
controller = Controller.new()

setupBrowsersAndEditors()
