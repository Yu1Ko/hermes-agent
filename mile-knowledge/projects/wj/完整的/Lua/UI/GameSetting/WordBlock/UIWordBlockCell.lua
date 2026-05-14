-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIWordBlockCell
-- Date: 2024-09-06 11:10:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWordBlockCell = class("UIWordBlockCell")

function UIWordBlockCell:OnEnter(tbDataList)
    self.tbDataList = tbDataList or {}

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()

    Timer.AddFrame(self, 1, function()
        UIHelper.WidgetFoceDoAlign(self)
    end)
end

function UIWordBlockCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWordBlockCell:BindUIEvent()

end

function UIWordBlockCell:RegEvent()
    Event.Reg(self, EventType.OnEnterWordBlockDelAll, function()
        UIHelper.SetTabVisible(self.tbTogSelectList, true)
        UIHelper.SetTabVisible(self.tbBtnEditList, false)

        for k, tog in ipairs(self.tbTogSelectList) do
            UIHelper.SetSelected(tog, false)
        end
    end)

    Event.Reg(self, EventType.OnExitWordBlockDelAll, function()
        UIHelper.SetTabVisible(self.tbTogSelectList, false)
        UIHelper.SetTabVisible(self.tbBtnEditList, true)
    end)
end

function UIWordBlockCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWordBlockCell:UpdateInfo()
    UIHelper.SetTabVisible(self.tbWidgetList, false)

    for k, tbData in ipairs(self.tbDataList) do
        UIHelper.SetVisible(self.tbWidgetList[k], true)

        local labelWord = self.tbLabelWordList[k]
        local labelDesc = self.tbLabelSettingList[k]
        local btnEdit = self.tbBtnEditList[k]
        local togSelect = self.tbTogSelectList[k]

        local szWord = tbData.szWord
        local bRecruitBlock = tbData.bRecruitBlock

        UIHelper.SetString(labelWord, szWord)
        UIHelper.SetString(labelDesc, string.format("生效场景：%s", WordBlockMgr.GetBlokDescByWord(szWord)))

        UIHelper.BindUIEvent(btnEdit, EventType.OnClick, function()
            UIMgr.Open(VIEW_ID.PanelProhibitWordPop, tbData)
        end)

        UIHelper.BindUIEvent(togSelect, EventType.OnSelectChanged, function(_, bSelected)
            Event.Dispatch(EventType.OnWordBlockSelected, szWord, bSelected)
        end)
    end
end


return UIWordBlockCell