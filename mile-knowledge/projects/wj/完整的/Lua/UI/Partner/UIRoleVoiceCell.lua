-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIRoleVoiceCell
-- Date: 2023-04-06 14:49:55
-- Desc: 侠客-传记条目
-- Prefab: WidgetRoleVoiceCell
-- ---------------------------------------------------------------------------------

local TYPE            = {
    --- 语音
    VOICE = "Voice",
    --- 传记
    STORY = "Story",
}

local UIRoleVoiceCell = class("UIRoleVoiceCell")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIRoleVoiceCell:_LuaBindList()
    self.TogRoleVoice           = self.TogRoleVoice --- 已解锁时的选中toggle
    self.LabelContent           = self.LabelContent --- 已解锁时的文本（未选中）
    self.BtnRoleVoiceUnunlocked = self.BtnRoleVoiceUnunlocked --- 未解锁时的最顶层组件

    self.LabelContentLocked     = self.LabelContentLocked --- 未解锁时的文本
    self.LabelContentSelected   = self.LabelContentSelected --- 已解锁时的文本（选中）

    self.ImgMemoirist           = self.ImgMemoirist --- 传记图标（未选中）
    self.ImgMemoiristSelected   = self.ImgMemoiristSelected --- 传记图标（选中）
    self.WidgetIcon             = self.WidgetIcon --- 语音动画的节点（未选中）
    self.WidgetIconSelected     = self.WidgetIconSelected --- 语音动画的节点（选中）
end

function UIRoleVoiceCell:OnEnter(dwID, szType, tInfo)
    self.dwID   = dwID
    --- 专辑类型 Voice / Story
    self.szType = szType
    self.tInfo  = tInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIRoleVoiceCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRoleVoiceCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogRoleVoice, EventType.OnClick, function()
        if self.szType == TYPE.VOICE and self.tInfo.bHave then
            self:PlayPartnerVoice()
        end

        if self.fnOnClick then
            self.fnOnClick()
        end
    end)

    UIHelper.BindUIEvent(self.BtnRoleVoiceUnunlocked, EventType.OnClick, function()
        TipsHelper.ShowNormalTip("达成解锁条件后方可解锁")
    end)
end

function UIRoleVoiceCell:RegEvent()
    Event.Reg(self, "PLAY_SOUND_FINISHED", function()
        if self.nSoundID and arg0 == self.nSoundID then
            UIHelper.StopAllAni(self)
            UIHelper.PlayAni(self, self.WidgetIcon, "AniStop")
            UIHelper.PlayAni(self, self.WidgetIconSelected, "AniStop")
		end
    end)

    Event.Reg(self, "SYNC_SOUND_ID", function()
        local tVoiceInfo        = self.tInfo or {}
        local szVoiceFilePath   = tVoiceInfo.szPath
        if szVoiceFilePath and arg1 == szVoiceFilePath then
            Partner_SetPlayingSoundID(dwSoundID)
			self.nSoundID = arg0
		end
    end)
end

function UIRoleVoiceCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRoleVoiceCell:UpdateInfo()
    local bHave = self.tInfo.bHave

    UIHelper.SetVisible(self.TogRoleVoice, bHave)
    UIHelper.SetVisible(self.BtnRoleVoiceUnunlocked, not bHave)

    if bHave then
        UIHelper.SetToggleGroupIndex(self.TogRoleVoice, ToggleGroupIndex.PartnerRoleVoiceCell)
    else
        local nOpenLevel = self.tInfo.nOpenLevel
        local szTip      = FormatString(g_tStrings.STR_PARTNER_ATTRACTION_LOCK_TIP, g_tStrings.STR_PARTNER_ATTRACTION_LEVEL[nOpenLevel])
        local dwQuestID  = self.tInfo.dwQuestID
        if dwQuestID ~= 0 then
            local tQuestInfo = Table_GetQuestStringInfo(dwQuestID)
            if tQuestInfo then
                local szQuestTip = FormatString(g_tStrings.STR_PARTNER_FINISH_QUEST_TIP, UIHelper.GBKToUTF8(tQuestInfo.szName))
                szTip            = szTip .. szQuestTip
            end
        end
        szTip = szTip .. g_tStrings.STR_PARTNER_VOICE_UNLOCK

        UIHelper.SetString(self.LabelContentLocked, szTip)
    end

    local bIsStory = self.szType == TYPE.STORY

    UIHelper.SetVisible(self.ImgMemoirist, bIsStory)
    UIHelper.SetVisible(self.ImgMemoiristSelected, bIsStory)

    UIHelper.SetVisible(self.WidgetIcon, not bIsStory)
    UIHelper.SetVisible(self.WidgetIconSelected, not bIsStory)

    if self.szType == TYPE.STORY then
        self:UpdateStoryInfo()
    else
        self:UpdateVoiceInfo()
    end
end

function UIRoleVoiceCell:UpdateStoryInfo()
    if self.tInfo.bHave then
        local szTitle = UIHelper.GBKToUTF8(self.tInfo.szTitle)
        UIHelper.SetString(self.LabelContent, szTitle)
        UIHelper.SetString(self.LabelContentSelected, szTitle)
    end
end

local MAX_DESCRIPTION_SHOW_LENGTH = 15
local MAX_DESCRIPTION_TRUNCATION  = "..."

function UIRoleVoiceCell:UpdateVoiceInfo()
    if self.tInfo.bHave then
        local szFullDescription, szDescription = self:GetVoiceFullDescriptionAndShowDescription()

        UIHelper.SetString(self.LabelContent, szDescription)
        UIHelper.SetString(self.LabelContentSelected, szDescription)
    end
end

function UIRoleVoiceCell:GetVoiceFullDescriptionAndShowDescription()
    local szFullDescription = UIHelper.GBKToUTF8(self.tInfo.szDesc)
    -- 超过15字显示省略号
    local _, szDescription = UIHelper.TruncateString(szFullDescription, MAX_DESCRIPTION_SHOW_LENGTH, MAX_DESCRIPTION_TRUNCATION)

    return szFullDescription, szDescription
end

function UIRoleVoiceCell:PlayPartnerVoice()
    local tVoiceInfo        = self.tInfo
    local szVoiceFilePath   = tVoiceInfo.szPath
    local dwLastPlaySoundID = Partner_GetLastPlaySoundID()
    if dwLastPlaySoundID then
        SoundMgr.StopSound(dwLastPlaySoundID, true)
    end
    Partner_SetPlayingSoundPath(szVoiceFilePath)
    SoundMgr.PlaySound(SOUND.CHARACTER_SPEAK, szVoiceFilePath, nil, true)

    UIHelper.StopAllAni(self)
    UIHelper.PlayAni(self, self.WidgetIcon, "AniPlay")
    UIHelper.PlayAni(self, self.WidgetIconSelected, "AniPlay")
end

function UIRoleVoiceCell:SetFnOnClick(fnOnClick)
    self.fnOnClick = fnOnClick
end

return UIRoleVoiceCell