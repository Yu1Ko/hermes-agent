-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIRoleVoiceView
-- Date: 2023-04-06 10:56:35
-- Desc: 侠客-传记
-- Prefab: PanelRoleVoice
-- ---------------------------------------------------------------------------------

local UIRoleVoiceView = class("UIRoleVoiceView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIRoleVoiceView:_LuaBindList()
    self.BtnClose            = self.BtnClose --- 关闭按钮

    self.TogRoleVoice        = self.TogRoleVoice --- 言谈语音的toggle
    self.TogSystemVoice      = self.TogSystemVoice --- 系统语音的toggle
    self.TogBiography        = self.TogBiography --- 传记的toggle
    self.ScrollViewRoleVoice = self.ScrollViewRoleVoice --- 当前tab的scrollview

    self.WidgetAnchorLeftPop = self.WidgetAnchorLeftPop --- 左侧栏的锚点

    self.MiniScene           = self.MiniScene --- 摆放npc的场景组件
end

function UIRoleVoiceView:OnEnter(dwID, shared_hModelView)
    self.dwID = dwID
    -- 复用 UIPartnerDetailsView 的场景实例，从而无需再次创建，看起来更连贯
    self.shared_hModelView = shared_hModelView

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        UIMgr.HideView(VIEW_ID.PanelPartnerDetails)
    end

    self:UpdateInfo()
end

function UIRoleVoiceView:OnExit()
    self.bInit = false

    self:CleanUpModelView()

    self:UnRegEvent()
    UIMgr.ShowView(VIEW_ID.PanelPartnerDetails)
end

function UIRoleVoiceView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    for idx, uiToggle in ipairs({ self.TogRoleVoice, self.TogSystemVoice, self.TogBiography }) do
        UIHelper.SetSelected(uiToggle, false)
        UIHelper.SetToggleGroupIndex(uiToggle, ToggleGroupIndex.PartnerRoleVoice)
        UIHelper.BindUIEvent(uiToggle, EventType.OnClick, function()
            self:UpdateInfo()

            if idx ~= self.nLastClickToggleIndex then
                UIHelper.SetVisible(self.WidgetAnchorLeftPop, false)
            end
            self.nLastClickToggleIndex = idx
        end)
    end
    UIHelper.SetSelected(self.TogBiography, true)
end

function UIRoleVoiceView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    -- Event.Reg(self, "SYNC_SOUND_ID", function(dwSoundID, pcszFileName)
    --     local szSoundPath = Partner_GetLastPlaySoundPath()
    --     if szSoundPath and pcszFileName == szSoundPath then
    --         Partner_SetPlayingSoundID(dwSoundID)
    --     end
    -- end)
end

function UIRoleVoiceView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local function GetPartnerAttraction(dwID)
    local tInfo       = Partner_GetPartnerInfo(dwID)
    local nAttraction = 0
    if tInfo then
        nAttraction = tInfo.dwFSExp
    end
    return nAttraction
end

local function fnSort(t1, t2)
    if t1.bHave and t2.bHave then
        if t1.nOpenLevel == t2.nOpenLevel then
            return t1.nIndex < t2.nIndex
        end
        return t1.nOpenLevel < t2.nOpenLevel
    elseif t1.bHave then
        return true
    elseif t2.bHave then
        return false
    end
end

function UIRoleVoiceView:UpdateInfo()
    self:UpdateMiniScene()

    UIHelper.RemoveAllChildren(self.ScrollViewRoleVoice)

    if UIHelper.GetSelected(self.TogRoleVoice) then
        self:UpdateRoleVoice()
    elseif UIHelper.GetSelected(self.TogSystemVoice) then
        self:UpdateSystemVoice()
    elseif UIHelper.GetSelected(self.TogBiography) then
        self:UpdateBiography()
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRoleVoice)
end

function UIRoleVoiceView:CleanUpModelView()
    if self.hModelView then
        self.hModelView:release()
        self.hModelView = nil
    end

    self.m_scene = nil
end

function UIRoleVoiceView:UpdateMiniScene()
    -- 初始化 model view
    local hModelView = self.shared_hModelView

    -- 绑定ModelView的场景到MiniScene组件
    self.MiniScene:SetScene(hModelView.m_scene)

    -- 这里位置与详情可以保持完全一致，因此无需额外调整参数
end

function UIRoleVoiceView:UpdateRoleVoice()
    self:UpdateVoice(PartnerData.VOICE_TYPE.CHAT)
end

function UIRoleVoiceView:UpdateSystemVoice()
    self:UpdateVoice(PartnerData.VOICE_TYPE.FIGHT)
end

function UIRoleVoiceView:UpdateVoice(nSelVoiceType)
    local dwPartnerID = self.dwID
    local tVoiceList  = self:GetSortedVoiceInfoList(dwPartnerID)
    for _, tVoiceInfo in ipairs(tVoiceList) do
        if tVoiceInfo.nType == nSelVoiceType then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetRoleVoiceCell, self.ScrollViewRoleVoice, self.dwID, "Voice", tVoiceInfo)

            -- 点击弹出侧面板显示全部信息。
            script:SetFnOnClick(function()
                if not tVoiceInfo.bHave then
                    return
                end

                local szTitle   = ""
                if nSelVoiceType == PartnerData.VOICE_TYPE.CHAT then
                    szTitle = "言谈语音"
                elseif nSelVoiceType == PartnerData.VOICE_TYPE.FIGHT then
                    szTitle = "系统语音"
                end

                local szContent = UIHelper.GBKToUTF8(tVoiceInfo.szDesc)
                self:ShowLeftPop(szTitle, szContent)
            end)
        end
    end
end

function UIRoleVoiceView:GetSortedVoiceInfoList(dwID)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local tVoiceList  = Table_GetPartnerVoice(dwID)
    local nAttraction = GetPartnerAttraction(dwID)
    local nLevel      = GDAPI_GetHeroFSstar(nAttraction)
    for _, tVoiceInfo in pairs(tVoiceList) do
        local dwQuestID         = tVoiceInfo.dwQuestID
        tVoiceInfo.bFinishQuest = true
        if dwQuestID ~= 0 then
            local nQuestPhase = pPlayer.GetQuestPhase(dwQuestID)
            if nQuestPhase ~= QUEST_PHASE.FINISH then
                tVoiceInfo.bFinishQuest = false
            end
        end
        if tVoiceInfo.nOpenLevel == 0 then
            tVoiceInfo.nOpenLevel = 1
        end
        tVoiceInfo.bReachFSExp = nLevel >= tVoiceInfo.nOpenLevel
        tVoiceInfo.bHave       = tVoiceInfo.bReachFSExp and tVoiceInfo.bFinishQuest
    end
    table.sort(tVoiceList, fnSort)
    return tVoiceList
end

function UIRoleVoiceView:UpdateBiography()
    local dwPartnerID = self.dwID
    local tStoryList  = self:GetStoryInfoList(dwPartnerID)
    for _, tStoryInfo in ipairs(tStoryList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetRoleVoiceCell, self.ScrollViewRoleVoice, self.dwID, "Story", tStoryInfo)
        script:SetFnOnClick(function()
            if not tStoryInfo.bHave then
                return
            end

            local szTitle   = UIHelper.GBKToUTF8(tStoryInfo.szTitle)
            local szContent = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tStoryInfo.szContent))
            self:ShowLeftPop(szTitle, szContent)
        end)
    end
end

function UIRoleVoiceView:ShowLeftPop(szTitle, szContent)
    -- BtnCloseLeftPanel 绑定的 UIClickToHide.lua 脚本会将该组件隐藏，这里显示时需要改回来
    UIHelper.SetVisible(self.WidgetAnchorLeftPop, true)

    UIHelper.RemoveAllChildren(self.WidgetAnchorLeftPop)

    local uiWidgetRoleVoiceLeftPop = UIHelper.AddPrefab(PREFAB_ID.WidgetRoleVoiceLeftPop, self.WidgetAnchorLeftPop, self.dwID, szTitle, szContent)
    UIHelper.WidgetFoceDoAlign(uiWidgetRoleVoiceLeftPop)
    UIHelper.BindUIEvent(uiWidgetRoleVoiceLeftPop.BtnCloseLeft, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetAnchorLeftPop, false)
    end)
end

function UIRoleVoiceView:GetStoryInfoList(dwID)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local tStoryList  = Table_GetPartnerStory(dwID)
    local nAttraction = GetPartnerAttraction(dwID)
    local nLevel      = GDAPI_GetHeroFSstar(nAttraction)
    for _, tStoryInfo in pairs(tStoryList) do
        local dwQuestID         = tStoryInfo.dwQuestID
        tStoryInfo.bFinishQuest = true
        if dwQuestID ~= 0 then
            local nQuestPhase = pPlayer.GetQuestPhase(dwQuestID)
            if nQuestPhase ~= QUEST_PHASE.FINISH then
                tStoryInfo.bFinishQuest = false
            end
        end
        if tStoryInfo.nOpenLevel == 0 then
            tStoryInfo.nOpenLevel = 1
        end
        tStoryInfo.bReachFSExp = nLevel >= tStoryInfo.nOpenLevel
        tStoryInfo.bHave       = tStoryInfo.bReachFSExp and tStoryInfo.bFinishQuest
    end
    table.sort(tStoryList, fnSort)
    return tStoryList
end

return UIRoleVoiceView