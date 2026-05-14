-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIChatSettingAutoShoutEditbox
-- Date: 2024-10-14 15:03:05
-- Desc: ?
-- ---------------------------------------------------------------------------------
local TAG_TO_LEN = 1
local MAX_INPUT_CHAR_NUM = 50
local UIChatSettingAutoShoutEditbox = class("UIChatSettingAutoShoutEditbox")

function UIChatSettingAutoShoutEditbox:OnEnter(szType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIChatSettingAutoShoutEditbox:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatSettingAutoShoutEditbox:BindUIEvent()
    UIHelper.RegisterEditBoxChanged(self.EditBoxSendNormal, function(szText)
        self:UpdateLimitInfo()
    end)
end

function UIChatSettingAutoShoutEditbox:RegEvent()
    -- Event.Reg(self, EventType.XXX, func)
end

function UIChatSettingAutoShoutEditbox:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIChatSettingAutoShoutEditbox:GetParseText(szText)
    local nIndex = 0
    local tbTagList = ChatAutoShout.GetTagList("All")

    -- 标签处理
    for index, szTag in ipairs(tbTagList) do
        local ss = "@"..szTag
        szText = string.gsub(szText, ss, "@")
    end

    -- 表情处理
    for nBeginIndex, nEndIndex in function() return string.find(szText, "%b[]", nIndex) end do
        -- 先找出标签所在位置
        local szLabel = string.sub(szText, nBeginIndex + 1, nEndIndex - 1)
        if string.find(szLabel, "#", 1, true) == 1 then
            if ChatData.GetEmojiConfByName(szLabel) then
                szText = string.gsub(szText, szLabel, "")
            end
        end
        nIndex = nEndIndex + 1
    end

    return szText
end

local _tUtf8Mask = { 0, 0xc0, 0xe0, 0xf0 }
function UIChatSettingAutoShoutEditbox:UpdateLimitInfo()
    local szEditText = UIHelper.GetText(self.EditBoxSendNormal)
    local szText = szEditText   -- 用于特殊处理标签和表情字数
    if string.is_nil(szText) then
        UIHelper.SetString(self.LabelLimit, string.format("%d/%d", 0, MAX_INPUT_CHAR_NUM))
        return
    end
    szText = self:GetParseText(szText)
    local nLeft = string.len(szText)
    local nLen = 0
    while nLeft > 0 do
        local code = string.byte(szText, -nLeft)
        for i = 4, 1, -1 do
            if code >= _tUtf8Mask[i] then
                nLeft = nLeft - i
                break
            end
        end
        nLen = nLen + 1
        if nLen >= MAX_INPUT_CHAR_NUM then
            szEditText = string.sub(szEditText, 1, #szText - nLeft)
            UIHelper.SetText(self.EditBoxSendNormal, szEditText)
            nLeft = - 1 -- 退出
        end
    end
    UIHelper.SetString(self.LabelLimit, string.format("%d/%d", nLen, 50))
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIChatSettingAutoShoutEditbox:RegisterEditBox(fnCallBack)
    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditBoxSendNormal, fnCallBack)
    else
        UIHelper.RegisterEditBoxReturn(self.EditBoxSendNormal, fnCallBack)
    end
end

function UIChatSettingAutoShoutEditbox:SetCurGroupType(szType)
    self.szType = szType
end

function UIChatSettingAutoShoutEditbox:SetPlaceHolder(szText)
    UIHelper.SetPlaceHolder(self.EditBoxSendNormal, szText)
end

function UIChatSettingAutoShoutEditbox:SetOverflow(nLabelOverflow)
    UIHelper.SetOverflow(self.PLACEHOLDER_LABEL, nLabelOverflow)
end

function UIChatSettingAutoShoutEditbox:SetHorizontalAlignment(nAlign)
    UIHelper.SetHorizontalAlignment(self.PLACEHOLDER_LABEL, nAlign)
end

function UIChatSettingAutoShoutEditbox:SetEditBox(szText)
    UIHelper.SetText(self.EditBoxSendNormal, szText)
    self:UpdateLimitInfo()
end

function UIChatSettingAutoShoutEditbox:GetEditBox()
    return UIHelper.GetText(self.EditBoxSendNormal)
end

function UIChatSettingAutoShoutEditbox:AddTagToEditbox(szTag)
    local szText = UIHelper.GetText(self.EditBoxSendNormal)
    szText = szText .. szTag
    UIHelper.SetText(self.EditBoxSendNormal, szText)
    self:UpdateLimitInfo()
end

return UIChatSettingAutoShoutEditbox