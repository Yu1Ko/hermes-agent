-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIYuanxiaoLetterView
-- Date: 2026-01-26 17:03:31
-- Desc: ?
-- ---------------------------------------------------------------------------------
--UIMgr.Open(VIEW_ID.PanelYuanXiaoJie)
local UIYuanxiaoLetterView = class("UIYuanxiaoLetterView")
local tbType = {
    NONE = 1,
    ANI = 2,
    NOANI = 3,
}

function UIYuanxiaoLetterView:OnEnter(dwID)
    self.dwID = dwID
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIYuanxiaoLetterView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIYuanxiaoLetterView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIYuanxiaoLetterView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIYuanxiaoLetterView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIYuanxiaoLetterView:UpdateInfo()
    local tInfo = Table_GetCustomInvitation(self.dwID)
    if not tInfo then
        return
    end
    
    local nType = tInfo.nVKType
    if nType == tbType.NONE then
        UIHelper.PlayAni(self, self.AniAll, "AniYuanXiaoJieShow1")
    elseif nType == tbType.ANI then
        UIHelper.SetVisible(self.ImgLetter4, true)
        local szName = UI_GetClientPlayerName()
        UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(szName))
        UIHelper.PlayAni(self, self.AniAll, "AniYuanXiaoJieShow1", function()
            UIHelper.PlayAni(self, self.AniAll, "AniNameShow")
        end)
    elseif nType == tbType.NOANI then
        UIHelper.SetVisible(self.WidgetName, true)
        for k, img in pairs(self.tbNameList) do
            UIHelper.SetVisible(img, false)
        end
        UIHelper.SetVisible(self.ImgPet, false)
        UIHelper.SetVisible(self.ImgLetter4, true)
        UIHelper.PlayAni(self, self.AniAll, "AniYuanXiaoJieShow1", function ()
            UIHelper.SetVisible(self.ImgPet, true)
        end)
    end
end


return UIYuanxiaoLetterView