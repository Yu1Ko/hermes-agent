-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatEmojiCollectGroup
-- Date: 2022-12-24 16:47:01
-- Desc: 表情收藏分组
-- ---------------------------------------------------------------------------------

local UIChatEmojiCollectGroup = class("UIChatEmojiCollectGroup")

function UIChatEmojiCollectGroup:OnEnter(tbGroupConf)
    self.tbGroupConf = tbGroupConf

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatEmojiCollectGroup:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatEmojiCollectGroup:BindUIEvent()
    
end

function UIChatEmojiCollectGroup:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChatEmojiCollectGroup:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatEmojiCollectGroup:UpdateInfo()
    local nGroupID = self.tbGroupConf.nGroupID
    local szGroupName = self.tbGroupConf.szGroupName

    UIHelper.SetString(self.LabelOptionTitle, szGroupName)


    local tbEmojiList = ChatData.GetEmojiOneGroupInfo(nGroupID)
    for _, v in ipairs(tbEmojiList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetChatEmojiCollectExpression, self.LayoutContent)
        script:OnEnter(v)
    end

    UIHelper.LayoutDoLayout(self.LayoutContent)
    UIHelper.LayoutDoLayout(self.Layout)
end


return UIChatEmojiCollectGroup