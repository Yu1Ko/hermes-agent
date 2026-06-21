-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatSwitchChannelTip
-- Date: 2023-11-29 11:21:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChatSwitchChannelTip = class("UIChatSwitchChannelTip")

function UIChatSwitchChannelTip:OnEnter(szType)
    self.szType = szType

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatSwitchChannelTip:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatSwitchChannelTip:BindUIEvent()

end

function UIChatSwitchChannelTip:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChatSwitchChannelTip:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatSwitchChannelTip:UpdateInfo()
    if self.szType == UI_Chat_Switch_Type.Mini then
        self:UpdateInfo_Mini()
        self:UpdateInfo_MiniChatSyncState()
    else
        self:UpdateInfo_All()
    end
end


function UIChatSwitchChannelTip:UpdateInfo_Mini()
    UIHelper.SetVisible(self.WidgetBigMoreTip, true)

    local tbChannelList = ChatData.GetUIChannelList()

    local lastScript = nil
    local nCount = 0
    local nOneHeight = 60
    for _, tbOneChannel in ipairs(tbChannelList) do
        local szUIChannel = tbOneChannel.szUIChannel
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetChatSwitchCell, self.ScrollViewBigTip)
        nOneHeight = UIHelper.GetHeight(script._rootNode)
        UIHelper.SetVisible(script.imgSelect, szUIChannel == ChatData.GetMiniDisplayChannel())
        UIHelper.SetString(script.LabelChat, ChatData.GetUIChannelNickName(szUIChannel))
        UIHelper.BindUIEvent(script.BtnChatChannel, EventType.OnClick, function()
            if szUIChannel ~= ChatData.GetMiniDisplayChannel() then
                ChatData.SetMiniDisplayChannel(szUIChannel)
                Event.Dispatch(EventType.OnChatMiniChannelSelected, szUIChannel)
            end
            TipsHelper.DeleteAllHoverTips()
        end)

        lastScript = script
        nCount = nCount + 1
    end

    if not ChatSetting.bMiniChatSwitchScrollEnable or nCount < 7 then
        UIHelper.SetHeight(self.ScrollViewBigTip, nCount * nOneHeight)
        UIHelper.SetHeight(self.ImgBigTip, nCount * nOneHeight)
    end

    -- 隐藏最后的那根线
    if lastScript then
        UIHelper.SetVisible(lastScript.imgChatBtnLine, false)
    end
end

function UIChatSwitchChannelTip:UpdateInfo_MiniChatSyncState()
    local funcBind = function()
        local szUIChannel = ChatData.GetMiniDisplayChannel()
        ChatData.SetRuntimeSelectDisplayChannel(szUIChannel)
    end
    -- UIHelper.SetVisible(self.BtnLockTab, false)
    ChatHelper.Update_MiniChatSyncState(self.BtnLockTab, self.imgLockTab, self.imgLockTab1, not self.bSysBtnBinded, funcBind)
    self.bSysBtnBinded = true
end

function UIChatSwitchChannelTip:UpdateInfo_All()
    UIHelper.SetVisible(self.WidgetBigMoreTip, true)

    UIHelper.RemoveAllChildren(self.ScrollViewBigTip)

    local lastScript = nil
    local nCount = 0
    local nOneHeight = 60
    for _, nChannelID in ipairs(ChatSetting.tbSendChannelIDList) do
        local tbDisplayFlagConf = ChatData.GetChatFlagConfByChannelID(nChannelID)
        if tbDisplayFlagConf then
            local szName = tbDisplayFlagConf.szName
            local bFlag = ChatData.IsSendChannelVisible(nChannelID)
            if bFlag then
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetChatSwitchCell, self.ScrollViewBigTip)
                nOneHeight = UIHelper.GetHeight(script._rootNode)
                UIHelper.SetVisible(script.imgSelect, nChannelID == ChatData.GetSendChannelID())
                UIHelper.SetString(script.LabelChat, ChatData.GetChannelNickName(szName))
                UIHelper.BindUIEvent(script.BtnChatChannel, EventType.OnClick, function()
                    ChatData.SetSendChannelID(nil, nChannelID)
                    TipsHelper.DeleteAllHoverTips()
                end)

                lastScript = script
                nCount = nCount + 1
            end
        end
    end

    if not ChatSetting.bSendChannelScrollEnable or nCount < 7 then
        UIHelper.SetHeight(self.ScrollViewBigTip, nCount * nOneHeight)
        UIHelper.SetHeight(self.ImgBigTip, nCount * nOneHeight)
    end

    -- 隐藏最后的那根线
    if lastScript then
        UIHelper.SetVisible(lastScript.imgChatBtnLine, false)
    end

    UIHelper.WidgetFoceDoAlign(self)
end

return UIChatSwitchChannelTip