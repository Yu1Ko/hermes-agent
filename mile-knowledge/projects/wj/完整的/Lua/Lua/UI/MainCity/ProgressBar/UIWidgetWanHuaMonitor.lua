-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetWanHuaMonitor
-- Date: 2025-08-20 16:32:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetWanHuaMonitor = class("UIWidgetWanHuaMonitor")
local szBlackFrame = "UIAtlas2_SkillDX_SpecialSkill_WanHua_2_black"
local szWhiteFrame = "UIAtlas2_SkillDX_SpecialSkill_WanHua_2_white"

local tbNumFrameList = {
    [1] = "UIAtlas2_SkillDX_SpecialSkill_WanHua_2_purpleNumber_1",
    [2] = "UIAtlas2_SkillDX_SpecialSkill_WanHua_2_purpleNumber_2",
    [3] = "UIAtlas2_SkillDX_SpecialSkill_WanHua_2_purpleNumber_3",
    [4] = "UIAtlas2_SkillDX_SpecialSkill_WanHua_2_purpleNumber_4",
    [5] = "UIAtlas2_SkillDX_SpecialSkill_WanHua_2_purpleNumber_5",
    [6] = "UIAtlas2_SkillDX_SpecialSkill_WanHua_2_purpleNumber_6",
    [7] = "UIAtlas2_SkillDX_SpecialSkill_WanHua_2_purpleNumber_7",
}

function UIWidgetWanHuaMonitor:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIWidgetWanHuaMonitor:OnExit()
    Timer.DelAllTimer(self)
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetWanHuaMonitor:BindUIEvent()
    
end

function UIWidgetWanHuaMonitor:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetWanHuaMonitor:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetWanHuaMonitor:UpdateInfo()
    self.nLastSunValue = 0
    self.nLastMoonValue = 0
    self.bPlayOutAni = false
    Timer.DelAllTimer(self)
    local nTimer = Timer.AddCycle(self, 1/8, function ()
        self:Update()
    end)
end

function UIWidgetWanHuaMonitor:Update()
    local player = GetClientPlayer()
    if not player then
        UIHelper.SetVisible(self._rootNode, false)
        return
    end

    local nSunEnergy = player.nCurrentSunEnergy
	local nMoonEnergy = player.nCurrentMoonEnergy
    local nValue = nSunEnergy - nMoonEnergy
    if nSunEnergy > 0 or nMoonEnergy > 0 then
        UIHelper.SetVisible(self._rootNode, true)
        self.bPlayOutAni = false
        local nLastValue = self.nLastSunValue - self.nLastMoonValue
        if nValue > 0 or nLastValue > 0 then    --白
            for i = 1, 5, 1 do
                local imgNode = self.tbDotList[i]
                UIHelper.SetVisible(imgNode, i <= nSunEnergy)
                UIHelper.SetSpriteFrame(imgNode, szWhiteFrame)
            end
        elseif nValue < 0 or nLastValue < 0 then    --黑
            for i = 1, 5, 1 do
                local imgNode = self.tbDotList[i]
                UIHelper.SetVisible(imgNode, i <= nMoonEnergy)
                UIHelper.SetSpriteFrame(imgNode, szBlackFrame)
            end
        else
            for i = 1, 5, 1 do
                local imgNode = self.tbDotList[i]
                UIHelper.SetVisible(imgNode, false)
            end
        end
    else
        if not self.bPlayOutAni then
            UIHelper.SetVisible(self._rootNode, false)
            self.bPlayOutAni = true
        end
    end

    if Buff_Have(player, 29543, 1) then
        local nPower = Buffer_GetStackNum(29543)
        UIHelper.SetVisible(self.ImgNum, true)
        UIHelper.SetVisible(self.ImgX, true)
        UIHelper.SetSpriteFrame(self.ImgNum, tbNumFrameList[nPower])
    else
        UIHelper.SetVisible(self.ImgNum, false)
        UIHelper.SetVisible(self.ImgX, false)
    end

    self.nLastSunValue = nSunEnergy
    self.nLastMoonValue = nMoonEnergy
end


return UIWidgetWanHuaMonitor