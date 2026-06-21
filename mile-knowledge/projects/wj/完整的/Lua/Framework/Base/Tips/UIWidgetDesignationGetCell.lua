-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetDesignationGetCell
-- Date: 2024-01-12 10:42:09
-- Desc: WidgetDesignationGetCell
-- ---------------------------------------------------------------------------------

local UIWidgetDesignationGetCell = class("UIWidgetDesignationGetCell")

function UIWidgetDesignationGetCell:OnEnter(tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbData = tbData
    self:UpdateInfo()
end

function UIWidgetDesignationGetCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetDesignationGetCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseDesignationGetCell, EventType.OnClick, function()
        -- UIMgr.Close(self)
        Timer.DelAllTimer(self)
        self.tbData.callback(self._rootNode)
    end)
    UIHelper.BindUIEvent(self.BtnDesignationGet, EventType.OnClick, function()
        local tbData = self.tbData

        local dwLinkID = tbData.nDesignationID
        local bPrefixLink = tbData.bPrefix

        UIMgr.Open(VIEW_ID.PanelPersonalTitle, dwLinkID, bPrefixLink)
    end)
end

function UIWidgetDesignationGetCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetDesignationGetCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetDesignationGetCell:UpdateInfo()
    local tbData = self.tbData

    local r, g, b = GetItemFontColorByQuality(tbData.nQuality)
    UIHelper.SetString(self.LabelTitle, tbData.szTitle)
    UIHelper.SetString(self.LabelName, tbData.szName)
    UIHelper.SetColor(self.LabelName, cc.c3b(r, g, b))
    UIHelper.LayoutDoLayout(self.LayoutTitle)

    local callback = tbData.callback
    UIHelper.PlayAni(self, self.AniDesignationGetCell, "AniAchievementGetShow", function()
        Timer.Add(self, 5, function()
            callback(self._rootNode)
        end)
    end)
end


return UIWidgetDesignationGetCell