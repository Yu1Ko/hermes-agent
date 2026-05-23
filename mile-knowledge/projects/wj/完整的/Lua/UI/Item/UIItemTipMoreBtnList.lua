-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipMoreBtnList
-- Date: 2022-11-28 19:18:59
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipMoreBtnList = class("UIItemTipMoreBtnList")

function UIItemTipMoreBtnList:OnEnter(tbBtnInfo)
    self.tbBtnInfo = tbBtnInfo
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbScriptBtn = {}
    self:UpdateInfo()
end

function UIItemTipMoreBtnList:OnExit()
    self.bInit = false
end

function UIItemTipMoreBtnList:BindUIEvent()

end

function UIItemTipMoreBtnList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipMoreBtnList:UpdateInfo()
    for index in ipairs(self.tbBtnInfo) do
        self.tbScriptBtn[index] = self.tbScriptBtn[index] or UIHelper.AddPrefab(PREFAB_ID.WidgetTipMoreOperBtnCell, self.LayoutMoreOper)
    end

    for index, scriptBtn in ipairs(self.tbScriptBtn) do
        local tbInfo = self.tbBtnInfo[index]
        if tbInfo then
            local btn = scriptBtn._rootNode
            UIHelper.SetVisible(btn, true)
            scriptBtn:OnEnter(tbInfo)
            UIHelper.SetTouchDownHideTips(btn, false)
            UIHelper.SetName(scriptBtn._rootNode, "WidgetTipMoreOperBtnCell" .. index)
        else
            UIHelper.SetVisible(btn, false)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutMoreOper)
    UIHelper.SetContentSize(self.ImgBg, UIHelper.GetContentSize(self.LayoutMoreOper))
end

function UIItemTipMoreBtnList:ClearAllBtns()
    self.tbScriptBtn = {}
    UIHelper.RemoveAllChildren(self.LayoutMoreOper)
    UIHelper.LayoutDoLayout(self.LayoutMoreOper)
    UIHelper.SetContentSize(self.ImgBg, UIHelper.GetContentSize(self.LayoutMoreOper))
end

return UIItemTipMoreBtnList