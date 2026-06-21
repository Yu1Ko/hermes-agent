-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipBtnList
-- Date: 2023-11-24 15:09:43
-- Desc: ?
-- ---------------------------------------------------------------------------------
---@class UIItemTipBtnList

local UIItemTipBtnList = class("UIItemTipBtnList")

function UIItemTipBtnList:OnEnter(tbBtnInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self._keepmt = true
    end
    UIHelper.SetVisible(self._rootNode, false)
    self.nTopBtnCount = 0
    self.nBottomBtnCount = 0
    self.tbBtnInfo = tbBtnInfo
    self:UpdateInfo()
end

function UIItemTipBtnList:OnExit()
    self.bInit = false
end

function UIItemTipBtnList:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.ScrollViewCommonOp, false)
    UIHelper.SetTouchDownHideTips(self.ScrollViewNegativeOp, false)
    UIHelper.SetSwallowTouches(self.ScrollViewCommonOp, true)
    UIHelper.SetSwallowTouches(self.ScrollViewNegativeOp, true)
end

function UIItemTipBtnList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipBtnList:UpdateInfo()
    local tbBtnInfo = self.tbBtnInfo
    self.nTopBtnCount = 0
    self.nBottomBtnCount = 0
    UIHelper.RemoveAllChildren(self.ScrollViewNegativeOp)
    UIHelper.RemoveAllChildren(self.ScrollViewCommonOp)
    if #tbBtnInfo > 0 then
        UIHelper.SetVisible(self._rootNode, true)
        for _, tbBtn in ipairs(tbBtnInfo) do
            local nPrefabID = PREFAB_ID.WidgetBtnTipOperation
            local parent = self.ScrollViewCommonOp
            local bFobidCheckBtnType = tbBtn.bFobidCheckBtnType or false

            if not table.contain_value(ITEMTIPS_IMPORTANT_BTN, tbBtn.szName) and not bFobidCheckBtnType then
                tbBtn.bNormalBtn = true
            end

            if tbBtn.bNormalBtn then
                self.nTopBtnCount = self.nTopBtnCount + 1
                parent = self.ScrollViewNegativeOp
            end

            local scriptBtn = UIHelper.AddPrefab(nPrefabID, parent)
            scriptBtn:OnEnter(tbBtn)
        end
        self.nBottomBtnCount = #self.tbBtnInfo - self.nTopBtnCount
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCommonOp)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewNegativeOp)

        local innerContainer = self.ScrollViewCommonOp:getInnerContainer()
        local nLayoutListWidth, nLayoutListHeigh = UIHelper.GetContentSize(innerContainer)
        local nWidgetListWidth, nWidgetListHeight = UIHelper.GetContentSize(self.ScrollViewCommonOp)
        UIHelper.SetContentSize(self.ScrollViewCommonOp, nWidgetListWidth, nLayoutListHeigh)
        UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true ,true)
    end
end

function UIItemTipBtnList:GetBtnCount()
    return self.nTopBtnCount, self.nBottomBtnCount
end

return UIItemTipBtnList