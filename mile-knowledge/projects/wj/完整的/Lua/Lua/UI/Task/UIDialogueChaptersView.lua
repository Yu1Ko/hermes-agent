-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIDialogueChaptersView
-- Date: 2022-11-29 19:18:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIDialogueChaptersView = class("UIDialogueChaptersView")

function UIDialogueChaptersView:OnEnter(dwChapterID, tTime1, tTime2, tTime3, tTime4, tTime5, nAlpha)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:InitData(dwChapterID, tTime1, tTime2, tTime3, tTime4, tTime5, nAlpha)
    self:UpdateInfo()
    UIMgr.HideLayer(UILayer.Main)
    UIMgr.HideLayer(UILayer.Page)

    SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.ChapterBG)
end

function UIDialogueChaptersView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    UIMgr.ShowLayer(UILayer.Main)
    UIMgr.ShowLayer(UILayer.Page)
end

function UIDialogueChaptersView:BindUIEvent()

end

function UIDialogueChaptersView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDialogueChaptersView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIDialogueChaptersView:InitData(dwChapterID, tTime1, tTime2, tTime3, tTime4, tTime5, nAlpha)
    self.dwChapterID = dwChapterID
    self.tTime1 = tTime1
    self.tTime2 = tTime2
    self.tTime2 = tTime2
    self.tTime3 = tTime3
    self.tTime4 = tTime4
    self.tTime5 = tTime5
    self.nAlpha = nAlpha
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDialogueChaptersView:UpdateInfo()
    local bStoryMode = DungeonData.IsStoryMode()
    if bStoryMode then
        UIHelper.SetString(self.LabelFirstContent1, "")
        UIHelper.SetString(self.LabelFirstContent2, "")
    else
        local tbChapterInfo = Table_GetChaptersInfo(self.dwChapterID)
        if tbChapterInfo then

            UIHelper.SetString(self.LabelFirst, UIHelper.GBKToUTF8(tbChapterInfo.szMobileTitle))
            UIHelper.SetTexture(self.ImgTitle, tbChapterInfo.szMobilePathTitle)
    
            local tbText = string.split(UIHelper.GBKToUTF8(tbChapterInfo.szNote),"，")
            UIHelper.SetString(self.LabelFirstContent1, tbText[1])
            UIHelper.SetString(self.LabelFirstContent2, tbText[2])
    
            local bShowStamp = tbChapterInfo.bShowStamp
            UIHelper.SetVisible(self.ImgEnd, bShowStamp)
            UIHelper.SetVisible(self.ImgBegin, not bShowStamp)
        end
    end

    UIHelper.SetVisible(self.LabelPartnerHint, bStoryMode)
    UIHelper.SetVisible(self.ImgPartnerHint, bStoryMode)

    UIHelper.SetVisible(self.ImgLeftTitle, not bStoryMode)
    UIHelper.SetVisible(self.ImgChapterLine03, not bStoryMode)
    UIHelper.SetVisible(self.ImgChapterLine04, not bStoryMode)

    UIHelper.PlayAni(self, self.AniAll, "AniPassageShow2", function()
        UIMgr.Close(self)
    end)
end


return UIDialogueChaptersView