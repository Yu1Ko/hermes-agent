-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerCard
-- Date: 2023-03-28 11:34:44
-- Desc: 江湖侠客
-- Prefab: WidgetPartnerCard
-- ---------------------------------------------------------------------------------

---@class UIPartnerCard
local UIPartnerCard = class("UIPartnerCard")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerCard:_LuaBindList()
    self.ScrollViewHomeMatchRight = self.ScrollViewHomeMatchRight --- 侠客卡片的scroll view

    self.LayoutHomeMatchItemLess  = self.LayoutHomeMatchItemLess --- 侠客数目<=6的时候使用这个layout

    self.TogScreening             = self.TogScreening --- 筛选框的toggle

    self.ImgGiftOn                = self.ImgGiftOn --- 可领取免费茶饼
    self.ImgGiftOff               = self.ImgGiftOff --- 不可领取免费茶饼
    self.LabelGift                = self.LabelGift --- 免费茶饼提示语
    self.BtnGift                  = self.BtnGift --- 领取每日免费茶饼的按钮
end

function UIPartnerCard:OnEnter(dwPlayerID, MiniScene, nPartnerViewOpenType)
    self.dwPlayerID           = dwPlayerID
    self.MiniScene            = MiniScene
    ---@see PartnerViewOpenType
    self.nPartnerViewOpenType = nPartnerViewOpenType

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()

        PartnerData.InitFilterDef()
        FilterDef.Partner.Reset()

        self.bInit = true
    end

    if Partner_IsSelfPlayer(self.dwPlayerID) then
        local tAllPartnerList = PartnerData.GetPartnerIDList(self.dwPlayerID)
        self:UpdateInfo(tAllPartnerList)
    else
        -- 查看他人侠客时需要先向服务器请求其数据
        local player = GetPlayer(self.dwPlayerID)
        if player then
            self.szGlobalID = player.GetGlobalID()

            -- 与端游一样，dwCenterID取0，只查询当前服务器
            PeekOtherPlayerNpcAssistedSimpleList(0, self.szGlobalID)
        end
    end
end

function UIPartnerCard:OnExit()
    self.bInit = false

    self:CleanUpModelView()

    self:UnRegEvent()
end

function UIPartnerCard:BindUIEvent()
    UIHelper.BindUIEvent(self.TogScreening, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogScreening, TipsLayoutDir.TOP_LEFT, FilterDef.Partner)
    end)

    UIHelper.BindUIEvent(self.BtnGift, EventType.OnClick, function()
        local bDailyTeaTaken = PartnerData.IfGetHeroDailyTea()
        if bDailyTeaTaken then
            return
        end

        UIHelper.RemoteCallToServer("On_Hero_GetDailyTea")
    end)
end

function UIPartnerCard:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if szKey ~= FilterDef.Partner.Key then
            return
        end

        local tShowPartnerIDList = PartnerData.GetFilteredPartnerIDList(tbInfo, self.dwPlayerID)
        self:UpdateInfo(tShowPartnerIDList)
    end)

    Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nRetCode, dwID)
        -- 查看他人侠客时dwID为对应玩家ID
        if not Partner_IsSelfPlayer(self.dwPlayerID) and self.dwPlayerID == dwID then
            if nRetCode == NPC_ASSISTED_RESULT_CODE.OTHER_PLAYER_NPC_ASSISTED_SIMPLE_LIST_SYNC_OVER then
                -- 获取他人数据
                local tAllPartnerList = PartnerData.GetPartnerIDList(self.dwPlayerID)
                self:UpdateInfo(tAllPartnerList)
            end
        end
    end)

    Event.Reg(self, "On_Partner_IsGetDailyTeaSuccess", function(bFlag)
        if not bFlag then
            return
        end

        -- 获取了新的茶饼，刷新下界面
        self:UpdateDailyTeaInfo()
    end)
end

function UIPartnerCard:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerCard:UpdateInfo(tPartnerIDList)
    tPartnerIDList               = self:FilterTryOutPartners(tPartnerIDList)

    self.tPartnerIDList          = tPartnerIDList

    local bUseLayout = table.get_len(tPartnerIDList) <= 6
    UIHelper.SetVisible(self.LayoutHomeMatchItemLess, bUseLayout)
    UIHelper.SetVisible(self.ScrollViewHomeMatchRight, not bUseLayout)

    local uiContainer
    if bUseLayout then
        uiContainer = self.LayoutHomeMatchItemLess
    else
        uiContainer = self.ScrollViewHomeMatchRight
    end

    UIHelper.RemoveAllChildren(uiContainer)

    for idx, dwPartnerID in ipairs(tPartnerIDList) do
        ---@type UIPartnerCardCell
        local script = UIMgr.AddPrefab(PREFAB_ID.WidgetPartnerCardCell, uiContainer, dwPartnerID, tPartnerIDList, self.dwPlayerID)
        UIHelper.SetAnchorPoint(script._rootNode, 0, 0)

        UIHelper.BindUIEvent(script.BtnCard, EventType.OnClick, function()
            script:UnNewAddPartner()

            self:OpenPartnerDetailPage(dwPartnerID, tPartnerIDList)
        end)
    end

    if bUseLayout then
        UIHelper.LayoutDoLayout(uiContainer)
    else
        UIHelper.ScrollViewDoLayout(uiContainer)
        UIHelper.ScrollToLeft(uiContainer)
    end

    self:UpdateMiniScene()

    self:UpdateDailyTeaInfo()
end

function UIPartnerCard:OpenPartnerDetailPage(dwPartnerID, tPartnerIDList, nPartnerViewOpenType)
    local script = UIMgr.GetViewScript(VIEW_ID.PanelPartnerDetails)
    if script then
        script:OnEnter(dwPartnerID, tPartnerIDList, self.dwPlayerID, nPartnerViewOpenType)
    else
        UIHelper.TempHideMiniSceneUntilNewViewClose(self, self.MiniScene, nil, VIEW_ID.PanelPartnerDetails, nil)
        ---@see UIPartnerDetailsView#OnEnter
        UIMgr.Open(VIEW_ID.PanelPartnerDetails, dwPartnerID, tPartnerIDList, self.dwPlayerID, nPartnerViewOpenType)
    end
end

function UIPartnerCard:FilterTryOutPartners(tPartnerIDList)
    local player = Partner_GetPlayer(self.dwPlayerID)
    if not player then
        return tPartnerIDList
    end

    local BUFF_UI    = 27896--剧情模式标识
    local bStoryMode = player.IsHaveBuff(BUFF_UI, 1)
    if bStoryMode then
        return tPartnerIDList
    end

    -- 非剧情模式下不显示剧情侠客
    local tOtherPartnerIDList = {}
    for _, dwPartnerID in ipairs(tPartnerIDList) do
        local tInfo = Table_GetPartnerNpcInfo(dwPartnerID)
        if not tInfo.bTryOut then
            table.insert(tOtherPartnerIDList, dwPartnerID)
        end
    end

    return tOtherPartnerIDList
end

function UIPartnerCard:UpdateMiniScene()
    -- 初始化 model view
    local hModelView = self.hModelView

    if PartnerData.bNotMgrSceneByNpcModelView and not self.m_scene then
        self.m_scene = PartnerData.GetOrCreateScene()
    end

    if not hModelView then
        hModelView = NpcModelView.CreateInstance(NpcModelView)
        hModelView:ctor()
        hModelView:init(self.m_scene, PartnerData.bNotMgrSceneByNpcModelView, true, PartnerData.szSceneFilePath, "PartnerCard")
        self.MiniScene:SetScene(hModelView.m_scene)

        -- 确保三个model view都使用同一个场景实例
        self.m_scene    = hModelView.m_scene

        self.hModelView = hModelView
    end

    -- 不论是否加载模型，都要确保镜头参数位置一样
    hModelView:SetCamera(Const.MiniScene.PartnerView.tbMainCamera)
end

function UIPartnerCard:CleanUpModelView()
    if self.hModelView then
        self.hModelView:release()
        self.hModelView = nil
    end

    self.m_scene = nil
end

--- 获取第一个已经拥有的非试用侠客
function UIPartnerCard:GetFirstNormalGotPartnerID(tPartnerIDList)
    local dwFirstNormalGotPartnerID
    for idx, dwPartnerID in ipairs(tPartnerIDList) do
        local bHave = Partner_GetPartnerInfo(dwPartnerID, self.dwPlayerID) ~= nil
        local tInfo = Table_GetPartnerNpcInfo(dwPartnerID)
        if bHave and not tInfo.bTryOut then
            dwFirstNormalGotPartnerID = dwPartnerID
            break
        end
    end

    return dwFirstNormalGotPartnerID
end

function UIPartnerCard:UpdateDailyTeaInfo()
    if not Partner_IsSelfPlayer(self.dwPlayerID) then
        UIHelper.SetVisible(self.BtnGift, false)
        return
    end

    -- 今日免费茶饼是否已领取
    local bDailyTeaTaken = PartnerData.IfGetHeroDailyTea()
    UIHelper.SetVisible(self.ImgGiftOn, not bDailyTeaTaken)
    UIHelper.SetVisible(self.ImgGiftOff, bDailyTeaTaken)
    UIHelper.SetString(self.LabelGift, bDailyTeaTaken and "今日已领" or "点击领取")
    UIHelper.SetButtonState(self.BtnGift, not bDailyTeaTaken and BTN_STATE.Normal or BTN_STATE.Disable)
end

return UIPartnerCard