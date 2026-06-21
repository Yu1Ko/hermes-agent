-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIChatSettingAutoShoutCell
-- Date: 2024-10-12 15:48:34
-- Desc: ?
-- ---------------------------------------------------------------------------------
local CONTENT_TYPE = {
    SHOUT = 1,
    CHANNEL = 2,
}

local TYPE_TO_NAME = {
    [CONTENT_TYPE.SHOUT] = "喊话内容",
    [CONTENT_TYPE.CHANNEL] = "发布频道",
}

local UIChatSettingAutoShoutCell = class("UIChatSettingAutoShoutCell")

function UIChatSettingAutoShoutCell:OnEnter(nType, tbInfo)
    self.nType = nType
    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatSettingAutoShoutCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatSettingAutoShoutCell:BindUIEvent()
    
end

function UIChatSettingAutoShoutCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChatSettingAutoShoutCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatSettingAutoShoutCell:UpdateInfo()
    self:UpdateTitle()
    self:UpdateContent()
end

function UIChatSettingAutoShoutCell:UpdateTitle()
    local szTittle = TYPE_TO_NAME[self.nType]
    UIHelper.SetString(self.LabelTypeTittle, szTittle)
end

function UIChatSettingAutoShoutCell:UpdateContent()
    local szContent = self:ParseSettingData()
    UIHelper.SetRichText(self.LabelContent, szContent)

    local nRichTextHeight = UIHelper.GetHeight(self.LabelContent)
    UIHelper.SetHeight(self._rootNode, nRichTextHeight)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIChatSettingAutoShoutCell:ParseSettingData()
    local szContent = ""
    if self.nType == 1 then
        szContent = self.tbInfo[1]
    elseif self.nType == 2 then
        local bHasApplyChannel = false
        local tbApplyChannelList = self.tbInfo[CONTENT_TYPE.CHANNEL]
        local tbChannelList = ChatAutoShout.GetChannelList()
        for i = 1, #tbChannelList, 1 do
            table.find_if(tbChannelList[i].tbChannelID, function(v)
                if table.contain_value(tbApplyChannelList, v) then
                    local szTitle = tbChannelList[i].szTitle
                    if szContent == "" then
                        szContent = szTitle
                    else
                        szContent = szContent .. "、" .. szTitle
                    end
                    bHasApplyChannel = true
                    return true
                end
            end)
        end

        szContent = bHasApplyChannel and szContent or "不发布"
    end

    return szContent
end

return UIChatSettingAutoShoutCell