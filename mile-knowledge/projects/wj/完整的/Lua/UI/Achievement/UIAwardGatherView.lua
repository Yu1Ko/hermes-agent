-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAwardGatherView
-- Date: 2023-02-14 10:28:48
-- Desc: 隐元秘鉴 - 奖励收集
-- Prefab: PanelAwardGather
-- ---------------------------------------------------------------------------------
local UIAwardGatherView   = class("UIAwardGatherView")
local nPageItemCount      = 36

local tbModelPreviewInfo  = Const.MiniScene.AwardGatherView.tbModelPreviewInfo
local tbFurnitureModelPos = Const.MiniScene.AwardGatherView.tbFurnitureModelPos
local tbFurnitureCamare   = Const.MiniScene.AwardGatherView.tbFurnitureCamare
local tbFrame             = { tRadius = { 280, 700 } }
local tRepresentSub       = {
    -- [EQUIPMENT_SUB.MELEE_WEAPON] = EQUIPMENT_REPRESENT.WEAPON_STYLE,
    -- [EQUIPMENT_SUB.CHEST] = EQUIPMENT_REPRESENT.CHEST_STYLE,
    [EQUIPMENT_SUB.HELM] = EQUIPMENT_REPRESENT.HELM_STYLE,
    [EQUIPMENT_SUB.HEAD_EXTEND] = EQUIPMENT_REPRESENT.HEAD_EXTEND,
    -- [EQUIPMENT_SUB.WAIST] = EQUIPMENT_REPRESENT.WAIST_STYLE,
    -- [EQUIPMENT_SUB.BOOTS] = EQUIPMENT_REPRESENT.BOOTS_STYLE,
    -- [EQUIPMENT_SUB.BANGLE] = EQUIPMENT_REPRESENT.BANGLE_STYLE,
    [EQUIPMENT_SUB.WAIST_EXTEND] = EQUIPMENT_REPRESENT.WAIST_EXTEND,
    [EQUIPMENT_SUB.BACK_EXTEND] = EQUIPMENT_REPRESENT.BACK_EXTEND,
    [EQUIPMENT_SUB.FACE_EXTEND] = EQUIPMENT_REPRESENT.FACE_EXTEND,
    -- [EQUIPMENT_SUB.L_SHOULDER_EXTEND] = EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND,
    -- [EQUIPMENT_SUB.R_SHOULDER_EXTEND] = EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND,
    [EQUIPMENT_SUB.BACK_CLOAK_EXTEND] = EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND,
    -- [EQUIPMENT_SUB.BAG_EXTEND] = EQUIPMENT_REPRESENT.BAG_EXTEND,
    -- [EQUIPMENT_SUB.PENDENT_PET] = EQUIPMENT_REPRESENT.PENDENT_PET_STYLE,
    -- [EQUIPMENT_SUB.GLASSES_EXTEND] = EQUIPMENT_REPRESENT.GLASSES_EXTEND,
    -- [EQUIPMENT_SUB.L_GLOVE_EXTEND] = EQUIPMENT_REPRESENT.L_GLOVE_EXTEND,
    -- [EQUIPMENT_SUB.R_GLOVE_EXTEND] = EQUIPMENT_REPRESENT.R_GLOVE_EXTEND,
}

local tHorseEquipToRe     = {
    [HORSE_ENCHANT_DETAIL_TYPE.HEAD] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT1,
    [HORSE_ENCHANT_DETAIL_TYPE.CHEST] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT2,
    [HORSE_ENCHANT_DETAIL_TYPE.FOOT] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT3,
    [HORSE_ENCHANT_DETAIL_TYPE.HANT_ITEM] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT4,
}
---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAwardGatherView:_LuaBindList()
    self.BtnClose                 = self.BtnClose --- 关闭界面
    self.LabelRewardProgress      = self.LabelRewardProgress --- 奖励收集进度
    self.ScrollViewRewardItemList = self.ScrollViewRewardItemList --- 奖励道具列表 scroll view
    self.LayoutRewardItemList     = self.LayoutRewardItemList --- 奖励道具列表 layout

    self.WidgetSelectedItemInfo   = self.WidgetSelectedItemInfo --- 道具信息的widget

    self.EditBoxSearchText        = self.EditBoxSearchText --- 搜索文本框
    self.BtnCancelSearch          = self.BtnCancelSearch --- 取消搜索按钮

    self.BtnShowFilterTip         = self.BtnShowFilterTip --- 是否显示过滤器的Toggle

    self.LayoutItemDetail         = self.LayoutItemDetail --- 道具信息挂载锚点

    self.WidgetEmpty              = self.WidgetEmpty --- 无模型时的空状态
    self.WidgetEmptySearch        = self.WidgetEmptySearch --- 无搜索结果时的空状态

    self.WidgetPaginate           = self.WidgetPaginate --- 左下角的分页
end

function UIAwardGatherView:OnEnter(dwPlayerID, szScenePath)
    self.aAchievement = nil
    self.dwPlayerID   = dwPlayerID
    self.bPandantShowPlayerModel = true
    if not self.bInit then
        self:Init()
        self:RegEvent()
        self:BindUIEvent()

        self:InitFilterDef()
        FilterDef.AchievementAwardGather.Reset()
        AchievementData.ResetGiftSearchAndFilter()

        self.bInit = true
    end
    self.szScenePath = szScenePath or Const.COMMON_SCENE
    self:InitMiniScene()
    self:UpdateInfo()
end

function UIAwardGatherView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    UITouchHelper.UnBindModel()

  

    if self.hModelView then
        local scene = self.hModelView.m_scene
        if scene then
            scene:RestoreCameraLight()
        end

        self.hModelView:release()
        self.hModelView  = nil
        self.cameraModel = nil
        self.hPendantModelView = nil
    end

    if self.hPendantModelView then
        local scene = self.hPendantModelView.m_scene
        self.hPendantModelView:release()
        self.hModelView  = nil
        self.cameraModel = nil
    end

    if self.hRideModelView then
        self.hRideModelView:release()
        self.hRideModelView  = nil
        self.cameraRideModel = nil
    end
    if self.hFurnitureModelView then
        self.hFurnitureModelView:release()
        self.hFurnitureModelView   = nil
        self.tFurniturModelSetting = nil
        self.cameraFurnitureModel  = nil
    end

    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end
end

function UIAwardGatherView:BindUIEvent()

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        Homeland_SendMessage(HOMELAND_FURNITURE.EXIT)

        Timer.AddFrame(self, 1, function()
            UIMgr.Close(self)
        end)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxSearchText, function()
        AchievementData.szGiftKey = UIHelper.GetString(self.EditBoxSearchText)

        self.nPageIndex           = 1
        UIHelper.SetString(self.EditPaginate, self.nPageIndex)
        self.nCurIndex = self.nPageIndex * nPageItemCount + 1

        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnCancelSearch, EventType.OnClick, function()
        AchievementData.szGiftKey = ""
        UIHelper.SetString(self.EditBoxSearchText, "")

        self.nPageIndex = 1
        UIHelper.SetString(self.EditPaginate, self.nPageIndex)
        self.nCurIndex = self.nPageIndex * nPageItemCount + 1

        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function()
        if self.nPageIndex > 1 then
            self.nPageIndex = self.nPageIndex - 1
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            self.nCurIndex = self.nPageIndex * nPageItemCount + 1
            self:UpdateInfo()
        end
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function()
        if self.nPageIndex < self.nPageCount then
            self.nPageIndex = self.nPageIndex + 1
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            self.nCurIndex = self.nPageIndex * nPageItemCount + 1
            self:UpdateInfo()
        end
    end)

    UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
        local nPageIndex = tonumber(UIHelper.GetString(self.EditPaginate))
        if nPageIndex ~= self.nPageIndex then
            if nPageIndex < 1 then
                self.nPageIndex = 1
            elseif nPageIndex > self.nPageCount then
                self.nPageIndex = self.nPageCount
            else
                self.nPageIndex = nPageIndex
            end
            if self.nPageIndex ~= nPageIndex then
                UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            end
            self.nCurIndex = self.nPageIndex * nPageItemCount + 1
            self:UpdateInfo()
        end
    end)

    UIHelper.BindUIEvent(self.BntGo, EventType.OnClick, function()
        if not self.aAchievement then
            return
        end

        UIHelper.TempHidePlayerMiniSceneUntilNewViewClose(self, self.MiniScene, self.hModelView, VIEW_ID.PanelAchievementContent, function()
            self:UpdateModelInfo()
        end)

        local a = self.aAchievement
        UIMgr.Open(VIEW_ID.PanelAchievementContent, a.dwGeneral, a.dwSub, a.dwDetail, a.dwID, self.dwPlayerID)
    end)

    UIHelper.BindUIEvent(self.BtnShowFilterTip, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnShowFilterTip, TipsLayoutDir.TOP_LEFT, FilterDef.AchievementAwardGather)
    end)

    UIHelper.SetTouchDownHideTips(self.BtnLeft, false)
    UIHelper.SetTouchDownHideTips(self.BtnRight, false)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)

end

function UIAwardGatherView:Init()
    -- 初始化搜索参数
    AchievementData.szGiftKey = ""
end

function UIAwardGatherView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if szKey ~= FilterDef.AchievementAwardGather.Key then
            return
        end

        self:ParseFilterResult(tbInfo)
        self.nPageIndex = 1
        UIHelper.SetString(self.EditPaginate, self.nPageIndex)
        self.nCurIndex = self.nPageIndex * nPageItemCount + 1
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnMiniSceneLoadProgress, function(nProcess)
        if nProcess >= 100 then
            local scene = self.hModelView.m_scene
            if scene and not QualityMgr.bDisableCameraLight then
                scene:OpenCameraLight(QualityMgr.szCameraLightForUI)
            end
        end
    end)

    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        self:UpdateModelInfo()
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox ~= self.EditPaginate then return end

        local nPageIndex = tonumber(UIHelper.GetString(self.EditPaginate))
        if nPageIndex ~= self.nPageIndex then
            if nPageIndex < 1 then
                self.nPageIndex = 1
            elseif nPageIndex > self.nPageCount then
                self.nPageIndex = self.nPageCount
            else
                self.nPageIndex = nPageIndex
            end
            if self.nPageIndex ~= nPageIndex then
                UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            end
            self.nCurIndex = self.nPageIndex * nPageItemCount + 1
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE", function()
        UIHelper.TempHidePlayerMiniSceneUntilNewViewClose(self, self.MiniScene, self.hModelView, VIEW_ID.PanelOutfitPreview, function()
            self:UpdateModelInfo()
        end)
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 5, function()
            self:FixItemTipsSize()

            Timer.AddFrame(self, 2, function()
                UIHelper.CascadeDoLayoutDoWidget(self.LayoutItemDetail, true, true)
            end)
        end)
    end)

    -- Event.Dispatch("OnUIPandentModel_ShowPlayer", false)
    -- Event.Dispatch("OnUIPandentModel_ChangeEnvPreset", 15)
    -- UIMgr.Open(VIEW_ID.PanelAwardGather,  PlayerData.GetPlayerID(), UIHelper.GBKToUTF8("data\source\maps\界面使用场景\界面使用场景.jsonmap"))
    -- Event.Dispatch("OnUIPandentModel_AddPrefab", UIHelper.GBKToUTF8("data\\source\\maps_source\\Prefab\\界面使用场景\\水上花灯.prefab") )
    Event.Reg(self, "OnUIPandentModel_ShowPlayer", function(bVisible)
        self.bPandantShowPlayerModel = bVisible
        self:UpdateModelInfo()
    end)
    Event.Reg(self, "OnUIPandentModel_ChangeEnvPreset", function(nPresetID)
        rlcmd(string.format("set env preset %d", nPresetID))
    end)

    Event.Reg(self, "OnUIPandentModel_AddPrefab", function(szPrefabPath, nScale)
        self.hModelView:AddExModel(szPrefabPath,nScale or 1)
    end)
end

function UIAwardGatherView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAwardGatherView:UpdateInfo()
    local hPlayer = GetClientPlayer()
    if self.dwPlayerID then
        hPlayer = GetPlayer(self.dwPlayerID)
    end
    local tbAll             = {}
    local nOwnedCount       = 0

    local bShowCollected    = table.contain_value(AchievementData.tGiftFilterCollectStatus, AchievementData.GIFT_FILTER_TYPE.Collected) or
            table.contain_value(AchievementData.tGiftFilterCollectStatus, AchievementData.GIFT_FILTER_TYPE.All)
    local bShowNotCollected = table.contain_value(AchievementData.tGiftFilterCollectStatus, AchievementData.GIFT_FILTER_TYPE.NotCollected) or
            table.contain_value(AchievementData.tGiftFilterCollectStatus, AchievementData.GIFT_FILTER_TYPE.All)

    local tSearchGiftList   = AchievementData.SearchGift()
    for k, v in pairs(tSearchGiftList) do
        local bMatch  = true

        local bFinish = hPlayer.IsAchievementAcquired(v.dwAchievement)
        if bFinish then
            nOwnedCount = nOwnedCount + 1
            if bShowCollected then
                v.bOwned = true
            else
                bMatch = false
            end
        else
            if bShowNotCollected then
                v.bOwned = false
            else
                bMatch = false
            end
        end

        local aAchievement = Table_GetAchievement(v.dwAchievement)
        local itemInfo     = GetItemInfo(aAchievement.dwItemType, aAchievement.dwItemID)
        local nSub         = AchievementData.GetNSub(itemInfo)
        local bTypeMatch   = table.contain_value(AchievementData.tGiftFilterGiftType, nSub) or table.contain_value(AchievementData.tGiftFilterGiftType, "all")
        if not bTypeMatch then
            bMatch = false
        end

        if bMatch then
            table.insert(tbAll, v)
        end
    end

    table.sort(tbAll, function(a, b)
        if a.bOwned and not b.bOwned then
            return true
        end
        return false
    end)

    UIHelper.RemoveAllChildren(self.ScrollViewRewardItemList)
    self:UpdateList(tbAll)

    self.nPageCount = math.ceil(#tbAll / nPageItemCount) or 0
    UIHelper.SetString(self.LabelPaginate, "/" .. self.nPageCount)
    UIHelper.SetString(self.LabelRewardProgress, nOwnedCount .. "/" .. #AchievementData.tGiftList)

    -- 刚打开界面时不选中任何道具信息
    UIHelper.SetVisible(self.WidgetSelectedItemInfo, false)

    UIHelper.SetSelected(self.BtnShowFilterTip, false)

    local bHasSearchResult = not table.is_empty(tSearchGiftList)
    UIHelper.SetVisible(self.WidgetEmptySearch, not bHasSearchResult)
    UIHelper.SetVisible(self.MiniScene, bHasSearchResult)
    UIHelper.SetVisible(self.WidgetPaginate, bHasSearchResult)
end

function UIAwardGatherView:UpdateList(tbDataList)
    -- local nCountPerFrame = 20 -- 每一帧加载的个数
    -- local nStartIdx      = 1
    self.tbCurItemScript = {}
    UIHelper.RemoveAllChildren(self.ScrollViewRewardItemList)

    Timer.DelTimer(self, self.nTimerID)

    self.nPageIndex = self.nPageIndex or 1
    local nIndex1   = nPageItemCount * (self.nPageIndex - 1) + 1
    local nIndex2   = nIndex1 + nPageItemCount - 1
    for nIndex = nIndex1, nIndex2, 1 do
        local tbData = tbDataList[nIndex]
        if tbData then
            local aAchievement = Table_GetAchievement(tbData.dwAchievement)
            local widgetItem   = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.ScrollViewRewardItemList)
            widgetItem:OnInitWithTabID(aAchievement.dwItemType, aAchievement.dwItemID)

            UIHelper.SetToggleGroupIndex(widgetItem.ToggleSelect, ToggleGroupIndex.AchievementAwardGather)

            widgetItem:SetSelectChangeCallback(function(_, bSelected, _, _)
                if not bSelected then
                    return
                end
                self.aAchievement = aAchievement

                UIHelper.SetVisible(self.WidgetSelectedItemInfo, true)

                if not self.scriptItemTips then
                    self.scriptItemTips = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.LayoutItemDetail)
                    self.scriptItemTips:HidePreviewBtn(true)
                    UIHelper.SetAnchorPoint(self.scriptItemTips._rootNode, 0.5, 1)
                end
                self.scriptItemTips:OnInitWithTabID(aAchievement.dwItemType, aAchievement.dwItemID)

                -- local tbBtnState = {
                --     {
                --         szName = "查看成就",
                --         OnClick = function()
                --             if not self.aAchievement then
                --                 return
                --             end

                --             local a = self.aAchievement
                --             UIMgr.Open(VIEW_ID.PanelAchievementContent, a.dwGeneral, a.dwSub, a.dwDetail, a.dwID, self.dwPlayerID)
                --         end
                --     }
                -- }
                -- self.scriptItemTips:SetBtnState(tbBtnState)
                self.scriptItemTips:SetBtnState({})

                self:FixItemTipsSize()

                self:UpdateModelInfo()
                UIHelper.LayoutDoLayout(self.LayoutItemDetail)
                UIHelper.WidgetFoceDoAlignAssignNode(self, self.LayoutItemDetail)
            end)
            table.insert(self.tbCurItemScript, widgetItem)
            if not tbData.bOwned then
                widgetItem:SetItemGray(true)
            end
            UIHelper.ScrollViewDoLayout(self.ScrollViewRewardItemList)
            UIHelper.ScrollToTop(self.ScrollViewRewardItemList, 0)
            UIHelper.ScrollViewSetupArrow(self.ScrollViewRewardItemList, self.WidgetArrow)
        else
            Timer.DelTimer(self, self.nTimerID)
            --UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewRewardItemList, true, true)
            UIHelper.ScrollViewDoLayout(self.ScrollViewRewardItemList)
            UIHelper.ScrollToTop(self.ScrollViewRewardItemList, 0)
            UIHelper.ScrollViewSetupArrow(self.ScrollViewRewardItemList, self.WidgetArrow)
        end
    end

    Timer.AddFrame(self, 1, function()
        self.tbCurItemScript[1]:SetSelected(true)
        self.tbCurItemScript[1]:SetSelected(true)
    end)
end

function UIAwardGatherView:FixItemTipsSize()
    if not self.scriptItemTips then
        return
    end

    local layout = self.LayoutItemDetail
    local parent = UIHelper.GetParent(layout)

    -- 将右侧道具区域设置为比其父节点高度少80，确保不同比例下都长得差不多
    UIHelper.SetHeight(layout, UIHelper.GetHeight(parent) - 80)
    UIHelper.SetHeight(self.scriptItemTips._rootNode, UIHelper.GetHeight(parent) - 80)

    self.scriptItemTips:UpdateScrollViewHeight(UIHelper.GetHeight(parent) - 80 - 200)
end

local function _ResetFilter(nFilterIndex)
    FilterDef.AchievementAwardGather[nFilterIndex].tbList = {}
end

local function _AppendFilter(nFilterIndex, szName)
    table.insert(FilterDef.AchievementAwardGather[nFilterIndex].tbList, szName)
end

function UIAwardGatherView:InitFilterDefGiftType()
    _ResetFilter(FilterDef.AchievementAwardGather.IndexDef.GiftType)

    -- 获得情况
    _AppendFilter(FilterDef.AchievementAwardGather.IndexDef.GiftType, g_tStrings.MIDDLEMAP_QUEST_SHOW_ALL)
    for _, tInfo in ipairs(AchievementData.tGiftType) do
        _AppendFilter(FilterDef.AchievementAwardGather.IndexDef.GiftType, tInfo.szText)
    end
end

function UIAwardGatherView:InitFilterDef()
    -- 收集状态无需调整，仅奖励类别需要动态添加上去
    self:InitFilterDefGiftType()
end

function UIAwardGatherView:InitMiniScene()
    self.hModelView = PlayerModelView.CreateInstance(PlayerModelView)
    self.hModelView:ctor()
    self.hModelView:InitBy({
                               szName = "AwardGather",
                               bExScene = true,
                               szExSceneFile = self.szScenePath,
                               bAPEX = false,
                           })
    self.tbModelPreviewInfo = tbModelPreviewInfo[GetClientPlayer().nRoleType]
    self.MiniScene:SetScene(self.hModelView.m_scene)


    self.hPendantModelView = PendantModelView.CreateInstance(PendantModelView)
    self.hPendantModelView:ctor()
    self.hPendantModelView:InitBy({
                               szName = "AwardGatherPendant",
                               scene = self.hModelView.m_scene,
                           })

    self.hRideModelView = RidesModelView.CreateInstance(RidesModelView)
    self.hRideModelView:ctor()
    self.hRideModelView:init(self.hModelView.m_scene, nil)
    RidesModelPreview.RegisterHorse(self.MiniScene, self.hRideModelView, "AwardGatherHorse", "AwardGatherHorse")

    self.tFurniturModelSetting = {}
    self.hFurnitureModelView   = FurnitureModelView.CreateInstance(FurnitureModelView)
    self.hFurnitureModelView:ctor()
    self.hFurnitureModelView:init(self.hModelView.m_scene, false, _, "RenownRewardFurniture")
end

function UIAwardGatherView:UpdateModelInfo()
    -- UIHelper.SetVisible(self.WidgetAnchorMiddle, false)
    UIHelper.SetVisible(self.WidgetEmpty, false)
    UIHelper.SetVisible(self.WidgetDownloadBtnShell, false)
    self.hPendantModelView:UnloadModel()
    self.hModelView:UnloadModel()
    self.hRideModelView:UnloadRidesModel()
    self.hFurnitureModelView:UnloadModel()
    Homeland_SendMessage(HOMELAND_FURNITURE.EXIT)
    self.cameraModel = self.cameraModel or camera_plus.CreateInstance(camera_plus)
    self:InitCamera(self.cameraModel, self.tbModelPreviewInfo.tbCamere, Const.MiniScene.AwardGatherView.tbPos)

    if not self.aAchievement then
        return
    end

    local dwItemTabType  = self.aAchievement.dwItemType
    local dwItemTabIndex = self.aAchievement.dwItemID

    if not dwItemTabType or not dwItemTabIndex then
        return
    end

    local itemInfo = ItemData.GetItemInfo(dwItemTabType, dwItemTabIndex)
    if not itemInfo then
        return
    end
   
    if ItemData.IsPendantItem(itemInfo) then
        self:UpdatePendantItemModelInfo()
    elseif itemInfo.nGenre == ITEM_GENRE.HOMELAND then
        self:UpdateFurnitureModelInfo()
    elseif itemInfo.nSub == EQUIPMENT_SUB.HORSE then
        self:UpdateHorseModelInfo()
    elseif itemInfo.nSub == EQUIPMENT_SUB.HORSE_EQUIP then
        self:UpdateHorseEquipModelInfo()
    elseif itemInfo then
        self:UpdateMiddleItemIconInfo()
    end
end

function UIAwardGatherView:UpdatePendantItemModelInfo()
    if not self.aAchievement then
        return
    end
    local dwItemTabType  = self.aAchievement.dwItemType
    local dwItemTabIndex = self.aAchievement.dwItemID
    local itemInfo       = ItemData.GetItemInfo(dwItemTabType, dwItemTabIndex)
    if not itemInfo then
        return
    end
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end
    local hExterior = GetExterior()
    if not hExterior then
        return
    end
    self.hPendantModelView:UnloadModel()
    self.hModelView:UnloadModel()
    self.hRideModelView:UnloadRidesModel()
   
    local nYaw = self.tbModelPreviewInfo[itemInfo.nSub] or self.tbModelPreviewInfo.nYaw
    if not self.bPandantShowPlayerModel then 
        self.hPendantModelView:LoadRes(itemInfo,tRepresentSub[itemInfo.nSub])
        self.hPendantModelView:LoadModel()
        self.hPendantModelView:SetTranslation(0,100,0)
        self.hPendantModelView:SetYaw(nYaw)
        self.hPendantModelView:SetCamera(self.tbModelPreviewInfo.tbCamere)
        UITouchHelper.BindModel(self.TouchContainer, self.hPendantModelView, self.cameraModel, { tbFrame = tbFrame })
    else
        local tRepresentID = Role_GetRepresentID(g_pClientPlayer)
        for _, nRepresentSub in ipairs(tRepresentSub) do
            tRepresentID[nRepresentSub] = 0
        end
        tRepresentID[tRepresentSub[itemInfo.nSub]] = itemInfo.nRepresentID
        local bShowWeapon                          = false
        if not bShowWeapon then
            tRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE]    = 0
            tRepresentID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 0
        end
        self.hModelView:LoadRes(hPlayer.dwID, tRepresentID)
        self.hModelView:PlayAnimation("Idle", "loop")
        self.hModelView:SetTranslation(table.unpack(Const.MiniScene.AwardGatherView.tbPos))
        self.hModelView:SetYaw(nYaw)
        self.hModelView:SetCamera(self.tbModelPreviewInfo.tbCamere)
        UITouchHelper.BindModel(self.TouchContainer, self.hModelView, self.cameraModel, { tbFrame = tbFrame })
    end
   
    self.cameraModel = self.cameraModel or camera_plus.CreateInstance(camera_plus)
    self:InitCamera(self.cameraModel, self.tbModelPreviewInfo.tbCamere, Const.MiniScene.AwardGatherView.tbPos)
    self:UpdateDownloadEquipRes()
end

function UIAwardGatherView:UpdateFurnitureModelInfo()
    if not self.aAchievement then
        return
    end
    local dwItemTabType  = self.aAchievement.dwItemType
    local dwItemTabIndex = self.aAchievement.dwItemID

    local itemInfo       = ItemData.GetItemInfo(dwItemTabType, dwItemTabIndex)
    if not itemInfo then
        return
    end
    self:LoadSetting(self.tFurniturModelSetting)
    local nFurnitureType = itemInfo.nFurnitureType
    local dwFurnitureID  = itemInfo.dwFurnitureID
    local tLine          = Table_GetAwardFurnitureModelInfo(dwFurnitureID)
    local tUIInfo        = FurnitureData.GetFurnInfoByTypeAndID(nFurnitureType, dwFurnitureID)
    local dwRepresentID  = tUIInfo and tUIInfo.dwModelID
    local tbPos          = tLine and SplitString(tLine.szPosMB, ";") or tbFurnitureModelPos
    local fScale         = tLine and tLine.fScaleMB or Const.MiniScene.AwardGatherView.fFurnitureModelScale
    local nYaw           = tLine and tLine.nYaw or Const.MiniScene.AwardGatherView.fFurnitureModelYaw
    local nPutType       = tLine and tLine.nPutType or 0
    local nDetails       = tLine and tLine.nDetails or 0

    self.hFurnitureModelView:LoadModel(dwRepresentID, nPutType, nDetails, fScale)
    self.hFurnitureModelView:SetTranslation(unpack(tbPos))
    self.hFurnitureModelView:SetCamera(tbFurnitureCamare)
    self.hFurnitureModelView:SetYaw(nYaw)
    self.hFurnitureModelView:SetScale(fScale, fScale, fScale)

    self.cameraFurnitureModel = self.cameraFurnitureModel or camera_plus.CreateInstance(camera_plus)
    self:InitCamera(self.cameraFurnitureModel, tbFurnitureCamare)
    UITouchHelper.BindModel(self.TouchContainer, self.hFurnitureModelView, self.cameraFurnitureModel, { tbFrame = tbFrame })
end

local function TableCombine(A, B)
    local C = {}
    for _, value in ipairs(A) do
        table.insert(C, value)
    end
    for _, value in ipairs(B) do
        table.insert(C, value)
    end
    return C
end

function UIAwardGatherView:UpdateHorseModelInfo()
    if not self.aAchievement then
        return
    end
    local dwItemTabType  = self.aAchievement.dwItemType
    local dwItemTabIndex = self.aAchievement.dwItemID

    local itemInfo       = ItemData.GetItemInfo(dwItemTabType, dwItemTabIndex)
    if not itemInfo then
        return
    end

    local player        = g_pClientPlayer
    local tbRepresentID = player.GetRepresentID()

    if itemInfo and itemInfo.nGenre == ITEM_GENRE.EQUIPMENT and itemInfo.nSub == EQUIPMENT_SUB.HORSE then
        tbRepresentID[EQUIPMENT_REPRESENT.HORSE_STYLE] = itemInfo.nRepresentID
    else
        return
    end

    local tbCamera = UICameraTab["Ride"][VIEW_ID.PanelAwardGather]

    self.hRideModelView:LoadResByRepresent(tbRepresentID, false)
    self.hRideModelView:LoadRidesModel()
    self.hRideModelView:PlayRidesAnimation("Idle", "loop")
    self.hRideModelView:SetCameraPos(unpack(tbCamera.tbCameraPos))
    self.hRideModelView:SetCameraLookPos(unpack(tbCamera.tbCameraLookPos))
    self.hRideModelView:SetCameraPerspective(unpack(tbCamera.tbCameraPerspective))
    self.hRideModelView:SetTranslation(unpack(tbCamera.tbModelTranslation))

    local fScale = Const.MiniScene.RideScale
    self.hRideModelView:SetScaling(fScale, fScale, fScale)
    self.hRideModelView:SetYaw(tbCamera.nModelYaw)
    self.hRideModelView:SetMainFlag(true)   -- 接收光照、阴影等

    local tbRideModelCamera = TableCombine(tbCamera.tbCameraPos, tbCamera.tbCameraLookPos)
    self.cameraRideModel    = self.cameraRideModel or camera_plus.CreateInstance(camera_plus)
    self:InitCamera(self.cameraRideModel, tbRideModelCamera, tbCamera.tbModelTranslation)
    UITouchHelper.BindModel(self.TouchContainer, self.hRideModelView, self.cameraRideModel, { tbFrame = tbFrame })
end

function UIAwardGatherView:UpdateHorseEquipModelInfo()
    if not self.aAchievement then
        return
    end
    local dwItemTabType  = self.aAchievement.dwItemType
    local dwItemTabIndex = self.aAchievement.dwItemID

    local itemInfo       = ItemData.GetItemInfo(dwItemTabType, dwItemTabIndex)
    if not itemInfo then
        return
    end

    local player        = g_pClientPlayer
    local tbRepresentID = player.GetRepresentID()
    local nRepresentSub = tHorseEquipToRe[itemInfo.nDetail]
    for _, nHorseEquipToRe in ipairs(tHorseEquipToRe) do
        tbRepresentID[nHorseEquipToRe] = 0
    end

    if itemInfo and itemInfo.nGenre == ITEM_GENRE.EQUIPMENT and itemInfo.nSub == EQUIPMENT_SUB.HORSE_EQUIP then
        tbRepresentID[nRepresentSub] = itemInfo.nRepresentID
    end

    local tbCamera = UICameraTab["Ride"][VIEW_ID.PanelAwardGather]

    self.hRideModelView:LoadResByRepresent(tbRepresentID, false)
    self.hRideModelView:LoadRidesModel()
    self.hRideModelView:PlayRidesAnimation("Idle", "loop")
    self.hRideModelView:SetCameraPos(unpack(tbCamera.tbCameraPos))
    self.hRideModelView:SetCameraLookPos(unpack(tbCamera.tbCameraLookPos))
    self.hRideModelView:SetCameraPerspective(unpack(tbCamera.tbCameraPerspective))
    self.hRideModelView:SetTranslation(unpack(tbCamera.tbModelTranslation))

    local fScale = Const.MiniScene.RideScale
    self.hRideModelView:SetScaling(fScale, fScale, fScale)
    self.hRideModelView:SetYaw(tbCamera.nModelYaw)
    self.hRideModelView:SetMainFlag(true)   -- 接收光照、阴影等

    local tbRideModelCamera = TableCombine(tbCamera.tbCameraPos, tbCamera.tbCameraLookPos)
    self.cameraRideModel    = self.cameraRideModel or camera_plus.CreateInstance(camera_plus)
    self:InitCamera(self.cameraRideModel, tbRideModelCamera, tbCamera.tbModelTranslation)
    UITouchHelper.BindModel(self.TouchContainer, self.hRideModelView, self.cameraRideModel, { tbFrame = tbFrame })
end

function UIAwardGatherView:UpdateMiddleItemIconInfo()
    if not self.aAchievement then
        return
    end
    local dwItemTabType  = self.aAchievement.dwItemType
    local dwItemTabIndex = self.aAchievement.dwItemID

    local itemInfo       = ItemData.GetItemInfo(dwItemTabType, dwItemTabIndex)
    if not itemInfo then
        return
    end
    -- UIHelper.SetItemIconByItemInfo(self.ImgGoods, itemInfo)
    -- self:LoadSetting(self.tFurniturModelSetting)

    -- UIHelper.SetVisible(self.WidgetAnchorMiddle, true)
    UIHelper.SetVisible(self.WidgetEmpty, true)
    UIHelper.SetVisible(self.WidgetDownloadBtnShell, false)
end

local function _FilterIndexToCollectStatus(idx)
    if idx == 1 then
        return AchievementData.GIFT_FILTER_TYPE.All
    elseif idx == 2 then
        return AchievementData.GIFT_FILTER_TYPE.Collected
    else
        return AchievementData.GIFT_FILTER_TYPE.NotCollected
    end
end

local function _FilterIndexToGiftType(idx)
    if idx == 1 then
        -- 全部
        return "all"
    else
        local nGiftIndex = idx - 1
        local tInfo      = AchievementData.tGiftType[nGiftIndex]
        return tInfo.nSub
    end
end

function UIAwardGatherView:ParseFilterResult(tbInfo)
    local nFilterIndex

    -- 获得情况
    AchievementData.tGiftFilterCollectStatus = {}
    nFilterIndex                             = FilterDef.AchievementAwardGather.IndexDef.CollectStatus
    for _, idx in ipairs(tbInfo[nFilterIndex]) do
        table.insert(AchievementData.tGiftFilterCollectStatus, _FilterIndexToCollectStatus(idx))
    end

    -- 物品类型
    AchievementData.tGiftFilterGiftType = {}
    nFilterIndex                        = FilterDef.AchievementAwardGather.IndexDef.GiftType
    for _, idx in ipairs(tbInfo[nFilterIndex]) do
        table.insert(AchievementData.tGiftFilterGiftType, _FilterIndexToGiftType(idx))
    end
end

function UIAwardGatherView:InitCamera(camera, tbCameraInfo, tMainPlayerPos)
    if not camera then
        return
    end
    local nWidth, nHeight = UIHelper.GetContentSize(self.MiniScene)
    camera:ctor()
    camera:init(
            self.hModelView.m_scene,
            tbCameraInfo[1], tbCameraInfo[2], tbCameraInfo[3], tbCameraInfo[4], tbCameraInfo[5], tbCameraInfo[6],
            math.pi / 4, nWidth / nHeight, nil, nil, true
    )
    if tMainPlayerPos then
        camera:set_mainplayer_pos(tMainPlayerPos[1], tMainPlayerPos[2], tMainPlayerPos[3])
    end
end

function UIAwardGatherView:LoadSetting(tSetting)
    local szSettingFile = "/ui/Scheme/Setting/CoinShopFurnitureSetting.ini"
    local pFile         = Ini.Open(szSettingFile)
    if not pFile then
        return
    end
    local szSection       = "FurnitureModelSetting"
    tSetting              = {}
    tSetting.CriterionX   = pFile:ReadInteger(szSection, "CriterionX", 0)
    tSetting.CriterionY   = pFile:ReadInteger(szSection, "CriterionY", 0)
    tSetting.CriterionZ   = pFile:ReadInteger(szSection, "CriterionZ", 0)
    tSetting.MaxScale     = pFile:ReadFloat(szSection, "MaxScale", 0)
    tSetting.MinScale     = pFile:ReadFloat(szSection, "MinScale", 0)
    tSetting.PlatformMesh = pFile:ReadString(szSection, "PlatformMesh", "")
    tSetting.PlatformX    = pFile:ReadFloat(szSection, "PlatformX", 0)
    tSetting.PlatformY    = pFile:ReadFloat(szSection, "PlatformY", 0)
    tSetting.PlatformZ    = pFile:ReadFloat(szSection, "PlatformZ", 0)
    tSetting.PlatformYaw  = pFile:ReadFloat(szSection, "PlatformYaw", 0)
    pFile:Close()
    Homeland_SendMessage(HOMELAND_FURNITURE.ENTER, self.hModelView.m_scene, tSetting.PlatformMesh, tSetting.PlatformX, tSetting.PlatformY, tSetting.PlatformZ, tSetting.PlatformYaw)
end

function UIAwardGatherView:UpdateDownloadEquipRes()
    if not PakDownloadMgr.IsEnabled() then
        return
    end
    if not self.hModelView then
        return
    end
    local nRoleType, tEquipList, tEquipSfxList = self.hModelView:GetPakEquipResource()
    local scriptDownload                       = UIHelper.GetBindScript(self.WidgetDownloadBtnShell)
    local tConfig                              = {}
    tConfig.bLong                              = true
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist   = PakDownloadMgr.UserCheckDownloadEquipRes(nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    CoinShopPreview.UpdateSimpleDownloadBtn(scriptDownload, self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

return UIAwardGatherView