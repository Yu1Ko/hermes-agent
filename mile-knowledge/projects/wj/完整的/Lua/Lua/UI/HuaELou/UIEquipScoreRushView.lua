-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIEquipScoreRushView
-- Date: 2024-03-21 14:34:26
-- Desc: 通用多段奖励领取
-- ---------------------------------------------------------------------------------
local UIEquipScoreRushView = class("UIEquipScoreRushView")

function UIEquipScoreRushView:OnEnter(dwOperatActID, _, nType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwID = dwOperatActID

    if HuaELouData.tCustom[self.dwID]then
        self.tCustom = HuaELouData.tCustom[self.dwID]
    end

    local tLine = Table_GetOperActyInfo(dwOperatActID)
    if tLine and tLine.bNeedRemoteCall then
        RemoteCallToServer("On_Recharge_CheckProgress", {dwOperatActID})
    end


    if tLine then
        self:UpdatePageInfo()
    end
end

function UIEquipScoreRushView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIEquipScoreRushView:BindUIEvent()

end

function UIEquipScoreRushView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "On_Recharge_CheckProgress_CallBack", function (dwID, bActive, tCustom)
        if dwID == self.dwID then
            self.tCustom = tCustom
            self:UpdateRwardInfo()
        end
    end)

    Event.Reg(self, "On_Recharge_GetProgressReward_CallBack", function (dwID, nLevel)
        if dwID == self.dwID then
            if self.tCustom and self.tCustom.tRewardState then
                self.tCustom.tRewardState[nLevel] = OPERACT_REWARD_STATE.ALREADY_GOT
                self:UpdateRwardInfo()
            end
        end
    end)
end

function UIEquipScoreRushView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIEquipScoreRushView:UpdatePageInfo()
    local tRewardInfo = Table_GetActivityProgressInfo(self.dwID)
    UIHelper.RemoveAllChildren(self.WidgetSlots)
    self.tscriptView = {}
    for nIndex, v in ipairs(tRewardInfo) do
        if self.tWidgetSlots[nIndex] then
            local scriptView = UIHelper.GetBindScript(self.tWidgetSlots[nIndex])
            if scriptView then
                self:SetEquipScoreRushSlot(scriptView, v)
                if self.tCustom then
                    self:SetRewardState(scriptView, self.tCustom.tRewardState[nIndex])
                end
                scriptView:SetfnCallBack(function ()
                    if self.tCustom.tRewardState[nIndex] == OPERACT_REWARD_STATE.CAN_GET then
                        RemoteCallToServer("On_Recharge_GetProgressReward", tRewardInfo[nIndex].dwID, tRewardInfo[nIndex].nLevel)
                    end
                end)
                table.insert(self.tscriptView, scriptView)
            end
        end
    end

    for k, v in ipairs(self.tEquipScore) do
        local nScore = tRewardInfo[k].nScore
        UIHelper.SetString(v, nScore)
    end

    self:SetEquipScorePercent()
end

function UIEquipScoreRushView:SetEquipScoreRushSlot(scriptView, tRewardInfo)
    UIHelper.SetSpriteFrame(scriptView.ImgMark, tRewardInfo.szVKIconPath)

    UIHelper.RemoveAllChildren(scriptView.LayOutRewardItem)
    local tItems = SplitString(tRewardInfo.szReward, ";")
    for k, v in ipairs(tItems) do
        local tItem = SplitString(tItems[k], "_")
        local tItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, scriptView.LayOutRewardItem)
        if tItemScript then
            tItemScript:OnInitWithTabID(tItem[1], tItem[2], tItem[3])
            tItemScript:SetClickCallback(function()
                TipsHelper.ShowItemTips(nil, tItem[1], tItem[2])
                if UIHelper.GetSelected(tItemScript.ToggleSelect) then
                    UIHelper.SetSelected(tItemScript.ToggleSelect,false)
                end
            end)
        end
    end

    UIHelper.LayoutDoLayout(scriptView.LayOutRewardItem)
end

function UIEquipScoreRushView:SetRewardState(scriptView, nState)
    UIHelper.SetVisible(scriptView.ImgRewardGetBg, nState == OPERACT_REWARD_STATE.CAN_GET)
    UIHelper.SetVisible(scriptView.WidgetFinish, nState == OPERACT_REWARD_STATE.ALREADY_GOT)
end

function UIEquipScoreRushView:UpdateRwardInfo()
    local tRewardInfo = Table_GetActivityProgressInfo(self.dwID)
    for nIndex, v in ipairs(tRewardInfo) do
        local scriptView = self.tscriptView[nIndex]
        if self.tCustom and scriptView then
            self:SetRewardState(scriptView, self.tCustom.tRewardState[nIndex])
            UIHelper.SetString(self.LabelCurrentScore, self.tCustom.nCurValue)
        end
    end

    self:SetEquipScorePercent(tRewardInfo)
end

-- 因为进度条的四个节点没有四等分 映射出一个假的进度条
-- 25% -> 20%  50% -> 46%  75% -> 72%
local function trueToFake(t)
    -- t: 真实进度 (0~100)
    if t <= 0 then return 0 end
    if t >= 100 then return 100 end

    if t <= 25 then
        -- 区间1: [0,25] -> [0,20]
        return 0.8 * t
    elseif t <= 50 then
        -- 区间2: [25,50] -> [20,46]
        return 20 + 1.04 * (t - 25)
    elseif t <= 75 then
        -- 区间3: [50,75] -> [46,72]
        return 46 + 1.04 * (t - 50)
    else
        -- 区间4: [75,100] -> [72,100]
        return 72 + 1.12 * (t - 75)
    end
end

function UIEquipScoreRushView:SetEquipScorePercent(tRewardInfo)
    if self.tCustom then
        local nPercent = 0
        local bDone = false

        for nIndex, v in ipairs(tRewardInfo) do
            local nScore = v.nScore
            if self.tEquipScoreImg[nIndex] then
                UIHelper.SetVisible(self.tEquipScoreImg[nIndex], self.tCustom.nCurValue >= nScore)
            end

            if not bDone then
                if self.tCustom.nCurValue >= nScore then
                    nPercent = nPercent + 25
                else
                    local nPreScore = tRewardInfo[nIndex - 1] and tRewardInfo[nIndex - 1].nScore or 0
                    nPercent = nPercent + ((self.tCustom.nCurValue - nPreScore) / (nScore - nPreScore)) * 100 / #tRewardInfo
                    bDone = true
                end
            end
        end

        UIHelper.SetProgressBarPercent(self.ProgressBar, trueToFake(nPercent))
        UIHelper.SetString(self.LabelCurrentScore, self.tCustom.nCurValue)
    end
end

return UIEquipScoreRushView