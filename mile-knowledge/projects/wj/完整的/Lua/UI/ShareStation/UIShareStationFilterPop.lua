-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShareStationFilterPop
-- Date: 2024-07-29 10:41:04
-- Desc: 分享站筛选弹窗
-- ---------------------------------------------------------------------------------
local SHARE_LIST_PAGE_SIZE = 5
local SHARE_MAP_LIST_PAGE_SIZE = 8
local SHARE_EFFECT_ROW_SIZE = 3  -- 特效筛选每页最多行数
local SHARE_EFFECT_COL_SIZE = 3  -- 每行最多特效数量
local UIShareStationFilterPop = class("UIShareStationFilterPop")

local tbNavTitles1 = {"外观类型", "选择外观"}
local tbNavTitles2 = {"外观类型", "详细类型", "选择外观"}

function UIShareStationFilterPop:OnEnter(nDataType, tbCurClassTitle)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nDataType = nDataType
    self.tFilterExterior = clone(ShareStationData.tFilterExterior) or {}
    UIHelper.SetVisible(self.TogHelp, self.nDataType == SHARE_DATA_TYPE.EXTERIOR)
    if self.nDataType == SHARE_DATA_TYPE.PHOTO then
        UIHelper.SetString(self.LabelTitle, "地图筛选")
        self.nPhotoMapType = ShareStationData.nPhotoMapType or -1
        self.dwPhotoMapID = ShareStationData.dwPhotoMapID or -1
        self.tRegionList = WorldMap_GetRegionOfWorldmap() or {}
        self.tMapRegion = Table_GetMapRegion() or {}

        -- 如果没有传入tbCurClassTitle，且已经有选择的地图，则自动生成对应的分类标题
        if not tbCurClassTitle or table.is_empty(tbCurClassTitle) then
            self:InitPhotoCurClassTitle()
        else
            self.tbCurClassTitle = tbCurClassTitle
        end
    else
        self.tbCurClassTitle = tbCurClassTitle or {}
    end

    self:UpdateInfo()
end

function UIShareStationFilterPop:OnExit()
    self.bInit = false
end

function UIShareStationFilterPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function(btn)
        if self.nDataType == SHARE_DATA_TYPE.PHOTO then
            self.tFilterExterior = {}
            self.nPhotoMapType = -1
            self.dwPhotoMapID = -1
        else
            self.tFilterExterior = {}
        end
        self.tbCurClassTitle = {}
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if self.nDataType == SHARE_DATA_TYPE.PHOTO then
            if self.nPhotoMapType == 0 or self.dwPhotoMapID == 0 then
                return
            end

            Event.Dispatch(EventType.OnFilterShareStationMap, self.nPhotoMapType, self.dwPhotoMapID)
        else
            Event.Dispatch(EventType.OnFilterShareStationExterior, self.tFilterExterior)
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function()
        self.nCurPage = self.nCurPage - 1
        if self.nCurPage < 1 then
            self.nCurPage = 1
        end
        if self.nDataType == SHARE_DATA_TYPE.PHOTO then
            self:UpdateMapList()
        else
            self:UpdateExteriorList()
        end
        UIHelper.SetText(self.EditPaginate, self.nCurPage)
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function()
        self.nCurPage = self.nCurPage + 1
        if self.nCurPage > self.nTotalPage then
            self.nCurPage = self.nTotalPage
        end
        if self.nDataType == SHARE_DATA_TYPE.PHOTO then
            self:UpdateMapList()
        else
            self:UpdateExteriorList()
        end
        UIHelper.SetText(self.EditPaginate, self.nCurPage)
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
            local nPage = tonumber(UIHelper.GetString(self.EditPaginate))
            nPage = math.max(1, math.min(nPage or 1, self.nTotalPage))

            if nPage >= 1 and nPage <= self.nTotalPage then
                self.nCurPage = nPage
                if self.nDataType == SHARE_DATA_TYPE.PHOTO then
                    self:UpdateMapList()
                else
                    self:UpdateExteriorList()
                end
            end
            UIHelper.SetText(self.EditPaginate, self.nCurPage)
        end)

        UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function()
            local szSearchText = UIHelper.GetString(self.EditKindSearch)
            self.szSearchText = szSearchText
            self:UpdateInfo()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditPaginate, function()
            local nPage = tonumber(UIHelper.GetString(self.EditPaginate))
            nPage = math.max(1, math.min(nPage or 1, self.nTotalPage))

            if nPage >= 1 and nPage <= self.nTotalPage then
                self.nCurPage = nPage
                if self.nDataType == SHARE_DATA_TYPE.PHOTO then
                    self:UpdateMapList()
                else
                    self:UpdateExteriorList()
                end
            end
            UIHelper.SetText(self.EditPaginate, self.nCurPage)
        end)

        UIHelper.RegisterEditBoxReturn(self.EditKindSearch, function()
            local szSearchText = UIHelper.GetString(self.EditKindSearch)
            self.szSearchText = szSearchText
            self:UpdateInfo()
        end)
    end
end

function UIShareStationFilterPop:RegEvent()
    UIHelper.SetTouchDownHideTips(self.TogHelp, false)
    UIHelper.SetScrollViewCombinedBatchEnabled(self.ScrollViewFilterListOther, false)

    Event.Reg(self, EventType.OnGameNumKeyboardConfirmed, function(editbox, nCurNum)
        local nPage = nCurNum
        nPage = math.max(1, math.min(nPage or 1, self.nTotalPage))

        if nPage >= 1 and nPage <= self.nTotalPage then
            self.nCurPage = nPage
            if self.nDataType == SHARE_DATA_TYPE.PHOTO then
                self:UpdateMapList()
            else
                self:UpdateExteriorList()
            end
        end
        UIHelper.SetText(self.EditPaginate, self.nCurPage)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetSelected(self.TogHelp, false)
    end)
end

--- 初始化照片类型下的当前分类标题
function UIShareStationFilterPop:InitPhotoCurClassTitle(tbCurClassTitle)
    self.tbCurClassTitle = {}
    -- 获取地图类型列表
    local tbMapTypeList = self:GetMapTypeList()

    if self.nPhotoMapType == 0 then
        -- 已经选择了全部地图类型，添加到当前分类标题
        for _, tMapType in ipairs(tbMapTypeList) do
            if tMapType.nType == 0 then
                table.insert(self.tbCurClassTitle, tMapType)
                break
            end
        end
    elseif self.nPhotoMapType == SHARE_PHOTO_MAP_TYPE.NORMAL then
        -- 已经选择了大世界地图类型
        for _, tMapType in ipairs(tbMapTypeList) do
            if tMapType.nType == SHARE_PHOTO_MAP_TYPE.NORMAL then
                table.insert(self.tbCurClassTitle, tMapType)
                break
            end
        end

        -- 如果有具体的地图ID，查找对应的区域
        if self.dwPhotoMapID > 0 then
            -- 获取区域列表
            local tbRegionList = self:GetMapRegionList()
            -- 查找地图ID所属的区域
            for dwRegionID, tMapList in pairs(self.tMapRegion) do
                if table.contain_value(tMapList, self.dwPhotoMapID) then
                    -- 找到对应的区域，添加到当前分类标题
                    for _, tRegion in ipairs(tbRegionList) do
                        if tRegion.nSubType == dwRegionID then
                            table.insert(self.tbCurClassTitle, tRegion)
                            break
                        end
                    end
                    break
                end
            end
        end
    elseif self.nPhotoMapType == SHARE_PHOTO_MAP_TYPE.SELFIE_STUDIO then
        -- 已经选择了万景阁地图类型
        for _, tMapType in ipairs(tbMapTypeList) do
            if tMapType.nType == SHARE_PHOTO_MAP_TYPE.SELFIE_STUDIO then
                table.insert(self.tbCurClassTitle, tMapType)
                break
            end
        end
    end
end

function UIShareStationFilterPop:Init()
    self.nMainType, self.nSubType = -1, -1  -- 主类，子类
    if table.is_empty(self.tbCurClassTitle) then
        return
    end

    if self.nDataType == SHARE_DATA_TYPE.PHOTO then
        -- 地图类型逻辑
        local tMainTitleInfo = self.tbCurClassTitle[1]
        local tSubTitleInfo = self.tbCurClassTitle[2]
        
        if tMainTitleInfo then
            self.nMainType = tMainTitleInfo.nType
            -- 当maintype为万景阁时，subtype可以直接设置为0
            if self.nMainType == SHARE_PHOTO_MAP_TYPE.SELFIE_STUDIO then
                self.nSubType = 0
            end
        end
        
        if tSubTitleInfo then
            -- 当有子标题信息时，设置subtype为区域ID
            self.nSubType = tSubTitleInfo.nSubType or tSubTitleInfo.nType
        end
    else
        -- 原外观逻辑
        local tMainTitleInfo = self.tbCurClassTitle[1]
        local tSubTitleInfo = self.tbCurClassTitle[2]

        if tMainTitleInfo then
            self.nMainType = tMainTitleInfo.nType
            if self.nMainType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
                if tMainTitleInfo.tRewardsClassList[1] == 1 then -- 成衣
                    self.nSubType = tMainTitleInfo.tRewardsClassList[1]
                elseif tSubTitleInfo then
                    self.nSubType = tMainTitleInfo.tRewardsClassList[1]
                    return
                end
            elseif self.nMainType == COIN_SHOP_GOODS_TYPE.ITEM
                and tMainTitleInfo.tRewardsClassList
                and tMainTitleInfo.tRewardsClassList[1] == REWARDS_CLASS.EFFECT then
                -- 特效需要二级类型选择，暂不设置 nSubType
            elseif self.nMainType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
                self.nSubType = 0
            elseif self.nMainType ~= COIN_SHOP_GOODS_TYPE.HAIR then
                self.nSubType = tMainTitleInfo.tRewardsClassList[1]
            end
        end

        if tSubTitleInfo then
            self.nSubType = tSubTitleInfo.nShowType
        end
    end
end

function UIShareStationFilterPop:UpdateInfo()
    self.tbNavCells = {}
    self.tbCurClassTitle = self.tbCurClassTitle or {}
    self:Init()

    local tbNavTitles = tbNavTitles1
    if self.nDataType == SHARE_DATA_TYPE.PHOTO then
        if self.nMainType == SHARE_PHOTO_MAP_TYPE.NORMAL and self.nSubType >= 0 then
            tbNavTitles = {"地图类型", "选择区域", "选择地图"}
        else
            tbNavTitles = {"地图类型", "选择地图"}
        end
    elseif self.nMainType >= 0 and type(self.nSubType) ~= "string" and self.nSubType < 0 then
        tbNavTitles = tbNavTitles2
    end

    UIHelper.RemoveAllChildren(self.ScrollViewBreadNaviScreen)
    for nIndex, szTitle in ipairs(tbNavTitles) do
        if #self.tbCurClassTitle >= nIndex - 1 then
            local szTitleName = self.tbCurClassTitle[nIndex] and self.tbCurClassTitle[nIndex].tTitleInfo and self.tbCurClassTitle[nIndex].tTitleInfo.szName
            local szOption = szTitleName and UIHelper.GBKToUTF8(szTitleName) or szTitle
            local nCellPrefabID = PREFAB_ID.WidgetPublicBreadNaviCell

            if #szOption > 24 then
                nCellPrefabID = PREFAB_ID.WidgetPublicBreadNaviCellLong
            end

            if not self.tbNavCells[nIndex] then
                self.tbNavCells[nIndex] = UIHelper.AddPrefab(nCellPrefabID, self.ScrollViewBreadNaviScreen)
            end

            UIHelper.SetVisible(self.tbNavCells[nIndex]._rootNode, true)
            self.tbNavCells[nIndex]:OnEnter({szOption = szOption}, nIndex == 1, function ()
                self:RemoveClassTitle(nIndex)
            end)
            self.tbNavCells[nIndex]:SetChecked(#self.tbCurClassTitle > nIndex - 1 or #self.tbCurClassTitle == 0)
        end
    end

    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end

    self.nTimer = Timer.AddFrame(self, 1 ,function()
        UIHelper.ScrollViewDoLayout(self.ScrollViewBreadNaviScreen)
        UIHelper.ScrollToLeft(self.ScrollViewBreadNaviScreen, 0, false)
        if #self.tbCurClassTitle > 2 then
            UIHelper.ScrollToRight(self.ScrollViewBreadNaviScreen, 0, false)
        end
    end)

    if self.nDataType == SHARE_DATA_TYPE.PHOTO then
        -- 地图列表逻辑
        local bShowMapList = (self.nMainType >= 0 and (self.nMainType ~= SHARE_PHOTO_MAP_TYPE.NORMAL or self.nSubType >= 0)) or self.nMainType == 0
        if bShowMapList then
            self.tbData = self:GetMapListByType(self.nMainType, self.nSubType)
            self.tbData = self:FilterMapData(self.tbData, self.szSearchText or "")
            self:UpdateMapList(true)
        else
            if self.nMainType == SHARE_PHOTO_MAP_TYPE.NORMAL and self.nSubType < 0 then
                -- 大世界类型下，显示区域列表
                self.tbData = self:GetMapRegionList()
            else
                -- 其他情况，显示地图类型列表
                self.tbData = self:GetMapTypeList()
            end
            self:UpdateTitileList()
        end
    else
        -- 原外观列表逻辑
        local bShowExteriorList = self.nMainType >= 0 and (type(self.nSubType) == "string" or self.nSubType >= 0)
        if bShowExteriorList then
            self.tbData = ShareExteriorData.GetFilterList(self.nMainType, self.nSubType)
            self.tbData = self:FilterData(self.tbData, self.szSearchText or "")
            self:UpdateExteriorList(true)
        else
            if self.nMainType >= 0 then
                local tCurMainTitle = self.tbCurClassTitle[1]
                local nMainClass = tCurMainTitle and tCurMainTitle.tRewardsClassList and tCurMainTitle.tRewardsClassList[1] or -1
                self.tbData = ShareExteriorData.GetFilterSubTitle(self.nMainType, nMainClass)
            else
                self.tbData = ShareExteriorData.GetFilterTitle()
                self:ParseChestConfilct(self.tbData)
            end
            self:UpdateTitileList()
        end
    end
end

function UIShareStationFilterPop:UpdateExteriorList(bInitPage)
    UIHelper.SetVisible(self.WidgetContentWuCai, false)
    UIHelper.SetVisible(self.WidgetContentOther, true)

    local tMainTitle = self.tbCurClassTitle[1] or {}
    local tSubTitle = self.tbCurClassTitle[2] or {}

    local bIsEffect = tMainTitle.tRewardsClassList and tMainTitle.tRewardsClassList[1] == REWARDS_CLASS.EFFECT
    local nPageSize = bIsEffect and (SHARE_EFFECT_ROW_SIZE * SHARE_EFFECT_COL_SIZE) or SHARE_LIST_PAGE_SIZE

    if bInitPage then
        local nMaxPage = self.tbData and math.ceil(#self.tbData / nPageSize) or 1
        self.nCurPage = 1
        self.nTotalPage = math.max(1, nMaxPage)
        UIHelper.SetText(self.EditPaginate, self.nCurPage)
        UIHelper.SetString(self.LabelPaginate, "/"..nMaxPage)
    end

    local bEmpty = true
    local nCount = self:GetSeletctCount(tMainTitle)
    local bFull = nCount >= tMainTitle.nMaxFilterNum
    if tSubTitle and tSubTitle.nMaxFilterNum then
        nCount = self:GetSeletctCount(tSubTitle)
        bFull = nCount >= tSubTitle.nMaxFilterNum
    end

    UIHelper.HideAllChildren(self.ScrollViewFilterListOther)
    if bIsEffect then
        self.tbEffectRowCells = self.tbEffectRowCells or {}
        local nPageBase = (self.nCurPage - 1) * nPageSize
        for iRow = 1, SHARE_EFFECT_ROW_SIZE do
            local nRowBase = nPageBase + (iRow - 1) * SHARE_EFFECT_COL_SIZE
            -- 统计本行实际有数据的列数
            local nRowCount = 0
            for jCol = 1, SHARE_EFFECT_COL_SIZE do
                if self.tbData[nRowBase + jCol] then
                    nRowCount = nRowCount + 1
                end
            end

            if nRowCount > 0 then
                if not self.tbEffectRowCells[iRow] then
                    self.tbEffectRowCells[iRow] = UIHelper.AddPrefab(PREFAB_ID.WidgetShareStationFilterEffectItem, self.ScrollViewFilterListOther)
                    self.tbEffectRowCells[iRow].tbInnerCells = {}
                end
                local scriptRow = self.tbEffectRowCells[iRow]
                UIHelper.SetVisible(scriptRow._rootNode, true)

                -- 隐藏行内所有子节点，再按需显示
                UIHelper.HideAllChildren(scriptRow.LayoutEffectCell)
                scriptRow.tbInnerCells = scriptRow.tbInnerCells or {}
                for jCol = 1, nRowCount do
                    local tData = self.tbData[nRowBase + jCol]
                    if not scriptRow.tbInnerCells[jCol] then
                        scriptRow.tbInnerCells[jCol] = UIHelper.AddPrefab(PREFAB_ID.WidgetAccessoryEffect, scriptRow.LayoutEffectCell)
                    end
                    local scriptCell = scriptRow.tbInnerCells[jCol]
                    UIHelper.SetVisible(scriptCell._rootNode, true)
                    self:InitEffectFilterCell(scriptCell, tData, bFull)
                    bEmpty = false
                end
                UIHelper.LayoutDoLayout(scriptRow.LayoutEffectCell)
            end
        end
    else
        self.tbListCells = self.tbListCells or {}
        for i = 1, SHARE_LIST_PAGE_SIZE, 1 do
            local nIndex = (self.nCurPage - 1) * SHARE_LIST_PAGE_SIZE + i
            local tData = self.tbData[nIndex]
            if tData then
                if not self.tbListCells[i] then
                    self.tbListCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetSuitItem, self.ScrollViewFilterListOther)
                    local x = UIHelper.GetPositionX(self.tbListCells[i].TogPetList)
                    UIHelper.SetPositionX(self.tbListCells[i].TogPetList, x - 15)
                end
                self:InitExteriorCell(self.tbListCells[i], tData, bFull)
                UIHelper.SetVisible(self.tbListCells[i]._rootNode, true)
                bEmpty = false
            else
                UIHelper.ScrollViewDoLayout(self.ScrollViewFilterListOther)
                UIHelper.ScrollToTop(self.ScrollViewFilterListOther)
            end
        end
    end

    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
    UIHelper.ScrollViewDoLayout(self.ScrollViewFilterListOther)
    UIHelper.ScrollToTop(self.ScrollViewFilterListOther)
end

function UIShareStationFilterPop:InitEffectFilterCell(scriptCell, tData, bFull)
    local tbInfo = {
        dwEffectID = tData.dwEffectID or 0,
        szImgPath  = tData.szImgPath  or "",
        szName     = tData.szName     or "",
    }

    scriptCell:OnEnter(tbInfo, 0)
    UIHelper.SetVisible(scriptCell.Eff_Rectangle, false)
    UIHelper.SetVisible(scriptCell.ImgCollectIcon, false)
    UIHelper.SetVisible(scriptCell.ImgEquipped, false)

    -- 覆盖 toggle 为筛选选中状态
    local szEffectKey = tData.szEffectType or ""
    local tCurSelected = self.tFilterExterior[szEffectKey]
    local bHaveSelected = tCurSelected ~= nil and table.contain_value(tCurSelected, tData.dwEffectID)
    scriptCell:SetSelected(bHaveSelected)

    UIHelper.SetNodeGray(scriptCell._rootNode, bFull and not bHaveSelected, true)
    UIHelper.SetEnable(scriptCell.TogAccessoryEffect, not bFull or bHaveSelected)

    scriptCell:SetClickCallback(function(cell)
        local bNewSelected = UIHelper.GetSelected(cell.TogAccessoryEffect)
        self:OnSelectExterior(tData, bNewSelected)

        -- 显示特效详情tips
        if bNewSelected then
            local tips, scriptCell = TipsHelper.ShowItemTips(self._rootNode, "Effect", tData.dwEffectID or 0, false)
            scriptCell:SetBtnState({})
            tips:SetOffset(450, 0)
        end
    end)
end

function UIShareStationFilterPop:UpdateTitileList()
    self.szSearchText = nil
    UIHelper.SetText(self.EditKindSearch, "")
    UIHelper.SetVisible(self.WidgetContentWuCai, true)
    UIHelper.SetVisible(self.WidgetContentOther, false)
    UIHelper.SetVisible(self.WidgetEmpty, false)

    UIHelper.HideAllChildren(self.ScrollViewFilterList)
    self.tbCells = self.tbCells or {}
    for i, v in ipairs(self.tbData) do
        local bIsPhoto = self.nDataType == SHARE_DATA_TYPE.PHOTO
        local nPrefabID = bIsPhoto and PREFAB_ID.WidgetFilterItemCell or PREFAB_ID.WidgetMaterialCellWuCai

        if not self.tbCells[i] then
            self.tbCells[i] = UIHelper.AddPrefab(nPrefabID, self.ScrollViewFilterList)
        end

        local tTitleInfo = v.tTitleInfo
        local szName = UIHelper.GBKToUTF8(tTitleInfo.szName)
        if bIsPhoto then
            UIHelper.SetVisible(self.tbCells[i].ImgNext, true)
            self.tbCells[i]:OnEnter({szOption = szName}, function()
                self:OnSelectTitle(v, true)
            end)
        else
            local nCount = self:GetSeletctCount(v)
            self.tbCells[i]:OnInitWithCount(szName, nCount, v.nMaxFilterNum)
            self.tbCells[i]:SetSelectedCallback(function (bSelected)
                self:OnSelectTitle(v, bSelected)
            end)

            UIHelper.SetNodeGray(self.tbCells[i]._rootNode, v.bGray or false, true)
            UIHelper.SetEnable(self.tbCells[i].TogFilterItem, not v.bGray)
            UIHelper.SetOpacity(self.tbCells[i]._rootNode, v.bGray and 153 or 255)
        end
        UIHelper.SetVisible(self.tbCells[i]._rootNode, true)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFilterList)
end

local function _fnGetDataNameByType(nType, tData, nSubType)
    local szName, szType = "", ""
    if nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        szName = UIHelper.GBKToUTF8(tData.szSetName)
    elseif nType == COIN_SHOP_GOODS_TYPE.HAIR then
        local nHairID = tData.nHairID
        szName = CoinShopHair.GetHairText(nHairID) or ""
        szName = UIHelper.GBKToUTF8(szName)
    elseif nType == COIN_SHOP_GOODS_TYPE.ITEM then
        if type(nSubType) == "string" then -- 特效
            szName = UIHelper.GBKToUTF8(tData.szName or "")
        else -- 挂件/挂宠
            szName = ItemData.GetItemNameByItemInfoIndex(ITEM_TABLE_TYPE.CUST_TRINKET, tData.dwItemIndex)
            szName = UIHelper.GBKToUTF8(szName)
        end
    elseif nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then -- 武器
        local tWeaponInfo = CoinShop_GetWeaponInfo(tData.dwID)
        szName = UIHelper.GBKToUTF8(tWeaponInfo and tWeaponInfo.szName or "")
    end
    return szName, szType
end

function UIShareStationFilterPop:InitExteriorCell(scriptCell, tData, bFull)
    local nType = self.nMainType
    local tTopTitle = self.tbCurClassTitle[1] or {}
    local tSubTitle = self.tbCurClassTitle[2] or {}

    local tInfo = {}
    local bHaveSelected = false
    local dwTabType = "" -- 同步UIItemTip命名
    local dwGoodsID = 0
    local eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR

    local szName, szSubType = _fnGetDataNameByType(nType, tData, self.nSubType)
    if table.is_empty(tSubTitle) or nType == COIN_SHOP_GOODS_TYPE.HAIR then
        szSubType = tTopTitle.tTitleInfo.szName or ""
        szSubType = UIHelper.GBKToUTF8(szSubType)
    else
        szSubType = tSubTitle.tTitleInfo.szName or ""
        szSubType = UIHelper.GBKToUTF8(szSubType)
    end

    for _, nRes in pairs(tTopTitle.tSub) do
        local tCurSelected = self.tFilterExterior[nRes]
        if nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
            dwTabType = "EquipExterior"
            eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
            dwGoodsID = tData["nSub2"] > 0 and tData["nSub2"]

            local nSubIndex = ShareExteriorData.GetExteriorSubIndex(nRes)
            if tSubTitle and tSubTitle.tSub then
                nRes = tSubTitle.tSub[1]
                nSubIndex = ShareExteriorData.GetExteriorSubIndex(nRes)
                dwGoodsID = tData["nSub"..nSubIndex]
                tCurSelected = self.tFilterExterior[nRes]
            end

            if tData["nSub"..nSubIndex] and tData["nSub"..nSubIndex] > 0 and tCurSelected then
                bHaveSelected = table.contain_value(tCurSelected, tData["nSub"..nSubIndex])
            end
        elseif nType == COIN_SHOP_GOODS_TYPE.HAIR then
            dwTabType = "Hair"
            dwGoodsID = tData.nHairID
            eGoodsType = COIN_SHOP_GOODS_TYPE.HAIR
            bHaveSelected = table.contain_value(tCurSelected, tData.nHairID)
        elseif nType == COIN_SHOP_GOODS_TYPE.ITEM then
            -- 挂件/挂宠
            dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
            dwGoodsID = tData.dwItemIndex
            eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM
            bHaveSelected = table.contain_value(tCurSelected, tData.dwItemIndex)
        elseif nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
            dwTabType = "WeaponExterior"
            dwGoodsID = tData.dwID
            eGoodsType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR
            bHaveSelected = tCurSelected ~= nil and table.contain_value(tCurSelected, tData.dwID)
        end
    end

    tInfo.szName = UIHelper.LimitUtf8Len(szName, 8)
    tInfo.szSubType = szSubType
    tInfo.dwTabType = dwTabType
    tInfo.bSelected = bHaveSelected
    tInfo.dwGoodsID = dwGoodsID
    tInfo.eGoodsType = eGoodsType
    tInfo.bHave = tData.bHave

    UIHelper.SetNodeGray(scriptCell._rootNode, bFull and not bHaveSelected, true)
    UIHelper.SetEnable(scriptCell.TogPetList, not bFull or bHaveSelected)
    scriptCell:OnInitWithGoods(tInfo, nType, function (bSelected)
        self:OnSelectExterior(tData, bSelected)
    end)
end

function UIShareStationFilterPop:FilterData(tbData, szSearchText)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return {}
    end

    local nType = self.nMainType
    local tTopTitle = self.tbCurClassTitle[1] or {}
    local tSubTitle = self.tbCurClassTitle[2] or {}

    local tbFilterData = {}
    for _, tData in ipairs(tbData) do
        local dwID = 0
        local bHave = false
        local bTiming = false
        local bSourceValid = not tData.dwSource or tData.dwSource > 0

        if nType == COIN_SHOP_GOODS_TYPE.HAIR then
            dwID = tData.nHairID
        elseif nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then --暂时只考虑成衣
            local nSubPart = ShareExteriorData.GetExteriorSubIndex(EQUIPMENT_REPRESENT.CHEST_STYLE)
            if tSubTitle and tSubTitle.nShowType then
                nSubPart = ShareExteriorData.GetExteriorSubIndex(tSubTitle.nShowType)
            end
            dwID = tData["nSub" .. nSubPart]
        elseif nType == COIN_SHOP_GOODS_TYPE.ITEM then
            if type(self.nSubType) == "string" then -- 特效
                dwID = tData.dwEffectID or 0
            else -- 挂件/挂宠
                dwID = tData.dwItemIndex

                local tItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwID)
                if tItemInfo then
                    bTiming = tItemInfo.nExistType ~= ITEM_EXIST_TYPE.PERMANENT
                end
            end
        elseif nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then -- 武器
            dwID = tData.dwID
        end

        local szName = _fnGetDataNameByType(nType, tData, self.nSubType)
        if szSearchText == "" or (szName and string.find(szName, szSearchText)) and not string.find(szName, "·包身") then
            if dwID > 0 then
                if nType == COIN_SHOP_GOODS_TYPE.ITEM then
                    if type(self.nSubType) == "string" then
                        bHave = pPlayer.IsSFXAcquired(dwID)
                    else
                        local dwItemIndex = tData.dwItemIndex
                        bHave = ItemData.IsItemCollected(ITEM_TABLE_TYPE.CUST_TRINKET, dwItemIndex)
                    end
                else
                    local nOwnType = GetCoinShopClient().CheckAlreadyHave(nType, dwID)
                    bHave = nOwnType == COIN_SHOP_OWN_TYPE.EQUIP or nOwnType == COIN_SHOP_OWN_TYPE.FREE_TRY_ON
                end
                tData.dwID = dwID
                tData.bHave = bHave

                -- 排除未拥有的限时/获取途径未知的挂件；武器全部展示
                if nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR or bHave or (not bTiming and bSourceValid) then
                    table.insert(tbFilterData, tData)
                end
            end
        end
    end

    local _CheckIsSelected = function (dwID, tItemData)
        if not self.tFilterExterior then
            return false
        end

        if type(self.nSubType) == "string" and tItemData and tItemData.szEffectType then
            local tCurSelected = self.tFilterExterior[tItemData.szEffectType]
            return tCurSelected and table.contain_value(tCurSelected, dwID)
        end

        for _, nRes in pairs((self.tbCurClassTitle[1] or {}).tSub or {}) do
            local tCurSelected = self.tFilterExterior[nRes]
            if tCurSelected and table.contain_value(tCurSelected, dwID) then
                return true
            end
        end

        return false
    end

    local fnSort = function (t1, t2)
        local bSelected1, bSelected2 = false, false
        if self.tFilterExterior then
            bSelected1 = _CheckIsSelected(t1.dwID, t1)
            bSelected2 = _CheckIsSelected(t2.dwID, t2)
        end

        if bSelected1 ~= bSelected2 then
            return bSelected1
        end
        local nSort1 = t1.bHave and 1 or 0
        local nSort2 = t2.bHave and 1 or 0
        if nSort1 == nSort2 then
            return t1.dwID > t2.dwID
        end
        return nSort1 > nSort2
    end

    if nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        local fnWeaponSort = function(t1, t2)
            local bSelected1 = _CheckIsSelected(t1.dwID, t1)
            local bSelected2 = _CheckIsSelected(t2.dwID, t2)
            if bSelected1 ~= bSelected2 then
                return bSelected1
            end
            local n1 = t1.bHave and 1 or 0
            local n2 = t2.bHave and 1 or 0
            if n1 ~= n2 then
                return n1 > n2
            end
            local s1 = t1.nSubType or 0
            local s2 = t2.nSubType or 0
            if s1 ~= s2 then
                return s1 > s2
            end
            return t1.dwID > t2.dwID
        end
        table.sort(tbFilterData, fnWeaponSort)
    else
        table.sort(tbFilterData, fnSort)
    end

    return tbFilterData
end

function UIShareStationFilterPop:GetSeletctCount(tTitleInfo)
    local nCount = 0
    if not tTitleInfo or not self.tFilterExterior then
        return nCount
    end

    local bChest = tTitleInfo and tTitleInfo.nType == COIN_SHOP_GOODS_TYPE.EXTERIOR and tTitleInfo.tRewardsClassList[1] == 1
    local bSubSet = tTitleInfo and tTitleInfo.nType == COIN_SHOP_GOODS_TYPE.EXTERIOR and tTitleInfo.tRewardsClassList[1] == 2

    local tSub = tTitleInfo.tSub
    if not tSub then
        return nCount
    end

    for _, v in ipairs(tSub) do
        local szKey = v
        if self.tFilterExterior[szKey] then
            if bChest or bSubSet then
                for k, dwVal in pairs(self.tFilterExterior[szKey]) do
                    local nClass = ShareExteriorData.GetExteriorClass(dwVal)
                    local bIsChest = ShareExteriorData.IsChestClass(nClass)
                    if bChest and bIsChest then --成衣
                        nCount = nCount + 1
                    elseif bSubSet and not bIsChest then
                        nCount = nCount + 1
                    end
                end
            else
                nCount = nCount + table.GetCount(self.tFilterExterior[szKey])
            end
        end
    end

    return nCount
end

function UIShareStationFilterPop:OnSelectTitle(tTitle, bSelected)
    if self.nDataType == SHARE_DATA_TYPE.PHOTO then
        -- 地图类型选择逻辑
        if bSelected then
            if tTitle.nType == 0 then
                -- 选择全部，显示所有地图列表
                table.insert(self.tbCurClassTitle, tTitle)
                -- 临时存储地图类型为全部
                self.nMainType = 0
            else
                -- 选择具体地图类型，添加到当前分类标题
                table.insert(self.tbCurClassTitle, tTitle)
                -- 临时更新过滤器的地图类型
                self.nMainType = tTitle.nType
            end
        end
    else
        -- 原外观类型选择逻辑
        if bSelected then
            table.insert(self.tbCurClassTitle, tTitle)
        end
    end
    self:UpdateInfo()
end

function UIShareStationFilterPop:GetMapTypeList()
    local tbMapTypeList = {}

    -- 全部选项
    table.insert(tbMapTypeList, {
        tTitleInfo = { szName = UIHelper.UTF8ToGBK("全部") },
        nType = 0,
        tSub = { "nPhotoMapType" },
        nMaxFilterNum = 1
    })

    -- 大世界选项
    table.insert(tbMapTypeList, {
        tTitleInfo = { szName = UIHelper.UTF8ToGBK("大世界") },
        nType = SHARE_PHOTO_MAP_TYPE.NORMAL,
        tSub = { "nPhotoMapType" },
        nMaxFilterNum = 1
    })

    -- 万景阁选项
    table.insert(tbMapTypeList, {
        tTitleInfo = { szName = UIHelper.UTF8ToGBK("万景阁") },
        nType = SHARE_PHOTO_MAP_TYPE.SELFIE_STUDIO,
        tSub = { "nPhotoMapType" },
        nMaxFilterNum = 1
    })

    return tbMapTypeList
end

function UIShareStationFilterPop:GetMapRegionList()
    local tbRegionList = {}

    for _, tRegion in ipairs(self.tRegionList) do
        table.insert(tbRegionList, {
            tTitleInfo = { szName = tRegion.szRegionName },
            nType = SHARE_PHOTO_MAP_TYPE.NORMAL,
            nSubType = tRegion.dwRegionID, -- 区域ID作为子类型
            tSub = { "nPhotoMapType" },
            nMaxFilterNum = 1
        })
    end

    return tbRegionList
end

function UIShareStationFilterPop:GetMapListByType(nMapType, nSubType)
    local tbMapList = {}
    if nMapType == -1 or nMapType == 0 then
        -- 全部地图，包括大世界所有区域和万景阁
        -- 大世界地图：遍历所有区域，获取每个区域的所有地图
        for _, tRegion in ipairs(self.tRegionList) do
            local tMapListInRegion = self.tMapRegion[tRegion.dwRegionID] or {}
            for _, dwMapID in ipairs(tMapListInRegion) do
                local szMapName = Table_GetMapName(dwMapID)
                if szMapName ~= "" then
                    table.insert(tbMapList, {
                        dwMapID = dwMapID,
                        szName = szMapName,
                        nMapType = SHARE_PHOTO_MAP_TYPE.NORMAL,
                        szRegionName = tRegion.szRegionName -- 保存区域名称，方便搜索和显示
                    })
                end
            end
        end

        -- 万景阁地图：获取所有万景阁
        local tAllSelfieStudio = Table_GetAllSelfieStudio() or {}
        for _, tStudio in ipairs(tAllSelfieStudio) do
            table.insert(tbMapList, {
                dwMapID = tStudio.dwID,
                szName = tStudio.szName,
                nMapType = SHARE_PHOTO_MAP_TYPE.SELFIE_STUDIO,
                szRegionName = "万景阁" -- 万景阁作为一个特殊区域
            })
        end
    elseif nMapType == SHARE_PHOTO_MAP_TYPE.NORMAL then
        -- 大世界地图，根据nSubType过滤区域
        if nSubType > 0 then
            -- 只显示指定区域的地图
            local tMapListInRegion = self.tMapRegion[nSubType] or {}
            for _, dwMapID in ipairs(tMapListInRegion) do
                local szMapName = Table_GetMapName(dwMapID)
                if szMapName ~= "" then
                    table.insert(tbMapList, {
                        dwMapID = dwMapID,
                        szName = szMapName,
                        nMapType = SHARE_PHOTO_MAP_TYPE.NORMAL
                    })
                end
            end
        end
    elseif nMapType == SHARE_PHOTO_MAP_TYPE.SELFIE_STUDIO then
        -- 万景阁地图
        local tAllSelfieStudio = Table_GetAllSelfieStudio() or {}
        for _, tStudio in ipairs(tAllSelfieStudio) do
            table.insert(tbMapList, {
                dwMapID = tStudio.dwID,
                szName = tStudio.szName,
                nMapType = SHARE_PHOTO_MAP_TYPE.SELFIE_STUDIO
            })
        end
    end

    return tbMapList
end

function UIShareStationFilterPop:UpdateMapList(bInitPage)
    UIHelper.SetVisible(self.WidgetContentWuCai, false)
    UIHelper.SetVisible(self.WidgetContentOther, true)
    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupOtherCell)
    UIHelper.SetToggleGroupAllowedNoSelection(self.TogGroupOtherCell, true)

    -- 使用地图列表每页显示数量
    local nPageSize = SHARE_MAP_LIST_PAGE_SIZE
    if bInitPage then
        local nMaxPage = self.tbData and math.ceil(#self.tbData / nPageSize) or 1
        self.nCurPage = 1
        self.nTotalPage = math.max(1, nMaxPage)
        UIHelper.SetText(self.EditPaginate, self.nCurPage)
        UIHelper.SetString(self.LabelPaginate, "/"..nMaxPage)
    end

    local bFull = false
    local bEmpty = true

    UIHelper.HideAllChildren(self.ScrollViewFilterListOther)
    self.tbListCells = self.tbListCells or {}
    for i = 1, nPageSize, 1 do
        local nIndex = (self.nCurPage - 1) * nPageSize + i
        local tData = self.tbData[nIndex]
        if tData then
            if not self.tbListCells[i] then
                self.tbListCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetFilterItemCell, self.ScrollViewFilterListOther)
                UIHelper.SetWidth(self.tbListCells[i].ImgBg, 400)
                -- UIHelper.SetWidth(self.tbListCells[i].ImgUp1, 400)
                UIHelper.SetWidth(self.tbListCells[i].ImgUp2, 400)
                UIHelper.SetWidth(self.tbListCells[i]._rootNode, 400)
                local x = UIHelper.GetPositionX(self.tbListCells[i]._rootNode)
                UIHelper.SetPositionX(self.tbListCells[i]._rootNode, x - 25)
            end

            UIHelper.ToggleGroupAddToggle(self.TogGroupOtherCell, self.tbListCells[i].TogFilterItem)
            self:InitMapCell(self.tbListCells[i], tData)
            UIHelper.SetVisible(self.tbListCells[i]._rootNode, true)
            if self.nPhotoMapType == tData.nMapType and self.dwPhotoMapID == tData.dwMapID then
                UIHelper.SetToggleGroupSelectedToggle(self.TogGroupOtherCell, self.tbListCells[i].TogFilterItem)
            end
            bEmpty = false
        else
            UIHelper.ScrollViewDoLayout(self.ScrollViewFilterListOther)
        end
    end

    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
    UIHelper.ScrollViewDoLayout(self.ScrollViewFilterListOther)
    UIHelper.ScrollToTop(self.ScrollViewFilterListOther)
end

function UIShareStationFilterPop:InitMapCell(scriptCell, tData)
    scriptCell:OnEnter({szOption = UIHelper.GBKToUTF8(tData.szName)}, function()
        self:OnSelectMap(tData)
    end)

    UIHelper.SetVisible(scriptCell.ImgChecked, false)
    UIHelper.SetNodeGray(scriptCell._rootNode, false, true)
    UIHelper.SetEnable(scriptCell.TogFilterItem, true)
end

function UIShareStationFilterPop:FilterMapData(tbData, szSearchText)
    if szSearchText == "" then
        return tbData
    end

    local tbFilterData = {}
    for _, tMapData in ipairs(tbData) do
        -- 同时搜索地图名称和区域名称
        local szMapName = UIHelper.GBKToUTF8(tMapData.szName or "")
        local bMatchName = string.find(szMapName, szSearchText)

        local szRegionName = UIHelper.GBKToUTF8(tMapData.szRegionName or "")
        local bMatchRegion = szRegionName and string.find(szRegionName, szSearchText)

        if bMatchName or bMatchRegion then
            table.insert(tbFilterData, tMapData)
        end
    end

    return tbFilterData
end

function UIShareStationFilterPop:OnSelectMap(tData)
    self.nPhotoMapType = tData.nMapType
    self.dwPhotoMapID = tData.dwMapID
end

function UIShareStationFilterPop:OnSelectExterior(tData, bSelected)
    local nType = self.nMainType

    -- 特效使用字符串key存储筛选
    if nType == COIN_SHOP_GOODS_TYPE.ITEM and type(self.nSubType) == "string" then
        local szEffectKey = tData.szEffectType
        if szEffectKey and tData.dwEffectID then
            self.tFilterExterior[szEffectKey] = self.tFilterExterior[szEffectKey] or {}
            local tCurSelected = self.tFilterExterior[szEffectKey]
            if bSelected then
                if not table.contain_value(tCurSelected, tData.dwEffectID) then
                    table.insert(tCurSelected, tData.dwEffectID)
                end
            else
                table.remove_value(tCurSelected, tData.dwEffectID)
            end
            if table.GetCount(tCurSelected) == 0 then
                self.tFilterExterior[szEffectKey] = nil
            end
        end
        self:UpdateExteriorList()
        return
    end

    local tTopTitle = self.tbCurClassTitle[1] or {}
    local tSubTitle = self.tbCurClassTitle[2] or {}

    for _, nRes in pairs(tTopTitle.tSub) do
        self.tFilterExterior[nRes] = self.tFilterExterior[nRes] or {}

        local tCurSelected = self.tFilterExterior[nRes]
        if nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
            local nSubIndex = ShareExteriorData.GetExteriorSubIndex(nRes)
            if tSubTitle and tSubTitle.tSub then
                nRes = tSubTitle.tSub[1]
                self.tFilterExterior[nRes] = self.tFilterExterior[nRes] or {}

                tCurSelected = self.tFilterExterior[nRes]
                nSubIndex = ShareExteriorData.GetExteriorSubIndex(nRes)
            end

            local dwID = tData["nSub"..nSubIndex]
            if dwID and dwID >= 0 then
                if bSelected then
                    if not table.contain_value(tCurSelected, dwID) then
                        table.insert(tCurSelected, dwID)
                    end
                else
                    table.remove_value(tCurSelected, dwID)
                end
            end
        elseif nType == COIN_SHOP_GOODS_TYPE.HAIR then
            if tData.nHairID and tData.nHairID >= 0 then
                if bSelected then
                    table.insert(tCurSelected, tData.nHairID)
                else
                    table.remove_value(tCurSelected, tData.nHairID)
                end
            end
        elseif nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
            if tData.dwID and tData.dwID > 0 then
                if bSelected then
                    if not table.contain_value(tCurSelected, tData.dwID) then
                        table.insert(tCurSelected, tData.dwID)
                    end
                else
                    table.remove_value(tCurSelected, tData.dwID)
                end
            end
        else
            if bSelected then
                table.insert(tCurSelected, tData.dwItemIndex)
            else
                table.remove_value(tCurSelected, tData.dwItemIndex)
            end
        end

        if table.GetCount(tCurSelected) == 0 then
            self.tFilterExterior[nRes] = nil
        end
    end

    self:UpdateExteriorList()
end

function UIShareStationFilterPop:RemoveClassTitle(nIndex)
    for j = #self.tbCurClassTitle, nIndex, -1 do
        table.remove(self.tbCurClassTitle, j)
    end
    self:UpdateInfo()
end

function UIShareStationFilterPop:ParseChestConfilct(tbTitleList)
    if not tbTitleList or not self.tFilterExterior or table.is_empty(self.tFilterExterior) then
        return
    end

    local bChest = false
    local bSubSet = false
    for nSub, tIDList in pairs(self.tFilterExterior) do
        if nSub == EQUIPMENT_REPRESENT.CHEST_STYLE then
            for _, dwID in ipairs(tIDList) do
                if dwID > 0 then
                    local nClass = ShareExteriorData.GetExteriorClass(dwID)
                    if ShareExteriorData.IsChestClass(nClass) then --成衣
                        bChest = true
                    else
                        bSubSet = true
                    end
                    break
                end
            end
        elseif nSub == EQUIPMENT_REPRESENT.HELM_STYLE -- 外装收集-帽子
            or nSub == EQUIPMENT_REPRESENT.WAIST_STYLE -- 外装收集-腰带
            or nSub == EQUIPMENT_REPRESENT.BANGLE_STYLE -- 外装收集-护腕
            or nSub == EQUIPMENT_REPRESENT.BOOTS_STYLE -- 外装收集-鞋子
        then
            for _, dwID in ipairs(tIDList) do
                if dwID > 0 then
                    bSubSet = true
                    break
                end
            end
        end
    end

    for k, v in ipairs(tbTitleList) do
        if v.nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
            if v.tRewardsClassList[1] == 1 then -- 成衣
                v.bGray = bSubSet
            elseif v.tRewardsClassList[1] == 2 then -- 外装收集
                v.bGray = bChest
            end
        end
    end
end

return UIShareStationFilterPop