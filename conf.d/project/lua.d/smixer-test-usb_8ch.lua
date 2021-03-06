--[[
  Copyright (C) 2016 "IoT.bzh"
  Author Fulup Ar Foll <fulup@iot.bzh>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.


  NOTE: strict mode: every global variables should be prefixed by '_'
--]]

-- Static variables should be prefixed with _
_EventHandle={}


-- make variable visible from ::OnExitError::
local error
local result


local printf = function(s,...)
    io.write(s:format(...))
    io.write("\n")
    return
end

-- Display receive arguments and echo them to caller
function _mixer_simple_test_ (source, args)
    do
 
    -- Mixer UID is used as API name

    -- ==================== Default rate ===========================

    local audio_params ={
        R48000 = { ["rate"] = 48000 },
        R44100 = { ["rate"] = 44100 },
        R8000  = { ["rate"] = 8000  },
    }  

    local volume_ramps = {
            {["uid"]="ramp-fast",   ["delay"]= 050, ["up"]=10,["down"]=3},
            {["uid"]="ramp-slow",   ["delay"]= 250, ["up"]=03,["down"]=1},
            {["uid"]="ramp-normal", ["delay"]= 100, ["up"]=06,["down"]=2},
    }

    -- ============================= Backend (Sound Cards) ===================  

    local snd_usb_8ch= {
        ["uid"]= "8CH-USB",
        ["path"]= "/dev/snd/by-id/usb-0d8c_USB_Sound_Device-00",
        ["params"] = audio_params.R48000,
        ["sink"] = {
            ["controls"]= {
                ["volume"] = {["name"]= "Speaker Playback Volume", ["value"]=80},
                ["mute"]   = {["name"]= "Speaker Playback Switch"},
            },
            ["channels"] = {
                {["uid"]= "front-right", ["port"]= 0},
                {["uid"]= "front-left" , ["port"]= 1},
                {["uid"]= "middle-right", ["port"]= 2},
                {["uid"]= "middle-left" , ["port"]= 3},
                {["uid"]= "back-right", ["port"]= 4},
                {["uid"]= "back-left" , ["port"]= 5},
                {["uid"]= "centre-left" , ["port"]= 6},
                {["uid"]= "centre-left" , ["port"]= 7},
            },
        },
        ["source"] = {
            ["controls"]= {
                ["volume"] = {["name"]= "Capture Volume"},
                ["mute"]   = {["name"]= "Capture Switch"},
            },
            ["channels"] = {
                {["uid"]= "mic-right", ["port"]= 0},
                {["uid"]= "mic-left" , ["port"]= 1},
            },
        }
    }

 
    -- ============================= Zones ===================    
    local zone_stereo={
        ["uid"]  = "full-stereo",
        ["sink"] = {
            {["target"]="front-right",["channel"]=0},
            {["target"]="front-left" ,["channel"]=1},
            {["target"]="middle-right",["channel"]=0},
            {["target"]="middle-left" ,["channel"]=1},
            {["target"]="back-right",["channel"]=0},
            {["target"]="back-left" ,["channel"]=1},
        }
    }

    local zone_front= {
        ["uid"]  = "front-seats",
        ["sink"] = {
            {["target"]="front-right",["channel"]=0},
            {["target"]="front-left" ,["channel"]=1},
        }
    }

    local zone_middle= {
        ["uid"]  = "middle-seats",
        ["sink"] = {
            {["target"]="middle-right",["channel"]=0},
            {["target"]="middle-left" ,["channel"]=1},
        }
    }

    local zone_back= {
        ["uid"]  = "back-seats",
        ["sink"] = {
            {["target"]="back-right",["channel"]=0},
            {["target"]="back-left" ,["channel"]=1},
        }
    }


    -- =================== Audio Streams ============================
    local stream_music= {
        ["uid"]  = "stream-multimedia",
        ["verb"] = "multimedia",
        ["zone"] = "full-stereo",
        ["volume"]= 80,
        ["mute"]  = false,
        ["params"] = audio_params.R48000,
    }
    
    local stream_navigation= {
        ["uid"]  = "stream-navigation",
        ["verb"] = "navigation",
        ["zone"] = "front-seats",
        ["volume"]= 80,
        ["mute"]  = false,
        ["params"] = audio_params.R48000,
    }
    
    local stream_emergency= {
        ["uid"]   = "stream-emergency",
        ["verb"] = "emergency",
        ["zone"]  = "front-seats",
        ["volume"]= 80,
        ["mute"]  = false,
        ["params"] = audio_params.R48000,
    }
            
    -- Force Pulse to attach a well known Loop subdev to get a fix Alsa cardid 
    local stream_pulse= {
        ["uid"]   = "stream-pulseaudio",
        ["verb"] = "legacy",
        ["zone"]  = "back-seats",
        ["source"]= "loop-legacy",
        ["volume"]= 80,
        ["mute"]  = false,
        ["params"] = audio_params.R48000,
    }
    
    --- ================ Create Mixer =========================
    local MyTestHal= {
        ["uid"]      = "HAL-LUA-8CH-USB",
        ["prefix"]   = "default",
        ["ramps"]    = volume_ramps,
        ["playbacks"]= {snd_usb_8ch },
        ["captures"] = {snd_usb_8ch },
        ["zones"]    = {zone_stereo, zone_front, zone_back, zone_middle},
        ["streams"]  = {stream_pulse, stream_music, stream_navigation, stream_emergency },
    }

    error,result= AFB:servsync(source, "smixer", "attach", MyTestHal)
    if (error) then 
        AFB:error (source, "--InLua-- API smixer/attach fail error=%d %s", error, Dump_Table(result))
        goto OnErrorExit
    else
        AFB:notice (source, "--InLua-- smixer/attach done result=%s\n", Dump_Table(result))
    end
  
    -- ================== Happy End =============================
    AFB:notice (source, "--InLua-- Test success")
    return 0 end 

    -- ================= Unhappy End ============================
    ::OnErrorExit::
        local response=result["request"]
        printf ("--InLua-- ------------STATUS= %s --------------", response["status"])
        printf ("--InLua-- ++ INFO= %s", Dump_Table(response["info"]))
        printf ("--InLua-- ----------TEST %s-------------", response["status"])

        AFB:error (source, "--InLua-- Test Fail")
        return 1 -- unhappy end --
end 
