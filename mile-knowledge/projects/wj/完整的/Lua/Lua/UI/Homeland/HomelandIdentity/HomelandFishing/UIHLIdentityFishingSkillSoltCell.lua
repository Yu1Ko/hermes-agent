-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHLIdentityFishingSkillSoltCell
-- Date: 2024-03-01 14:15:47
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHLIdentityFishingSkillSoltCell = class("UIHLIdentityFishingSkillSoltCell")

function UIHLIdentityFishingSkillSoltCell:OnEnter(tbBtnData, nSlotID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nSlotID    = nSlotID
    self.tbBtnData  = tbBtnData
    self.dwSkillID  = tbBtnData and tbBtnData.id
    self:UpdateInfo()
end

function UIHLIdentityFishingSkillSoltCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHLIdentityFishingSkillSoltCell:BindUIEvent()
    UIHelper.SetLongPressDelay(self.BtnSkill, SHOW_TIP_PRESS_TIME)
    UIHelper.SetLongPressDistThreshold(self.BtnSkill, 5)
    UIHelper.BindUIEvent(self.BtnSkill, EventType.OnLongPress, function(_, x, y)
        if self.dwSkillID then
            local nSkillLevel = self.bEnterDynamicSkills and self.nSkillLevel or g_pClientPlayer.GetSkillLevel(self.dwSkillID)
            if nSkillLevel == 0 then
                nSkillLevel = 1
            end
            self:ShowSkillTip(nSkillLevel)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSkill, EventType.OnTouchEnded, function()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillInfoTips)
    end)

    UIHelper.BindUIEvent(self.BtnSkill, EventType.OnClick, function()
        if HomelandFishingData.IsSkillLock(self.nSlotID) then
            TipsHelper.ShowNormalTip(HomelandFishingData.GetLockTips(self.nSlotID))
        elseif self.tbBtnData and self.tbBtnData.callback then
            self.tbBtnData.callback()
        end
    end)
end

function UIHLIdentityFishingSkillSoltCell:RegEvent()
    Event.Reg(self, EventType.OnFishHooked, function (bDelete)
        if self.nSlotID ~= 1 then
            return
        end
        UIHelper.SetVisible(self.WidgetCanClick, not bDelete)
    end)
end

function UIHLIdentityFishingSkillSoltCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHLIdentityFishingSkillSoltCell:UpdateInfo()
    if not self.tbBtnData then
        UIHelper.SetVisible(self.WidgetLock, true)
        UIHelper.SetVisible(self.ImgSkillIcon, false)
        return
    end
    UIHelper.SetVisible(self.WidgetLock, false)
    UIHelper.SetVisible(self.ImgSkillIcon, true)
    self.nCDSkillTimer = Timer.AddFrameCycle(self, 1, function ()
        if not self.dwSkillID then
            return
        end

        local _, nLeft, nTotal, nCDCount, nMaxCount, bIsRecharge, bPublicCD = SkillData.GetSkillCDProcess(g_pClientPlayer, self.dwSkillID)
        nLeft = nLeft or 0
        nTotal = nTotal or 1

        nLeft = nLeft / GLOBAL.GAME_FPS
        nTotal = nTotal / GLOBAL.GAME_FPS

        local bCool = nLeft > 0 or nTotal > 0
        UIHelper.SetActiveAndCache(self, self.WidgetSkillCd, bCool)
        UIHelper.SetActiveAndCache(self, self.ImgSkillCd, bCool)
        UIHelper.SetActiveAndCache(self, self.LabelTime, bCool)

        if bCool then
            UIHelper.SetString(self.LabelTime, UIHelper.GetSkillCDText(nLeft, true))
        end
    end)
end

function UIHLIdentityFishingSkillSoltCell:ShowSkillTip(nSkillLevel)
    local tCursor = GetCursorPoint()
    local tips, tipsScriptView = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetSkillInfoTips, tCursor.x,
            tCursor.y, self.dwSkillID, nil, nil, nSkillLevel)
    tipsScriptView:SetBtnVisible(false)
end

return UIHLIdentityFishingSkillSoltCell