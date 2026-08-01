-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeIdentityPrefumeAddWidget
-- Date: 2024-01-23 14:29:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeIdentityPrefumeAddWidget = class("UIHomeIdentityPrefumeAddWidget")

function UIHomeIdentityPrefumeAddWidget:OnEnter(nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nIndex = nIndex
    self:UpdateInfo()
end

function UIHomeIdentityPrefumeAddWidget:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeIdentityPrefumeAddWidget:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.BtnAdd, false)
    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function ()
        if self.fnClickCallback then
            self.fnClickCallback()
        end
    end)
end

function UIHomeIdentityPrefumeAddWidget:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomeIdentityPrefumeAddWidget:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomeIdentityPrefumeAddWidget:UpdateInfo()
    
end

function UIHomeIdentityPrefumeAddWidget:SetClickCallback(fnClickCallback)
    self.fnClickCallback = fnClickCallback
end

function UIHomeIdentityPrefumeAddWidget:SetRecallCallback(fnRecallCallback)
    self.scriptIcon:SetRecallVisible(true)
    self.scriptIcon:SetRecallCallback(fnRecallCallback)
end

function UIHomeIdentityPrefumeAddWidget:SetItemCilckCallback(fnClickCallback)
    self.scriptIcon:SetClickCallback(fnClickCallback)
end

function UIHomeIdentityPrefumeAddWidget:OnChangeItem(dwItemTabIndex, nCount)
    UIHelper.RemoveAllChildren(self.WidgetGoods80)
    if not dwItemTabIndex then
        return
    end
    self.scriptIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetGoods80)
    self.scriptIcon:OnInitWithTabID(ITEM_TABLE_TYPE.OTHER, dwItemTabIndex, nCount)
    self.scriptIcon:SetClickNotSelected(true)
    self.scriptIcon:SetClearSeletedOnCloseAllHoverTips(true)
end

return UIHomeIdentityPrefumeAddWidget