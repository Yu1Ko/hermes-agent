-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBookSourceCell
-- Date: 2022-12-15 22:50:47
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBookSourceCell = class("UIBookSourceCell")

function UIBookSourceCell:OnEnter(szLinkInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szLinkInfo = szLinkInfo
end

function UIBookSourceCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBookSourceCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnNav, EventType.OnClick, function ()
        Event.Dispatch("EVENT_LINK_NOTIFY", self.szLinkInfo)
        --local szLinkEvent, szLinkArg = self.szLinkInfo:match("(%w+)/(.*)")
        UIMgr.Close(VIEW_ID.PanelBookInfo)
    end)
end

function UIBookSourceCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBookSourceCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIBookSourceCell:SetCellName(szName)
    szName = string.gsub(szName, "\n", "")
    UIHelper.SetRichText(self.RichTextSourceTips, szName)
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBookSourceCell:UpdateInfo()
    
end


return UIBookSourceCell