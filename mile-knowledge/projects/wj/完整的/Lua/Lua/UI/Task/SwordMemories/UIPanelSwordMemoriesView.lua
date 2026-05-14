-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelSwordMemoriesView
-- Date: 2023-09-11 15:56:52
-- Desc: ?
-- ---------------------------------------------------------------------------------
local IMG_CLOSE = "UIAtlas2_Public_PublicButton_PublicButton1_btn_Close"
local IMG_RETURN = "UIAtlas2_Public_PublicButton_PublicButton1_btn_return_Other"

local UIPanelSwordMemoriesView = class("UIPanelSwordMemoriesView")

function UIPanelSwordMemoriesView:OnEnter(nChapterID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init(nChapterID)
end

function UIPanelSwordMemoriesView:OnVisible()
    -- if not self.bScrollViewDoLayout then
    --     Timer.AddFrame(self, 1, function()
    --         UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewChapterContent)
    --     end)
    --     self.bScrollViewDoLayout = true
    -- end
end

function UIPanelSwordMemoriesView:OnExit()
    SwordMemoriesData.ShowAllSection(false)
    self.bInit = false
    self:UnRegEvent()
    -- SwordMemoriesData.UnInit()
end

function UIPanelSwordMemoriesView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        if self.bVerSionList then
            UIMgr.Close(self)
        else
            self:BackToVersionList()
        end
    end)
    if self.BtnStop then
        UIHelper.BindUIEvent(self.BtnStop, EventType.OnClick, function()
            SwordMemoriesData.StopSound()
        end)
    end

    for nIndex, toggle in ipairs(self.tbTogVersionList) do
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(_, bSelect)
            if bSelect then
                self:SetCurSeason(nIndex, true)
            end
        end)
    end
    UIHelper.BindUIEvent(self.BtnWulintongjian, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelWuLinTongJian)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnStop, EventType.OnClick, function()
        SwordMemoriesData.StopSound()
    end)
end

function UIPanelSwordMemoriesView:RegEvent()
    Event.Reg(self, EventType.OnSwordMemoriesSoundChanged, function()
        self:UpdateBtnStopPlay()
    end)
end

function UIPanelSwordMemoriesView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelSwordMemoriesView:Init(nChapterID)
    -- self.tbScriptCharpter = {}
    -- self.tbScriptSection = {}
    -- SwordMemoriesData.Init()
    self.nDefaultChapterID = nChapterID
    self.nDefaultSeasonID = SwordMemoriesData.GetSectionIDByChapterID(nChapterID)
    self:InitUI()
    if self.nDefaultSeasonID then
        self:SetCurSeason(self.nDefaultSeasonID, true, self.nDefaultChapterID)
    else
        self:BackToVersionList()
    end
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelSwordMemoriesView:InitUI()
    for nIndex, nSeasonID in ipairs(SWORDMEMORIY_SEASONIDLIST) do
        local nOffSet = nSeasonID % 2 == 0 and 0 or 100
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetSwordMemoriesVersionBtn, self.ScrollViewVersionList, nSeasonID, self)
        UIHelper.SetPositionY(scriptView._rootNode, UIHelper.GetPositionY(scriptView._rootNode) + nOffSet)
        UIHelper.SetName(scriptView._rootNode, "WidgetSwordMemoriesVersionBtn".. tostring(nSeasonID))
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewVersionList)
    
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end

    self.nTimer = Timer.AddFrame(self, 1, function()
        if g_pClientPlayer.nLevel < 130 then 
            UIHelper.ScrollToRight(self.ScrollViewVersionList, 0)
        else
            UIHelper.ScrollToLeft(self.ScrollViewVersionList, 0)
        end
    end)

    self:UpdateWidgetDone()
    -- self.DetailScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSwordMemoriesVersionTog, self.WidgetDetailShell, nIndex, true, self)
end


function UIPanelSwordMemoriesView:UpdateLayoutRightTopContent()
    local bVis = false
    for  nIndex, btn in ipairs(self.tbRightTopBtn) do
        if UIHelper.GetVisible(btn) then
            bVis =true
            break
        end
    end
    UIHelper.SetVisible(self.LayoutRightTopContent, bVis)
    UIHelper.LayoutDoLayout(self.LayoutRightTopContent)
end

function UIPanelSwordMemoriesView:UpdateWidgetDone()
    for nIndex, widgetDone in ipairs(self.tbWidgetDone) do
        local nCount, nTotal = SwordMemoriesData.GetSeasonProgress(nIndex)
        UIHelper.SetVisible(widgetDone, nCount == nTotal)
    end
end

function UIPanelSwordMemoriesView:UpdateInfo()
    UIHelper.SetVisible(self.WidgetAnchorContent, not self.bVerSionList)
    UIHelper.SetVisible(self.ScrollViewVersionList, self.bVerSionList)
    UIHelper.SetVisible(self.WidgetAniBottomContent, not self.bVerSionList)
    if not self.bVerSionList then 
        
        local scriptView = UIHelper.GetBindScript(self.WidgetAnchorContent)
        scriptView:OnEnter(self.nSeasonID, self, self.bPlayVersionAni, self.nChapterID)
    
    end

    for nIndex, toggle in ipairs(self.tbTogVersionList) do
        UIHelper.SetSelected(toggle, self.nSeasonID == nIndex, false)
    end

    UIHelper.SetSpriteFrame(self.ImgClose, self.bVerSionList and IMG_CLOSE or IMG_RETURN)
    UIHelper.SetVisible(self.WidgetWulintongjian, self.bVerSionList)
    UIHelper.SetVisible(self.WidgetBtnStop, SwordMemoriesData.IsSoundPlaying())
    self:UpdateLayoutRightTopContent()
end

function UIPanelSwordMemoriesView:UpdateBtnStopPlay()
    UIHelper.SetVisible(self.WidgetBtnStop, SwordMemoriesData.IsSoundPlaying())
    self:UpdateLayoutRightTopContent()
end

function UIPanelSwordMemoriesView:SetCurSeason(nSeasonID, bPlayVersionAni, nChapterID)
    self.bVerSionList = false
    self.nSeasonID = nSeasonID
    self.bPlayVersionAni = bPlayVersionAni
    self.nChapterID = nChapterID
    self:UpdateInfo()
end

function UIPanelSwordMemoriesView:BackToVersionList()
    self.bVerSionList = true
    self:UpdateInfo()
end

function UIPanelSwordMemoriesView:PlayAni(szName)
    UIHelper.SetVisible(self.Eff_BookName, false)
    UIHelper.StopAni(self, self.AniAll, szName)
    UIHelper.SetVisible(self.Eff_BookName, true)
    UIHelper.PlayAni(self, self.AniAll, szName)
end

return UIPanelSwordMemoriesView