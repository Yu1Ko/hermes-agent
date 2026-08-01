-- ---------------------------------------------------------------------------------
-- Author: liu yu min
-- Name: UIChallengeConfirmPop
-- Date: 2023-04-07 11:41:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChallengeConfirmPop = class("UIChallengeConfirmPop")

function UIChallengeConfirmPop:OnEnter(dwPlayerID, nEndFrame, szName)
    self.dwPlayerID = dwPlayerID
    self.nEndFrame = nEndFrame
    self.szName = szName
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChallengeConfirmPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelTimer(self,self.nTimerID)
end

function UIChallengeConfirmPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPK, EventType.OnClick, function()
        self:PkGo()
        if UIMgr.IsViewOpened(VIEW_ID.PanelArenaPop) then
            UIMgr.Close(VIEW_ID.PanelArenaPop)
        end
    end)
end

function UIChallengeConfirmPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChallengeConfirmPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChallengeConfirmPop:UpdateInfo()
    self:UpdateName()
    self:UpdateTime()
end

function UIChallengeConfirmPop:UpdateName()
    UIHelper.SetVisible(self.RichTextContent01,true)
    UIHelper.SetVisible(self.BtnPK,true)
    local szName = string.format("<color=#e2f6fb>%s</c> <color=#c1cfd2>正在对您发起挑战</color>", UIHelper.GBKToUTF8(self.szName))
    UIHelper.SetRichText(self.RichTextContent01,szName)
end

function UIChallengeConfirmPop:UpdateTime()
    local nLeftSecond 	= (self.nEndFrame - GetLogicFrameCount()) / GLOBAL.GAME_FPS
    nLeftSecond = math.ceil(nLeftSecond)
    nLeftSecond	= math.max(0, nLeftSecond)
    nLeftSecond = nLeftSecond - 5
    UIHelper.SetString(self.LabelNum, string.format("%s", nLeftSecond + 5))
    self.nTimerID = Timer.AddCountDown(self, nLeftSecond, function(deltaTime)
        UIHelper.SetString(self.LabelNum, string.format("%s", deltaTime + 5))
    end,function()
        self:PkGo()
    end)
    Timer.Add(self , 0.2 , function ()
        UIHelper.SetString(self.LabelNum, string.format("%s", nLeftSecond + 5))
        UIHelper.LayoutDoLayout(self.LayoutContentEditConfirm)
    end)
end

function UIChallengeConfirmPop:PkGo()
    RemoteCallToServer("On_PK_PkGo", self.dwPlayerID)
    UIMgr.Close(VIEW_ID.PanelArenaConfirmPop)
    Timer.DelTimer(self,self.nTimerID)
    local nLeftSecond = (self.nEndFrame - GetLogicFrameCount()) / GLOBAL.GAME_FPS
    nLeftSecond = math.ceil(nLeftSecond)
    nLeftSecond	= math.max(0, nLeftSecond)
    TipsHelper.PlayCountDown(nLeftSecond)
end

return UIChallengeConfirmPop