-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatMiniCell
-- Date: 2022-12-14 20:07:22
-- Desc: mini聊天面板Cell
-- ---------------------------------------------------------------------------------

local UIChatMiniCell = class("UIChatMiniCell")
local tbPrefabList = {
    [1] = PREFAB_ID.WidgetChatMainCityCell2,
    [2] = PREFAB_ID.WidgetChatMainCityCell,
}

function UIChatMiniCell:OnEnter(nIndex, tbChatData, nMode)
    if nIndex == nil then
        return
    end

    self.nIndex = nIndex
    self.tbChatData = tbChatData
    self.nMode = nMode or Storage.ControlMode.nMode

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatMiniCell:BindUIEvent()

end

function UIChatMiniCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChatMiniCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatMiniCell:UpdateInfo()
    if not self.tbChatData then
        UIHelper.SetRichText(self.RichText, "")
        return
    end

    local szContent = self.tbChatData.szContent or ""
    local dwTalkerID = self.tbChatData.dwTalkerID
    local nChannel = self.tbChatData.nChannel
    local dwTitleID = self.tbChatData.dwTitleID or 0
    local szGlobalID = self.tbChatData.szGlobalID
    --local nPadding = ChatData.GetCellPadding(PREFAB_ID.WidgetChatMainCityCell)
    local nPadding = ChatData.GetCellPadding(tbPrefabList[self.nMode])
    local player = GetClientPlayer()
    local bIsSelf = (player and dwTalkerID == player.dwID) or (szGlobalID and APIHelper.IsSelfByGlobalID(szGlobalID))
    local nSourceType = self.tbChatData.nSourceType

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
            --szContent = string.is_nil(szTitle) and szContent or string.format("%s：%s", szTitle, szContent)
        else
            if not string.is_nil(szName) then -- 没有名字就不加称号
                -- 名字加门派颜色
                if IsNumber(dwForceID) and dwForceID > 0 then
                    if FORCE_TYPE_TO_COLOR[dwForceID] then
                        local szForceColor = FORCE_TYPE_TO_COLOR[dwForceID].szColor
                        szName = string.format("<color=%s>[%s]</color>", szForceColor, szName)
                    end
                else
                    szName = string.format("[%s]", szName)
                end

                if nSourceType and nSourceType == CHAT_SOURCE_TYPE.APP then
                    szName = szName .. "[来自推栏]"
                end

                szContent = string.is_nil(szTitle) and string.format("%s说：%s", szName, szContent) or string.format("%s%s说：%s", szTitle, szName, szContent)
            end
        end
	end

    -- 内容
    szContent = self:GetContent(nChannel, szContent, self.tbChatData.nTime, self.tbChatData.bRookieGM)
    local szRichText = ChatHelper.GetMiniChatRichText(szContent, nChannel)
    UIHelper.SetWidth(self.RichText, self.nWidth)
    UIHelper.SetRichText(self.RichText, szRichText)
    UIHelper.SetRichTextCanClick(self.RichText, false)

    UIHelper.SetHeight(self.WidgetRoot, UIHelper.GetHeight(self.RichText) + nPadding)
    UIHelper.WidgetFoceDoAlign(self)
end

function UIChatMiniCell:SetWidth(nWidth)
    self.nWidth = nWidth
end

function UIChatMiniCell:GetContent(nChannelID, szContent, nTime, bRookieGM)
    local szKey = "Mini_Channel_"..tostring(nChannelID)
    local szTime = ChatHelper.ConvertChatTime(nTime, true, true)
    local szColor = UI_Chat_Color[szKey]

    if string.is_nil(szColor) then
        if ChatData.IsGMChannel(nChannelID) then
            szColor = UI_Chat_Color.GM
        end
    end

    if bRookieGM then
        szColor = UI_Chat_Color.GM
    end

    if string.is_nil(szColor) then
        szContent = szTime .. szContent
    else
        szContent = string.format("<color=%s>%s%s</color>", szColor, szTime, szContent)
    end

    return szContent
end


return UIChatMiniCell

