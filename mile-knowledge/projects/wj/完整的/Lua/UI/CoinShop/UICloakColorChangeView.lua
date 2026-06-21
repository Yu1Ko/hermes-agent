-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICloakColorChangeView
-- Date: 2024-04-20 10:40:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local tRoleCameraInfo = {
    [ROLE_TYPE.STANDARD_MALE] = { -50, 151, -722, 120, 80, 78, 0.33, 1.77777779, 20, 40000, true }, --rtStandardMale,     // 标准男
    [ROLE_TYPE.STANDARD_FEMALE] = { -50, 151, -722, 50, 80, 78, 0.3, 1.77777779, 20, 40000, true }, --rtStandardFemale,   // 标准女
    [ROLE_TYPE.LITTLE_BOY] = { -50, 151, -722, 50, 65, 78, 0.27, 1.77777779, 20, 40000, true }, --rtLittleBoy,        // 小男孩
    [ROLE_TYPE.LITTLE_GIRL] = { -50, 143, -722, 50, 65, 78, 0.27, 1.77777779, 20, 40000, true }, --rtLittleGirl,       // 小孩女
}

local tRoleRadiusInfo =
{
    [ROLE_TYPE.STANDARD_MALE]   = { 380, 500}, --rtStandardMale, --标男常规镜头最近最远限制
    [ROLE_TYPE.STANDARD_FEMALE] = { 395, 500}, --rtStandardFemale,
    [ROLE_TYPE.STRONG_MALE]     = { 50, 160}, --rtStrongMale,
    [ROLE_TYPE.SEXY_FEMALE]     = { 50, 100}, --rtSexyFemale,
    [ROLE_TYPE.LITTLE_BOY]      = { 300, 390}, --rtLittleBoy,
    [ROLE_TYPE.LITTLE_GIRL]     = { 300, 390},  --rtLittleGirl,
}

local nRoleYaw = -3.36    -- 角色初始旋转


local UICloakColorChangeView = class("UICloakColorChangeView")

function UICloakColorChangeView:OnEnter(dwItemType, dwItemIndex, dwShowItemType, dwShowItemIndex, bFromItem)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:InitMiniScene()
    self.dwItemType = dwItemType
    self.dwItemIndex = dwItemIndex
    self.dwShowItemType = dwShowItemType
    self.dwShowItemIndex = dwShowItemIndex
    if bFromItem then
        self:InitGetFromItem(dwItemType, dwItemIndex, dwShowItemType, dwShowItemIndex)
    else
        self:UpdateInfo()
    end
end

function UICloakColorChangeView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    UITouchHelper.UnBindModel()
    if self.hModelView then
        if self.hModelView.m_scene then
            self.hModelView.m_scene:RestoreCameraLight()
        end
        self.hModelView:release()
        self.hModelView = nil
        self.camera = nil
    end

    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end
end

function UICloakColorChangeView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnRevert, EventType.OnClick, function()
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function()
        local dwItemType = self.dwItemType
        local dwItemIndex = self.dwItemIndex
        local tSelectColor = self.tSelectColor
        local szMsg = g_tStrings.CLOAK_CLOLOR_CHANGE_SURE
        UIHelper.ShowConfirm(szMsg, function()
            RemoteCallToServer("On_Pendent_ChangeCloakColor", dwItemType, dwItemIndex, tSelectColor)
            UIMgr.Close(self)
        end)
    end)

    UIHelper.BindUIEvent(self.ToggleCamera, EventType.OnSelectChanged, function(_, bSelected)
        local nRadius = bSelected and self.tRadius[2] or self.tRadius[1]
        self.camera:set_radius(nRadius)
    end)
end

function UICloakColorChangeView:RegEvent()
    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        self:UpdatePlayer()
    end)

    Event.Reg(self, EventType.OnMiniSceneLoadProgress, function(nProcess)
        if nProcess >= 100 then
            local scene = self.hModelView.m_scene
            if scene and not QualityMgr.bDisableCameraLight then
                scene:OpenCameraLight(QualityMgr.szCameraLightForUI)
            end
        end
    end)
end

function UICloakColorChangeView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICloakColorChangeView:InitMiniScene()
    self.hModelView = PlayerModelView.CreateInstance(PlayerModelView)
    self.hModelView:ctor()
    self.hModelView:InitBy({
        szName = "CloakColorChange",
        bExScene = true,
        szExSceneFile = "data\\source\\maps\\MB商城_2023_001\\MB商城_2023_001.jsonmap",
        bAPEX = false,
    })
    self.MiniScene:SetScene(self.hModelView.m_scene)
    -- UITouchHelper.BindModel(self.TouchContainer, self.hModelView)

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nRoleType = Player_GetRoleType(hPlayer)
    local tCameraInfo = tRoleCameraInfo[nRoleType]
    -- self.camera = self.camera or camera_plus.CreateInstance(camera_plus)
    self.hModelView:SetCamera(tCameraInfo)
    self.hModelView.m_scene:SetMainPlayerPosition(0, 0, 0)
    -- self:InitCamera(self.camera, tCameraInfo)
    -- self.tRadius = tRoleRadiusInfo[nRoleType]
    -- local tbFrame = { tRadius = self.tRadius }
    -- UITouchHelper.BindModel(self.TouchContainer, self.hModelView, self.camera, { tbFrame = tbFrame })
    UITouchHelper.BindModel(self.TouchContainer, self.hModelView)
    -- UIHelper.SetSelected(self.ToggleCamera, true)
    UIHelper.SetVisible(self.ToggleCamera, false)
end

function UICloakColorChangeView:InitCamera(camera, tbCameraInfo)
    if not camera then
        return
    end
    local nWidth, nHeight = UIHelper.GetContentSize(self.MiniScene)
    camera:ctor()
    camera:init(self.hModelView.m_scene, tbCameraInfo[1], tbCameraInfo[2], tbCameraInfo[3], tbCameraInfo[4], tbCameraInfo[5], tbCameraInfo[6], math.pi / 4, nWidth / nHeight, nil, nil, true)
end

function UICloakColorChangeView:UpdateInfo()
    local tColorList = CoinShop_CloakColor(self.dwItemType, self.dwItemIndex)
    local hItemInfo = GetItemInfo(self.dwShowItemType, self.dwShowItemIndex)
    local szItemName = ItemData.GetItemNameByItemInfo(hItemInfo)
    UIHelper.SetString(self.LabelName, string.format("%s", UIHelper.GBKToUTF8(szItemName)))
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetAnchorName, true, true)

    local tColor = hItemInfo.GetColorID()
    self.tSelectColor = tColor
    self:UpdateColorList(tColorList)
    self:UpdatePlayer()
end

function UICloakColorChangeView:UpdateColorList(tColorList)
    for nBlock in ipairs(self.tWidgetBlock) do
        UIHelper.SetVisible(self.tWidgetBlock[nBlock], false)
    end
    self.tColorCells = self.tColorCells or {}
    for nBlock, tBlock in ipairs(tColorList) do
        UIHelper.SetVisible(self.tWidgetBlock[nBlock], true)
        self.tColorCells[nBlock] = self.tColorCells[nBlock] or {}
        local layout = UIHelper.GetChildByName(self.tWidgetBlock[nBlock], "LayoutHanging")
        for nIndex, tRGB in ipairs(tBlock) do
            if not self.tColorCells[nBlock][nIndex] then
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFaceItem_80, layout)
                UIHelper.ToggleGroupAddToggle(self.tWidgetBlock[nBlock], script.ToggleSelect)
                UIHelper.SetSwallowTouches(script.ToggleSelect, false)
                self.tColorCells[nBlock][nIndex] = script
            end
            self.tColorCells[nBlock][nIndex]:OnEnter(10, { tColor = tRGB, fnAction = function()
                self.tSelectColor[nBlock] = nIndex
                self:UpdatePlayer()
            end })
            local bSelect = nIndex == self.tSelectColor[nBlock]
            if bSelect then
                UIHelper.SetToggleGroupSelected(self.tWidgetBlock[nBlock], nIndex - 1)
            end
        end
        UIHelper.LayoutDoLayout(layout)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)
end

function UICloakColorChangeView:UpdatePlayer()
    local yaw = self.hModelView:GetYaw()
    if yaw == 0 then
        yaw = nRoleYaw
    end
    self.hModelView:UnloadModel()

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tRepresentID = Role_GetRepresentID(hPlayer)
    local hItemInfo = GetItemInfo(self.dwShowItemType, self.dwShowItemIndex)
    local nRepresentSub, nRepresentColor = ExteriorView_GetRepresentSub(hItemInfo.nSub, hItemInfo.nDetail)
    tRepresentID[nRepresentSub] = hItemInfo.nRepresentID
    tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR1] = self.tSelectColor[1]
    tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR2] = self.tSelectColor[2]
    tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR3] = self.tSelectColor[3]
    self.tRepresentID = tRepresentID

    self.hModelView:LoadRes(hPlayer.dwID, tRepresentID)
    self.hModelView:LoadModel()
    self.hModelView:SetTranslation(0, 0, 0)
    self.hModelView:SetYaw(yaw)
    self.hModelView:PlayAnimation("Idle", "loop")

    self:UpdateDownloadEquipRes()
end

function UICloakColorChangeView:UpdateDownloadEquipRes()
    if not PakDownloadMgr.IsEnabled() then
        return
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    if not self.tRepresentID then
        return
    end
    local tEquipList, tEquipSfxList = Player_GetPakEquipResource(hPlayer.nRoleType, self.tRepresentID.nHatStyle, self.tRepresentID)
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownloadBtnShell)
    local tConfig = {}
    tConfig.bLong = true
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(hPlayer.nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    CoinShopPreview.UpdateSimpleDownloadBtn(scriptDownload, self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

--------------------------道具22992,22993------------------------------

local tSetCamera =
{
    [ROLE_TYPE.STANDARD_MALE]   = {-397, 23, -858, 0, 98, 0, 0.185}, --rtStandardMale,
    [ROLE_TYPE.STANDARD_FEMALE] = {-174, 63, -870, 0, 90, 0, 0.185}, --rtStandardFemale,
    [ROLE_TYPE.LITTLE_BOY]      = {95, -21, -669, 0, 71, 0, 0.185}, --rtLittleBoy,
    [ROLE_TYPE.LITTLE_GIRL]     = {86, 106, -647.4, 0, 68, 0, 0.185}  --rtLittleGirl,
}

local function GetListFromItem(dwTabType, dwIndex)
    local tSetList = GetExterior().GetExteriorPackInfo(dwTabType, dwIndex)
    local tList = {}
    for nIndex, nSetID in ipairs(tSetList) do
        if nSetID > 0 then
            local tSet = Table_GetExteriorSet(nSetID)
            table.insert(tList, tSet.tSub)
        end
    end
    return tList
end

local function GetSetInfo(tSet)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local nHave = 0
    local bHaveTime = false
    local bAskPay = false
    local bInStorage = false
    for _, dwID in ipairs(tSet) do
        local nTimeType, nTime = hPlayer.GetExteriorTimeLimitInfo(dwID)
        local nOwnType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwID)
        if nOwnType == COIN_SHOP_OWN_TYPE.STORAGE then
            bInStorage = true
        elseif nOwnType == COIN_SHOP_OWN_TYPE.PEER_PAY then
            bAskPay = true
        end
        local bHave = nTimeType and nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT
        if nTimeType and nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.SEVEN_DAYS_LIMIT then
            bHaveTime = true
        end
        if bHave then
            nHave = nHave + 1
        end
    end
    return nHave, bHaveTime, bAskPay, bInStorage
end
function UICloakColorChangeView:InitGetFromItem(dwTabType, dwIndex, dwBox, dwX)
    self.dwShowItemType = dwTabType
    self.dwShowItemIndex = dwIndex

    self.tList = GetListFromItem(dwTabType, dwIndex)

    self.nSelectIndex = 1
    self:UpdateColorList_Get(self.tList)
    self:UpdateChooseItemInfo()

    local iItemInfo = ItemData.GetItemInfo(dwTabType, dwIndex)
    local szItemName = UIHelper.GBKToUTF8(iItemInfo.szName)
    UIHelper.SetVisible(self.BtnRevert, false)
    UIHelper.SetString(self.LabelTitle, szItemName)
    UIHelper.SetString(self.LabelContent, "领取")
    UIHelper.SetVisible(self.ScrollViewList, false)
    UIHelper.SetVisible(self.WidgetExterior, true)

    local fnSure = function()
        local nSelect = self.nSelectIndex
        local dwID = self.tList[nSelect][1]
        local tExteriorInfo = GetExterior().GetExteriorInfo(dwID)
        RemoteCallToServer("On_Mall_GetFromItem", dwTabType, dwIndex, dwBox, dwX, tExteriorInfo.nSet)
        UIMgr.Close(self)
    end

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function()
        local nSelect = self.nSelectIndex
        local dwID = self.tList[nSelect][1]
        local tSet = self.tList[nSelect]
        local tExteriorInfo = GetExterior().GetExteriorInfo(dwID)
        local tSetInfo = Table_GetExteriorSet(tExteriorInfo.nSet)
        local szSetName = UIHelper.GBKToUTF8(tSetInfo.szSetName)

        local nHave, bHaveTime, bAskPay, bInStorage = GetSetInfo(tSet)
        local szMsg
        if bHaveTime then
            szMsg = FormatString(g_tStrings.EXTERIOR_GET_FROM_ITEM_MSG1, szSetName)
        else
            szMsg = FormatString(g_tStrings.EXTERIOR_GET_FROM_ITEM_MSG2, szSetName)
        end

        UIHelper.ShowConfirm(szMsg, fnSure)
    end)
end

function UICloakColorChangeView:UpdateChooseItemInfo()
    local dwID = self.tList[self.nSelectIndex][1]
    local tExteriorInfo = GetExterior().GetExteriorInfo(dwID)
    local tSetInfo = Table_GetExteriorSet(tExteriorInfo.nSet)

    UIHelper.SetString(self.LabelName, string.format("%s", UIHelper.GBKToUTF8(tSetInfo.szSetName)))
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetAnchorName, true, true)

    self:UpdatePlayer_GetFromItem(self.tList[self.nSelectIndex])
end

function UICloakColorChangeView:UpdateColorList_Get(tList)
    self.tColorCells = self.tColorCells or {}
    for nIndex, tInfo in ipairs(tList) do
        if not self.tColorCells[nIndex] then
            local dwID = tInfo[1]
            local tExteriorInfo = GetExterior().GetExteriorInfo(dwID)
            local tSetInfo = Table_GetExteriorSet(tExteriorInfo.nSet)
            local fnCallback = function(tog, bSelected)
                if bSelected then
                    self.nSelectIndex = nIndex
                    self:UpdateChooseItemInfo()
                end
            end
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetChangeCloakCell, self.ScrollViewExterior, UIHelper.GBKToUTF8(tSetInfo.szSetName), fnCallback)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupItem, script.TogChangeCloakCell)
            UIHelper.SetSwallowTouches(script.TogChangeCloakCell, false)
            self.tColorCells[nIndex] = script
        end
        --local bSelect =  nIndex == self.tSelectColor[nBlock]
        --if bSelect then
        --    UIHelper.SetToggleGroupSelected(self.tWidgetBlock[nBlock], nIndex-1)
        --end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewExterior)
end

function UICloakColorChangeView:UpdatePlayer_GetFromItem(tSetInfo)
    local yaw = self.hModelView:GetYaw()
    if yaw == 0 then
        yaw = 5.9
        --yaw = 6.5
    end

    self.hModelView:UnloadModel()

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tRepresentID = Role_GetRepresentID(hPlayer)

    local tRepresentSub =
    {
        EQUIPMENT_REPRESENT.HELM_STYLE,
        EQUIPMENT_REPRESENT.CHEST_STYLE,
        EQUIPMENT_REPRESENT.BANGLE_STYLE,
        EQUIPMENT_REPRESENT.WAIST_STYLE,
        EQUIPMENT_REPRESENT.BOOTS_STYLE,
        EQUIPMENT_REPRESENT.FACE_EXTEND,
        EQUIPMENT_REPRESENT.BACK_EXTEND,
        EQUIPMENT_REPRESENT.WAIST_EXTEND,
    }

    for _, nRepresentSub in ipairs(tRepresentSub) do
        tRepresentID[nRepresentSub] = 0
    end

    if tSetInfo then
        for _, dwID in ipairs(tSetInfo) do
            local tExteriorInfo = GetExterior().GetExteriorInfo(dwID)
            local nRepresentSub1 = Exterior_SubToRepresentSub(tExteriorInfo.nSubType)
            local nRepresentColor1 = Exterior_RepresentSubToColor(nRepresentSub1)
            tRepresentID[nRepresentSub1] = tExteriorInfo.nRepresentID
            tRepresentID[nRepresentColor1] = tExteriorInfo.nColorID
        end
    end

    self.tRepresentID = tRepresentID

    local nRoleType = hPlayer.nRoleType
    local tCamera = tSetCamera[nRoleType]
    --self.hModelView:SetCamera({tCamera[1], tCamera[2], tCamera[3], tCamera[4], tCamera[5], tCamera[6], tCamera[7] + 0.03})
    self.hModelView:UpdateRepresentID(tRepresentID, nRoleType)
    self.hModelView:SetTranslation(0, 0, 0)
    self.hModelView:SetYaw(yaw)
    self.hModelView:PlayAnimation("Idle", "loop")

    --self:UpdateDownloadEquipRes()
end

return UICloakColorChangeView