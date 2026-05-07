local UIWidgetMonsterBookImpartPop = class("UIWidgetMonsterBookImpartPop")

function UIWidgetMonsterBookImpartPop:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetMonsterBookImpartPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookImpartPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UIWidgetMonsterBookImpartPop:RegEvent()

end

function UIWidgetMonsterBookImpartPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookImpartPop:UpdateInfo()
    UIHelper.SetString(self.LabelTransSkillRule, g_tStrings.MONSTER_BOOK_TRANS_SKILL_RULE)
    UIHelper.SetString(self.LabelTransLevelRule, g_tStrings.MONSTER_BOOK_TRANS_LEVEL_RULE)

    for nLevel, widgetRow in ipairs(self.tWidgetRows) do
        local scriptRow = UIHelper.GetBindScript(widgetRow)
        local tLimitInfo = MonsterBookData.tImpartLimitInfoMap[nLevel]
        if tLimitInfo then
            UIHelper.SetString(scriptRow.LabelLevel, nLevel)
            UIHelper.SetString(scriptRow.LabelJingNai, tLimitInfo.nNeedValue)
            UIHelper.SetString(scriptRow.LabelRequirement, string.format("%d/%d级", tLimitInfo.nSELimitImpartLevel, tLimitInfo.nNoLimitImpartLevel))
            UIHelper.SetString(scriptRow.LabelCost, tLimitInfo.nCost)
        end
        UIHelper.SetVisible(widgetRow, tLimitInfo ~= nil)
    end
end

return UIWidgetMonsterBookImpartPop