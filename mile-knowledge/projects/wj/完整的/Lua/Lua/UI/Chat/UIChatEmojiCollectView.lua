-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatEmojiCollectView
-- Date: 2022-12-24 12:53:54
-- Desc: 聊天表情收藏
-- ---------------------------------------------------------------------------------

local UIChatEmojiCollectView = class("UIChatEmojiCollectView")

function UIChatEmojiCollectView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatEmojiCollectView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatEmojiCollectView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

end

function UIChatEmojiCollectView:RegEvent()
    Event.Reg(self, "REMOTE_EMOTION_FAVORITES_EVENT", function()
        self:UpdateInfo_Title()
    end)
end

function UIChatEmojiCollectView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatEmojiCollectView:UpdateInfo()
    self:UpdateInfo_Title()
    self:UpdateInfo_List()
end

function UIChatEmojiCollectView:UpdateInfo_Title()
    local tbFavoriteEmoji = ChatData.GetAllEmotionInFavorites()
    local nTotal = ChatData.GetEmotionFavoritesMaxCount()
    local szTitle = string.format("（%d/%d）", #tbFavoriteEmoji, nTotal)
    UIHelper.SetString(self.LabelNum, szTitle)
end

function UIChatEmojiCollectView:UpdateInfo_List()
    local tbGroupList = ChatData.GetChatEmojiGroupList(false)

    for k, v in ipairs(tbGroupList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetChatSettingToggle, self.ScrollViewLeftList)
        script:OnEnter(k, v.szGroupName, k == 1, nil, function()
            self:OnGroupSelected(v.nGroupID)
        end)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLeftList)
end

function UIChatEmojiCollectView:OnGroupSelected(nGroupID)
    UIHelper.RemoveAllChildren(self.ScrollView)
    local tbEmojiList = ChatData.GetEmojiOneGroupInfo(nGroupID)
    for _, v in ipairs(tbEmojiList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetChatEmojiCollectExpression, self.ScrollView)
        script:OnEnter(v)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollView)
end


return UIChatEmojiCollectView