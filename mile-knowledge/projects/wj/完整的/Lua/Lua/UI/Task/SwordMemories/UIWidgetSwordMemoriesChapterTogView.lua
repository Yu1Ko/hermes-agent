-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSwordMemoriesChapterTogView
-- Date: 2023-09-11 17:00:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSwordMemoriesChapterTogView = class("UIWidgetSwordMemoriesChapterTogView")

function UIWidgetSwordMemoriesChapterTogView:OnEnter(tbChapterInfo, scriptParent, bSelect, bBookAtlas)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbChapterInfo = tbChapterInfo
    self.scriptParent = scriptParent
    self.bSelect = bSelect
    self.bBookAtlas = bBookAtlas
    self:UpdateInfo()
end

function UIWidgetSwordMemoriesChapterTogView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSwordMemoriesChapterTogView:BindUIEvent()
    UIHelper.BindUIEvent(self.TogChapter, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self.scriptParent:SetCurChapter(self.tbChapterInfo)
        end
    end)
end

function UIWidgetSwordMemoriesChapterTogView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSwordMemoriesChapterTogView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSwordMemoriesChapterTogView:UpdateInfo()
    if self.bBookAtlas then
        UIHelper.SetVisible(self.ImgFinishedNormal, not self.tbChapterInfo.bLock)
        UIHelper.SetVisible(self.ImgFinished1, not self.tbChapterInfo.bLock)
        UIHelper.SetVisible(self.LabelProgressNormal, not self.tbChapterInfo.bLock)
        UIHelper.SetVisible(self.LabelProgressNormal1, not self.tbChapterInfo.bLock)
        UIHelper.SetString(self.LabelChapterNameNormal, UIHelper.GBKToUTF8(self.tbChapterInfo.szTitle))
        UIHelper.SetString(self.LabelChapterNameNormal1, UIHelper.GBKToUTF8(self.tbChapterInfo.szTitle))
        UIHelper.SetString(self.LabelProgressNormal, UIHelper.GBKToUTF8(self.tbChapterInfo.szTime))
        UIHelper.SetString(self.LabelProgressNormal1, UIHelper.GBKToUTF8(self.tbChapterInfo.szTime))
        return
    end

    local szText = UIHelper.GBKToUTF8(self.tbChapterInfo.szName)
    UIHelper.SetString(self.LabelChapterNameNormal, szText, 7)
    UIHelper.SetString(self.LabelChapterNameNormal1, szText, 7)

    local nCount, nTotal = SwordMemoriesData.GetSectionFinishedCount(self.tbChapterInfo.dwID)
    local szProgress = string.format("小节：%s/%s", tostring(nCount), tostring(nTotal))
    UIHelper.SetString(self.LabelProgressNormal, szProgress)
    UIHelper.SetString(self.LabelProgressNormal1, szProgress)
    UIHelper.SetVisible(self.ImgFinishedNormal, nCount == nTotal)
    UIHelper.SetVisible(self.ImgFinished1, nCount == nTotal)


    if self.bSelect then
        self:DelaySelect()
    end
    UIHelper.SetVisible(self._rootNode, true)
end

function UIWidgetSwordMemoriesChapterTogView:DelaySelect()
    self:UnDelaySelect()
    self.nSelectTimer = Timer.AddFrame(self, 1, function()
        UIHelper.SetSelected(self.TogChapter, true)
    end)
end

function UIWidgetSwordMemoriesChapterTogView:UnDelaySelect()
    if self.nSelectTimer then
        Timer.DelTimer(self, self.nSelectTimer)
        self.nSelectTimer = nil
    end
end


return UIWidgetSwordMemoriesChapterTogView