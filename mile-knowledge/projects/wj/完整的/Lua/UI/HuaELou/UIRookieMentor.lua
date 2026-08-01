-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRookieMentor
-- Date: 2024-05-14 21:44:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRookieMentor = class("UIRookieMentor")

function UIRookieMentor:OnEnter(dwOperatActID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local tActivity = UIHuaELouActivityTab[nID]
    if not tActivity then
        return
    end

    local tLine = Table_GetOperActyInfo(dwOperatActID)
    if tLine and tLine.szTitle then
        UIHelper.SetString(self.LabelNormalName1, UIHelper.GBKToUTF8(tLine.szTitle))
    end

    self.nID = nID
    self.dwOperatActID = dwOperatActID
    self.nBtnID = tActivity.nBtnID

    if tActivity.szbgImgPath ~= "" and self.BgGift then
        UIHelper.SetTexture(self.BgGift, tActivity.szbgImgPath)
    end

    -- self:UpdateTimeInfo(tLine)
    self:UpdateInfo()
end

function UIRookieMentor:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRookieMentor:BindUIEvent()

end

function UIRookieMentor:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRookieMentor:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRookieMentor:UpdateInfo()
    local tReward = HuaELouData.GetShowReward(self.nID) or {}
    if Platform.IsMobile() then
        UIHelper.SetVisible(self.LayoutReward, true)
        UIHelper.SetVisible(self.LayoutRewardVK, false)
        UIHelper.SetVisible(self.BtnDetail, true)
        for k, v in ipairs(self.tbItem) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, v)
            if script then
                script:OnInitWithTabID(tReward[k][1], tReward[k][2], tReward[k][3])
                script:SetClickCallback(function ()
                    if UIHelper.GetSelected(script.ToggleSelect) then
                        UIHelper.SetSelected(script.ToggleSelect, false)
                    end
                    TipsHelper.ShowItemTips(v, tReward[k][1], tReward[k][2])
                end)
            end
        end

        if self.BtnDetail and self.nBtnID ~= 0 then
            local scriptBtn = UIHelper.GetBindScript(self.BtnDetail)
            if scriptBtn then
                scriptBtn:OnEnter(self.nBtnID)
            end
        end
    else
        UIHelper.SetVisible(self.LayoutReward, false)
        UIHelper.SetVisible(self.LayoutRewardVK, true)
        UIHelper.SetVisible(self.BtnDetail, false)
        for k, v in ipairs(self.tbItemVK) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, v)
            if script then
                script:OnInitWithTabID(tReward[k][1], tReward[k][2], tReward[k][3])
                script:SetClickCallback(function ()
                    if UIHelper.GetSelected(script.ToggleSelect) then
                        UIHelper.SetSelected(script.ToggleSelect, false)
                    end
                    TipsHelper.ShowItemTips(v, tReward[k][1], tReward[k][2])
                end)
            end
        end
    end
end

function UIRookieMentor:UpdateTimeInfo(tLine)
    if self.LabelMiddle then
        local tStartTime, tEndTime = tLine.tStartTime, tLine.tEndTime
        local nStart = tStartTime[1]
        local nEnd = tEndTime and tEndTime[1]
        local szText = HuaELouData.GetTimeShowText(nStart, nEnd)

        UIHelper.SetString(self.LabelMiddle, szText)
    end
end

return UIRookieMentor