local UIMonsterBookEntranceResultPop = class("UIMonsterBookEntranceResultPop")
local EFFECT_DISPLAY_TIME = 10
function UIMonsterBookEntranceResultPop:OnEnter(tParam)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self.nEffectTickCount = tParam.nEffectTickCount
    self:UpdateInfo(tParam)

    self.nTimerID = self.nTimerID or Timer.AddFrameCycle(self, 15, function ()
        self:UpdateEffectTime()
    end)
end

function UIMonsterBookEntranceResultPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMonsterBookEntranceResultPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSkillIcon, EventType.OnClick, function ()
        if self.szEffectTips then
            TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnSkillIcon, self.szEffectTips)
        end
    end)
end

function UIMonsterBookEntranceResultPop:RegEvent()

end

function UIMonsterBookEntranceResultPop:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIMonsterBookEntranceResultPop:UpdateEffectTime()
    local nTime = EFFECT_DISPLAY_TIME - math.floor((GetTickCount() - self.nEffectTickCount) / 1000)
    if nTime >= 0 then
        UIHelper.SetString(self.LabelTitle, string.format("即将前往（%d秒）", nTime))
    else
        UIMgr.Close(self)
    end
end
function UIMonsterBookEntranceResultPop:UpdateInfo(tParam)
    local bResult = tParam.bResult    
    local nLevel = tParam.nRealLevel
    local nEffectID, tEffectInfo = tParam.nEffectID, tParam.tEffectInfo
    local szBossName = tParam.szBossName
    local szResult = "<color=#D7F6FF>您预测了</c><color=#FFE26E>第%d层</color><color=#D7F6FF>，</c><color=#D7F6FF>即将前往</c><color=#FFE26E>第%d层</color><color=#D7F6FF>挑战</c><color=#FFE26E>%s</color>"
    szResult = string.format(szResult, tParam.nGuessLevel, nLevel, szBossName)
    UIHelper.SetRichText(self.RichTextResultMain, szResult)
    UIHelper.SetVisible(self.WidgetRewarded, bResult)
    UIHelper.SetVisible(self.WidgetFailed, not bResult)
    UIHelper.SetVisible(self.WidgetBuffObtained, nEffectID ~= 0)
    UIHelper.SetVisible(self.WidgetBuffNone, nEffectID == 0)
    
    if bResult then
        local dwTabType = tParam.dwTabType
        local dwIndex = tParam.dwIndex
        local nStackNum = tParam.nStackNum or 1
        local pItemInfo = GetItemInfo(dwTabType, dwIndex)
        UIHelper.RemoveAllChildren(self.WidgetRewardItem80)
        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetRewardItem80)
        scriptItem:OnInitWithTabID(dwTabType, dwIndex)
        scriptItem:SetLabelCount(nStackNum)
        local szText = ""
        if pItemInfo then
            szText = UIHelper.GBKToUTF8(pItemInfo.szName)
            scriptItem:SetClickCallback(function ()
                local _, scriptItemTips = TipsHelper.ShowItemTips(scriptItem._rootNode, dwTabType, dwIndex, false)
                if scriptItemTips then
                    UIHelper.SetVisible(scriptItemTips.BtnItemShare, false)
                end
            end)
        end
        UIHelper.SetString(self.LabelRewardName, szText)
    else
        local nFail = tParam.nFail or 0
        local szText = g_tStrings.MONSTER_STEP_EFFECT_FAIL[nFail] or ""
        UIHelper.SetString(self.LabelFailed, szText)
    end
    if nEffectID ~= 0 then
        local szImgPath = UIHelper.GetIconPathByIconID(tEffectInfo.dwIconID)
        local szBuffName = UIHelper.GBKToUTF8(tEffectInfo.szName)
        local szDescription = UIHelper.GBKToUTF8(tEffectInfo.szDescription)
        self.szEffectTips = string.format("特殊效果：%s\n%s", szBuffName, szDescription)
        UIHelper.SetTexture(self.ImgSkillIcon, szImgPath)
        UIHelper.SetString(self.LabelBuffName, szBuffName)
    end
end

return UIMonsterBookEntranceResultPop