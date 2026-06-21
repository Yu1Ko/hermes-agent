-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetYaoZongPlant
-- Date: 2025-08-19 15:26:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetYaoZongPlant = class("UIWidgetYaoZongPlant")

function UIWidgetYaoZongPlant:OnEnter(nIndex)
    self.nIndex = nIndex
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdatePlantInfo()
end

function UIWidgetYaoZongPlant:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetYaoZongPlant:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSkill1, EventType.OnSelectChanged, function (_,bSelected)
        if bSelected then
            local dwID = SpecialDXSkillData.tCurPlantList[self.nIndex].dwID
            if dwID then
                Event.Dispatch(EventType.OnTargetChanged, TARGET.NPC, dwID)
                SetTarget(TARGET.NPC, dwID)
            end
        end
    end)
end

function UIWidgetYaoZongPlant:RegEvent()
    Event.Reg(self, "PET_DISPLAY_DATA_UPDATE", function()
        SpecialDXSkillData.UpdateNowPlant()
        self:UpdatePlantInfo()
    end)

    Event.Reg(self, "UPDATE_BEAST_PET_INDEX", function()
        local tCallNpc = {arg3, arg4, arg5}
        local tCallPlant = {}
        for i = 1, 3 do
            if tCallNpc[i] then
                AppendWhenNotExist(tCallPlant, tCallNpc[i])
            end
        end
        SpecialDXSkillData.tCallPlant = tCallPlant
        SpecialDXSkillData.UpdateNowPlant()
        self:UpdatePlantInfo()
    end)

    Event.Reg(self, "PLAYER_STATE_UPDATE", function()
        SpecialDXSkillData.UpdatePlantLM()
        self:UpdatePlantHealth()
    end)

    Event.Reg(self, EventType.OnTargetChanged, function(nTargetType, nTargetId)
        SpecialDXSkillData.dwTargetNpcID = nTargetId
		if nTargetType ~= TARGET.NPC then
			SpecialDXSkillData.dwTargetNpcID = 0
		end
        self:UpdatePlantSelect()
    end)

    Event.Reg(self, EventType.OnShortcutUseSkillSelect, function(nIndex, nPressType)
        if nIndex - 200 == self.nIndex then
            if nPressType == 1 then
                local tPlant = SpecialDXSkillData.tNowPlant[self.tPlantInfo.dwTemplateID]
                if tPlant then
                    UIHelper.SetSelected(self.TogSkill1, true, true)
                end
            end
        end
    end)
end

function UIWidgetYaoZongPlant:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetYaoZongPlant:UpdatePlantSelect()
    local dwSelectID = SpecialDXSkillData.dwTargetNpcID or 0
    local tPlant = SpecialDXSkillData.tNowPlant[self.tPlantInfo.dwTemplateID]
    if tPlant and tPlant.dwID == dwSelectID then
        UIHelper.SetSelected(self.TogSkill1, true, false)
    else
        UIHelper.SetSelected(self.TogSkill1, false, false)
    end
end

function UIWidgetYaoZongPlant:UpdatePlantHealth()
    local tPlant = SpecialDXSkillData.tNowPlant[self.tPlantInfo.dwTemplateID]
    local nPercent = 0
    if tPlant and tPlant.nMaxLife ~= 0 then
        nPercent = tPlant.nCurrentLife / tPlant.nMaxLife
    end
    UIHelper.SetProgressBarPercent(self.Bar1, nPercent * 100)
end

function UIWidgetYaoZongPlant:UpdatePlantTime()
    Timer.DelAllTimer(self)
    Timer.AddCycle(self, 1/8, function ()
        local tBuffInfo = Buffer_GetTimeData(self.tPlantInfo.dwBuffID)
        if tBuffInfo then
            local nLeftFrame = Buffer_GetLeftFrame(tBuffInfo)
            local nHour, nMinute, nSecond = TimeLib.GetTimeToHourMinuteSecondTenthSec(nLeftFrame, true)
            UIHelper.SetString(self.LabelCount1, tostring(nSecond))
            UIHelper.SetVisible(self.LabelCount1, true)
        else
            UIHelper.SetVisible(self.LabelCount1, false)
        end
    end)

end

function UIWidgetYaoZongPlant:UpdatePlantInfo()
    local nIndex = self.nIndex
    if not nIndex then
        return
    end
    self.tPlantInfo = SpecialDXSkillData.tCurPlantList[nIndex]
    if self.tPlantInfo then
        local nIconID = Table_GetSkillIconID(self.tPlantInfo.dwSkillID, 1)
        UIHelper.SetItemIconByIconID(self.ImgIcon1, nIconID)
        UIHelper.UpdateMask(self.MaskSkill)
    
        local tPlant = SpecialDXSkillData.tNowPlant[self.tPlantInfo.dwTemplateID]
        if tPlant then
            UIHelper.SetEnable(self.TogSkill1, true)
            UIHelper.SetNodeGray(self.ImgIcon1, false)
            SpecialDXSkillData.tCurPlantList[nIndex].dwID = tPlant.dwID
        else
            UIHelper.SetEnable(self.TogSkill1, false)
            UIHelper.SetNodeGray(self.ImgIcon1, true)
            SpecialDXSkillData.tCurPlantList[nIndex].dwID = nil
        end
    
        self:UpdatePlantSelect()
        self:UpdatePlantHealth()
        self:UpdatePlantTime()
    end
end

return UIWidgetYaoZongPlant