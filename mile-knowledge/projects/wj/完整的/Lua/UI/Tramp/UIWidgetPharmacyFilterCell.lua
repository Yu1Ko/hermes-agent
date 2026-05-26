-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetPharmacyFilterCell
-- Date: 2023-04-18 15:59:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetPharmacyFilterCell = class("UIWidgetPharmacyFilterCell")

function UIWidgetPharmacyFilterCell:OnEnter(tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbData = tbData
    self:UpdateInfo()
end

function UIWidgetPharmacyFilterCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPharmacyFilterCell:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            if CraftManageData.IsLocked(self.tbData.tbCraftInfos) then
                TipsHelper.ShowNormalTip(UIHelper.GBKToUTF8(self.tbData.tbCraftInfos.szUnlockTip))
            else
                local tbData = self.tbData.tbCraftInfos
                tbData.szName = self.tbData.szName
                self.tbData.funcSelect(self.tbData.tbCraftInfos, self)
            end
        end
    end)
end

function UIWidgetPharmacyFilterCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetPharmacyFilterCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetPharmacyFilterCell:UpdateInfo()
    local szName = self.tbData.szName ~= "？？？" and UIHelper.GBKToUTF8(self.tbData.szName) or "未知"
    UIHelper.SetString(self.LabelTitle03, szName)
    UIHelper.SetString(self.LabelTitle04, szName)
    UIHelper.SetString(self.LabelOrders, string.format("最多可做:%s", tostring(self.tbData.tbCraftInfos.nMaxMakeNum)))
    UIHelper.SetVisible(self.WidgteOrders, szName ~= "未知")
    UIHelper.SetSwallowTouches(self._rootNode, false)
end

return UIWidgetPharmacyFilterCell