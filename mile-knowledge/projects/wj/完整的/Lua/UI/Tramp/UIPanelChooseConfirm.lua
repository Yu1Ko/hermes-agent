-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelChooseConfirm
-- Date: 2023-04-10 19:33:51
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelChooseConfirm = class("UIPanelChooseConfirm")

function UIPanelChooseConfirm:OnEnter(bNewSave, bNumError, tPlayerState)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bNewSave, self.bNumError, self.tPlayerState = bNewSave, bNumError, tPlayerState
    self:UpdateInfo()
end

function UIPanelChooseConfirm:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelChooseConfirm:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function(btn)
        if VagabondData.GetCanStart() then
            local nCurrentID = VagabondData.GetCurrentID()
            local nPlayerNum = VagabondData.GetPlayerNum()
            local bNewSave = VagabondData.GetNewSave()
            RemoteCallToServer("On_LangKeXing_Sure", nCurrentID, nPlayerNum, bNewSave)
            UIMgr.Close(VIEW_ID.PanelChooseLv)
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCalloff, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UIPanelChooseConfirm:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelChooseConfirm:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelChooseConfirm:UpdateInfo()
    VagabondData.UpdateTipWndMsg(self.bNewSave, self.tPlayerState)
    self:UpdateInfo_Title()
    self:UpdateInfo_Players()
    self:UpdateInfo_BtnState()
end

function UIPanelChooseConfirm:UpdateInfo_Title()
    local tbPlayerState = VagabondData.GetPlayerState()
    if VagabondData.GetNewSave() then
        UIHelper.SetRichText(self.LabelHint, FormatString(g_tStrings.STR_LKX_NEW_START_TIP, #tbPlayerState))
    else
        UIHelper.SetRichText(self.LabelHint, FormatString(g_tStrings.STR_LKX_RESUME_TIP, VagabondData.GetPlayerNum()))
    end
end

function UIPanelChooseConfirm:UpdateInfo_Players()
    local tbPlayerState = VagabondData.GetPlayerState()
    local szText = ""
    for index, tInfo in ipairs(tbPlayerState) do
        local szColor = tInfo.szErrorType == "NoLimit" and "#a7fbaf" or "#ff7676"
        local szPlayer = string.format("<color=#ffffff>%s</c><color=%s>%s</color>", UIHelper.GBKToUTF8(tInfo.szName), szColor, g_tStrings.STR_LIMIT_TIP[tInfo.szErrorType])
        local szNewLine = index == 1 and "" or "\n"
        szText = szText..szNewLine..szPlayer
    end
    UIHelper.SetVisible(self.WidgetOneName, #tbPlayerState == 1)
    UIHelper.SetVisible(self.LayoutNameMore, #tbPlayerState > 1)
    UIHelper.SetRichText(self.RichTextName, szText)
    UIHelper.SetRichText(self.RichTextNameMore, szText)
    UIHelper.LayoutDoLayout(self.LayoutNameMore)
end

function UIPanelChooseConfirm:UpdateInfo_BtnState()
    local bCanStart = VagabondData.GetCanStart()
    UIHelper.SetVisible(self.BtnCalloff, bCanStart)
    UIHelper.SetString(self.LabelOk, bCanStart and "确认" or "确定并退出")
end


return UIPanelChooseConfirm