-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatMiniHintCell
-- Date: 2024-06-21 19:44:59
-- Desc: 迷你面板的提示
-- ---------------------------------------------------------------------------------

local UIChatMiniHintCell = class("UIChatMiniHintCell")

function UIChatMiniHintCell:OnEnter(tbChatData, nWidth)
    self.tbChatData = tbChatData
    self.nWidth = nWidth

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatMiniHintCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatMiniHintCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        local nHintIndex = self.tbChatData and self.tbChatData.nHintIndex
        if nHintIndex then
            ChatHintMgr.RemoveDataByIndex(nHintIndex)
        end
    end)

    UIHelper.BindUIEvent(self.BtnInfo, EventType.OnClick, function()
        local nChannel = self.tbChatData and self.tbChatData.nChannel
        if nChannel then
            local szUIChannel = ChatHintMgr.GetUIChannel(nChannel)
            if szUIChannel == UI_Chat_Channel.Whisper then
                ChatRecentMgr.SetCurWhisperPlayerName(self.tbChatData.szName)
                UIMgr.Open(VIEW_ID.PanelChatSocial, 1, szUIChannel)
            else
                UIMgr.Open(VIEW_ID.PanelChatSocial, 1, szUIChannel)
            end
        end
    end)
end

function UIChatMiniHintCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChatMiniHintCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIChatMiniHintCell:UpdateInfo()
    if not self.tbChatData then
        UIHelper.SetRichText(self.RichText, "")
        return
    end

    local szContent = self.tbChatData.szContent or ""
    local dwTalkerID = self.tbChatData.dwTalkerID
    local nChannel = self.tbChatData.nChannel
    local dwTitleID = self.tbChatData.dwTitleID or 0
    local nPadding =0
    local player = GetClientPlayer()
    local bIsSelf = (player and dwTalkerID == player.dwID)

    local szName = bIsSelf and GBKToUTF8(player.szName) or self.tbChatData.szName
    if not IsString(szName) then szName = "" end

    local dwForceID = bIsSelf and player.dwForceID or self.tbChatData.dwForceID

	if (IsNumber(dwTalkerID) and dwTalkerID > 0) or (not string.is_nil(dwTalkerID)) then
		local szTitle = ""
		if dwTitleID > 0 then
			local tbPrefix = UIHelper.GetDesignationInfoByTitleID(dwTitleID, dwForceID)
            if tbPrefix then
                local nQuality = tbPrefix.nQuality or 0
                local szColor = ItemQualityColor[nQuality + 1]
                local szTitleName = tbPrefix.szName and GBKToUTF8(tbPrefix.szName) or ""
                szTitle = string.format("<color=%s>[%s]</color>", szColor, szTitleName)
            end
		end

        if ChatData.IsSystemChannel(nChannel) then
            szContent = string.is_nil(szTitle) and szContent or string.format("%s：%s", szTitle, szContent)
        else
            if not string.is_nil(szName) then -- 没有名字就不加称号
                szContent = string.is_nil(szTitle) and string.format("%s：%s", szName, szContent) or string.format("%s%s：%s", szTitle, szName, szContent)
            end
        end
	end

    -- 内容
    szContent = self:GetContent(nChannel, szContent, self.tbChatData.nTime)
    local szRichText = ChatHelper.GetMiniChatRichText(szContent, nChannel)
    --UIHelper.SetWidth(self.RichText, self.nWidth)
    UIHelper.SetRichText(self.RichText, szRichText)
    UIHelper.SetRichTextCanClick(self.RichText, false)

    if not self.tbChatData.nHintDisplayTime then
        self.tbChatData.nHintDisplayTime = GetCurrentTime()
    end

    -- UIHelper.SetHeight(self.WidgetRoot, UIHelper.GetHeight(self.RichText) + nPadding)
    -- UIHelper.WidgetFoceDoAlign(self)

    self:PlayAnim()
end

function UIChatMiniHintCell:SetWidth(nWidth)
    self.nWidth = nWidth
end

function UIChatMiniHintCell:GetContent(nChannelID, szContent, nTime)
    local szKey = "Mini_Channel_"..tostring(nChannelID)
    local szTime = ChatHelper.ConvertChatTime(nTime, true, true)
    local szColor = UI_Chat_Color[szKey]

    if string.is_nil(szColor) then
        if ChatData.IsGMChannel(nChannelID) then
            szColor = UI_Chat_Color.GM
        end
    end

    if string.is_nil(szColor) then
        szContent = szTime .. szContent
    else
        szContent = string.format("<color=%s>%s%s</color>", szColor, szTime, szContent)
    end

    return szContent
end

function UIChatMiniHintCell:PlayAnim()
    if not self.tbChatData then return end

    local bHasPlayAnim = self.tbChatData.bHasPlayAnim
    if not bHasPlayAnim then
        UIHelper.SetVisible(self.Eff_SiLiaoTip, false)
        UIHelper.SetVisible(self.Eff_SiLiaoTip, true)
        self.tbChatData.bHasPlayAnim = true
    else
        UIHelper.SetVisible(self.Eff_SiLiaoTip, false)
    end
end


return UIChatMiniHintCell