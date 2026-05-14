-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: SelfieOneClickModeData
-- Date: 2026-04-13
-- Desc: 一键模式数据管理
-- ---------------------------------------------------------------------------------
SelfieOneClickModeData = class("SelfieOneClickModeData")
local self = SelfieOneClickModeData

local tCamAniData = {}
local tBGMData = {}
local tBodyActionData = {}
local tFaceActionData = {}
local tVideoPrams = {}

SelfieOneClickModeData.bOpenOneMode = false     -- 是否为一键成片模式
SelfieOneClickModeData.bEnableAIGerate = true   -- 是否激活AI动捕生成
SelfieOneClickModeData.nCustomMotionType = nil

SelfieOneClickModeData.szBodyActionSprite = "UIAtlas2_Camera_Selfie_Action"
SelfieOneClickModeData.szFaceActionSprite = "UIAtlas2_Camera_Selfie_Emoji"

function SelfieOneClickModeData.Init()
    Event.Reg(self, "ON_ONE_CLICK_CHOOSE_CAM_ANI", function (bSeq, tCamAniData)
        self.SetCamAniData(bSeq, tCamAniData)
    end)
    
    
    Event.Reg(self, "ON_ONE_CLICK_CHOOSE_BGM", function (nBgmID, nStartTime, nEndTime, bCustom)
        self.SetBGMData(nBgmID, nStartTime, nEndTime, bCustom)
    end)
    
    
    Event.Reg(self, "ON_ONE_CLICK_CHOOSE_BODY_ACTION", function (bAIAct, szKey, szCustomName)
        self.SetBodyActionData(bAIAct, szKey, szCustomName)
    end)
    
    
    Event.Reg(self, "ON_ONE_CLICK_CHOOSE_FACE_ACTION", function (bAIAct, szKey, szCustomName)
        self.SetFaceActionData(bAIAct, szKey, szCustomName)
    end)
end

function SelfieOneClickModeData.UnInit()
    self.Clear()
    Event.UnRegAll(self)
end


function SelfieOneClickModeData.Clear()
    tCamAniData = {}
    tBGMData = {}
    tBodyActionData = {}
    tFaceActionData = {}
    tVideoPrams = {}
end

----------------------------- 运镜数据 -----------------------------

function SelfieOneClickModeData.SetCamAniData(bSeq, tData)
    tCamAniData = {
        bSeq = bSeq,
        tData = tData
    }
end

function SelfieOneClickModeData.GetCamAniData()
    return tCamAniData
end


----------------------------- BGM数据 -----------------------------

function SelfieOneClickModeData.SetBGMData(nBgmID, nStartTime, nEndTime, bCustom)
    tBGMData = {
        nBgmID = nBgmID,
        nStartTime = nStartTime,
        nEndTime = nEndTime,
        bCustom = bCustom
    }
end

function SelfieOneClickModeData.GetBGMData()
    return tCamAniData
end

----------------------------- 动作数据 -----------------------------

function SelfieOneClickModeData.SetBodyActionData(bAIAct, szKey, szCustomName)
    tBodyActionData = {
        bAIAct = bAIAct,
        szKey = szKey,
        szCustomName = szCustomName
    }
end

function SelfieOneClickModeData.GetBodyActionData()
    return tBodyActionData
end


----------------------------- 面部表情数据 -----------------------------

function SelfieOneClickModeData.SetFaceActionData(bAIAct, szKey, szCustomName)
    tFaceActionData = {
        bAIAct = bAIAct,
        szKey = szKey,
        szCustomName = szCustomName
    }
end

function SelfieOneClickModeData.GetFaceActionData()
    return tFaceActionData
end


----------------------------- 录制参数 -----------------------------

function SelfieOneClickModeData.SetVideoPrams(tPrams)
    tVideoPrams = tPrams
end

function SelfieOneClickModeData.GetVideoPrams()
    return tVideoPrams
end

function SelfieOneClickModeData.ClearVideoPrams()
    tVideoPrams = nil
end

----------------------------- AI动作判断 -----------------------------

function SelfieOneClickModeData.IsUseAIAction()
   
end

function SelfieOneClickModeData.IsAIBodyAction()
  
end

function SelfieOneClickModeData.IsAIFaceAction()
   
end
