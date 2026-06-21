-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICommonActivityLetterView
-- Date: 2026-01-26 17:32:03
-- Desc: ?
-- ---------------------------------------------------------------------------------
local UICommonActivityLetterView = class("UICommonActivityLetterView")

function UICommonActivityLetterView:OnEnter(dwID)
    self.dwID = dwID
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UICommonActivityLetterView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICommonActivityLetterView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UICommonActivityLetterView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICommonActivityLetterView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end





--RemoteCallToClient(player.dwID, "OpenGeneralInvitation", 3)
-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UICommonActivityLetterView:EncodeString(szText)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return szText
    end
    local tbContentList = {}
    local nMaxLen = 27

    szText = string.gsub(szText, "%[PlayerName%]", UIHelper.GBKToUTF8(hPlayer.szName))
    szText = string.gsub(szText, "\t", " ")
    local tbLines = string.split(szText, "\n")

    for _, szLine in ipairs(tbLines) do
        if UIHelper.GetUtf8Len(szLine) <= nMaxLen then
            table.insert(tbContentList, szLine)
        else
            local nStart = 1
            while nStart <= UIHelper.GetUtf8Len(szLine) do
                local szSub = UIHelper.GetUtf8SubString(szLine, nStart, nMaxLen)
                table.insert(tbContentList, szSub)
                nStart = nStart + nMaxLen
            end
        end
    end

    return tbContentList
end

function UICommonActivityLetterView:UpdateInfo()
    local tInfo = Table_GetCustomInvitation(self.dwID)
    if not tInfo then
        return
    end

    local tbContentList = self:EncodeString(UIHelper.GBKToUTF8(tInfo.szContent))
    for i, node in ipairs(self.tbLetterContent) do
        local szContent = tbContentList[i]
        if szContent then
            local PLACEHOLDER = "\1"
            szContent = string.gsub(szContent, "([%w\128-\255]) (%s*[%w\128-\255])", "%1" .. PLACEHOLDER .. "%2")
            szContent = string.gsub(szContent, " ", "\n")
            szContent = string.gsub(szContent, PLACEHOLDER, "\n\n")
            UIHelper.SetString(node, szContent)
            UIHelper.SetVisible(node, true)
        else
            UIHelper.SetVisible(node, false)
        end
    end

    UIHelper.SetVisible(self.LabelTitle, false)
    UIHelper.SetVisible(self.LabelTitle2, false)
    UIHelper.PlayAni(self, self.AniAll, "AniYuanXiaoJieShow1")
end


return UICommonActivityLetterView