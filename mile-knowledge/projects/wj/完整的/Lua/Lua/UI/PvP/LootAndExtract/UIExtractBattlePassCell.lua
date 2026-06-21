-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractBattlePassCell
-- Date: 2025-04-01 17:14:41
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIExtractBattlePassCell = class("UIExtractBattlePassCell")

function UIExtractBattlePassCell:OnEnter(nIndex, tbItems)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nIndex = nIndex
    self.tbItems = tbItems
    self:UpdateInfo()
end

function UIExtractBattlePassCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExtractBattlePassCell:BindUIEvent()
    
end

function UIExtractBattlePassCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIExtractBattlePassCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExtractBattlePassCell:UpdateInfo()
    UIHelper.SetString(self.LabelNum_Normal, self.nIndex)
    UIHelper.SetString(self.LabelNum_Select, self.nIndex)
    UIHelper.SetVisible(self.ImgGet, self.tbItems.bReward)
    local bGot = self.tbItems.bGot
    for i, widget in ipairs(self.tbItemWidget) do
        UIHelper.RemoveAllChildren(widget)
        local item = self.tbItems[i]
        if item then
            local dwType, dwIndex, nCount = item[1], item[2], item[3]
            local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetHuaELouReward, widget, dwType, dwIndex, nCount)
            scriptCell:SetCanGetState(nil, bGot)
            scriptCell:SetSelectChangeCallback(function (bSelected)
                if bSelected then
                    TipsHelper.ShowItemTips(scriptCell._rootNode, dwType, dwIndex, false, TipsLayoutDir.AUTO)
                end
            end)
            UIHelper.SetAnchorPoint(scriptCell._rootNode, 0.5, 0.5)
        end
    end
end


return UIExtractBattlePassCell