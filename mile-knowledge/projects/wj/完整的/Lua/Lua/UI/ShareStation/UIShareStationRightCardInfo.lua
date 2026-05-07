-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShareStationRightCardInfo
-- Date: 2025-07-19 21:40:38
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_COLLECT_COUNT = 50 --最多收藏捏脸的个数
local DEFAULT_CUSTOM_DATA = {
    fScale = 1,
    nOffsetX = 0,
    nOffsetY = 0,
    nOffsetZ = 0,
    fRotationX = 0,
    fRotationY = 0,
    fRotationZ = 0,
}

local UIShareStationRightCardInfo = class("UIShareStationRightCardInfo")

function UIShareStationRightCardInfo:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitDressUpList()
end

function UIShareStationRightCardInfo:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIShareStationRightCardInfo:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnShare, EventType.OnClick, function(btn)
        if self.tbData then
            local nDataType = self.nDataType
            local szShareCode = self.tbData.szShareCode
            local szLinkInfo = "ShareCodeLinkTip/" .. nDataType .. "/" .. szShareCode .. "/" .. UIHelper.UTF8ToGBK(self.tbData.szName)
            if self.tbData.nSubType and self.tbData.nSubType ~= 0 then
                szLinkInfo = szLinkInfo .. "/" .. self.tbData.nSubType
            end
            ChatHelper.SendEventLinkToChat("设计站"..g_tStrings.tShareStationTitle[nDataType].."·"..self.tbData.szName, szLinkInfo)
        end
    end)

    UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick, function(btn)
        if self.tbData then
            SetClipboard(self.tbData.szShareCode)

            local szTip = g_tStrings.STR_SHARE_STATION_COPY_CODE_TIP
            if self.tbData.nOpenStatus == SHARE_OPEN_STATUS.COVER_ILLEGAL then
                szTip = g_tStrings.STR_SHARE_STATION_COPY_ILLEGAL_CODE_TIP
            end
            TipsHelper.ShowNormalTip(szTip)
        end
    end)

    UIHelper.BindUIEvent(self.BtnCollect, EventType.OnClick, function(btn)
        if not self.tbData then
            return
        end

        local bIsLogin = ShareStationData.bIsLogin
        local bHaveCollect = UIHelper.GetVisible(self.ImgCollectSelect)
        if bHaveCollect then
            ShareCodeData.UnCollectData(bIsLogin, self.nDataType, self.tbData.szShareCode)
        else
            ShareCodeData.CollectData(bIsLogin, self.nDataType, self.tbData.szShareCode)
        end
    end)

    UIHelper.BindUIEvent(self.BtnEdit, EventType.OnClick, function(btn)
        if not self.tbData then
            return
        end

        if self.bNeedUpdate then
            Event.Dispatch(EventType.OnStartDoUpdateShareData, ShareStationData.bIsLogin, self.nDataType, self.tbData)
            return
        end

        local nViewID = VIEW_ID.PanelEditFaceDetail
        if not UIMgr.GetView(nViewID) then
            UIMgr.Open(nViewID, self.tbData, self.nDataType, self.tbData.nPhotoSizeType)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDel, EventType.OnClick, function(btn)
        if not self.tbData then
            return
        end

        local bLogin = ShareStationData.bIsLogin
        UIHelper.ShowConfirm(g_tStrings.STR_SHARE_STATION_DEL_CONFIRM, function ()
            ShareCodeData.ApplyDelData(bLogin, self.nDataType, self.tbData.szShareCode)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnReport, EventType.OnClick, function(btn)
        if not self.tbData then
            return
        end

        local bLogin = ShareStationData.bIsLogin
        UIMgr.Open(VIEW_ID.PaneReportFacelPop, bLogin, self.nDataType, self.tbData)
    end)

    UIHelper.BindUIEvent(self.BtnReward, EventType.OnClick, function(btn)
        if not self.tbData then
            return
        end

        GiftHelper.OpenTip(TIP_TYPE.ShareStation, self.tbData, function (nNum, nGold, nTipItemID)
            local szName = self.tbData.szName or ""
            szName = UIHelper.UTF8ToGBK(szName)

            if nGold * nNum >= GiftHelper.MESSAGE_TIP_NUM then
                local szContent = FormatString(g_tStrings.STR_VOICE_REWARD_NUM_BIG_MESSAGE, nGold * nNum)
                UIHelper.ShowConfirm(szContent, function()
                    GiftHelper.TipByShareCode(self.nDataType, self.tbData.szShareCode, szName, nNum, nGold, nTipItemID)
                end)
                return
            end
            GiftHelper.TipByShareCode(self.nDataType, self.tbData.szShareCode, szName, nNum, nGold, nTipItemID)
        end)
    end)
end

function UIShareStationRightCardInfo:RegEvent()
    Event.Reg(self, EventType.OnCoinShopCancelExteriorChangeHair, function ()
        if not self.tbData then
            return
        end
        self:UpdateExterior(self.tbData)

        UIHelper.CascadeDoLayoutDoWidget(self.ScrollShareContent, true, true)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollShareContent)
    end)

    Event.Reg(self, EventType.OnUpdateCollectShareCodeList, function (nDataType, tCollectData)
        if not self.tbData or nDataType ~= self.nDataType then
            return
        end

        Timer.AddFrame(self, 1, function ()
            local bHaveCollect = ShareStationData.IsCollectShare(self.tbData.szShareCode)
            UIHelper.SetVisible(self.ImgCollectSelect, bHaveCollect)
        end)
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        Timer.Add(self, 0.1, function ()
            UIHelper.ScrollViewDoLayout(self.ScrollShareContent)
            UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
        end)
    end)
end

function UIShareStationRightCardInfo:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIShareStationRightCardInfo:InitDressUpList()
    self.tbDressUpWidget = {}
    self.tbDressUpItemLayout = {}
    self.tbDressUpToggle = {}

    for nSort = SHARE_EXTERIOR_SHOP_STATE.HAVE, SHARE_EXTERIOR_SHOP_STATE.OTHER do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetShareStationDressUpCell, self.WidgetDressList)

        local szTitle = g_tStrings.STR_EXTERIOR_SHOP_STATE_TEXT[nSort]
        local szWarn = g_tStrings.STR_EXTERIOR_SHOP_STATE_TEXT_WARNING[nSort]
        if szWarn then
            UIHelper.SetVisible(script.WidgetWarn, true)
            UIHelper.SetRichText(script.LabelWarn, szWarn)
        end
        UIHelper.SetLabel(script.LabelTitle, szTitle)
        UIHelper.SetVisible(script.WidgetFlag, nSort == SHARE_EXTERIOR_SHOP_STATE.IN_BAG_BIND or nSort == SHARE_EXTERIOR_SHOP_STATE.IN_BAG_UNBIND)
        self.tbDressUpWidget[nSort] = script._rootNode
        self.tbDressUpItemLayout[nSort] = script.LayoutCell
        self.tbDressUpToggle[nSort] = script.ToggleCell
    end

    for k, tog in ipairs(self.tbDressUpToggle) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(tog, bSelected)
            local tbNewExterior = {}
            Timer.AddFrame(self, 1, function()
                local bEnablePreview = self:UpdateInvisible(self.szPageType)
                if not bEnablePreview then
                    return
                end

                tbNewExterior = self:GetSelectExterior()
                if not table.is_empty(tbNewExterior) then
                    ExteriorCharacter.PreviewExteriorInShareStation(tbNewExterior)
                end
            end)
        end)
    end

    UIHelper.LayoutDoLayout(self.WidgetDressList)
    UIHelper.LayoutDoLayout(self.WidgetDressUp)
end

function UIShareStationRightCardInfo:UpdateInfo(nDataType, tbData)
    self.nDataType = nDataType
    self.tbData = tbData
    if not self.tbData then
        return
    end

    local tInfo = self.tbData
    local szShareCode = tInfo.szShareCode
    local szFileLink = tInfo.szFileLink --数据文件下载链接
    local nRoleType = tInfo.nRoleType --体型
    local szCoverLink = tInfo.szCoverLink --封面下载链接
    local szCoverPath = tInfo.szCoverPath --封面路径
    local dwCreateTime = tInfo.dwCreateTime --上传时间
    local szDesc = tInfo.szDesc --描述
    local szName = tInfo.szName --名字
    local nOpenStatus = tInfo.nOpenStatus --作品状态，包括：公开、私密、隐藏、审核中、审核失败、已删除
    local nHeat = tInfo.nHeat --总热度
    local szUser = tInfo.szUser --作者
    local tTags = tInfo.tTag --风格标签
    local nVersion = tInfo.nVersion --版本号
    local szUploadSource = tInfo.szUploadSource --上传来源
    local nRewards = tInfo.nRewards --打赏金额
    local bCertified = tInfo.bCertified --是否认证
    local nPos = tInfo.nPos --位置

    -- 捏脸站
    local szSuffix = tInfo.szSuffix
    -- 搭配站
    local dwForceID = tInfo.dwForceID
    -- 拍照站
    local nPhotoSizeType = tInfo.nPhotoSizeType
    local nPhotoMapType = tInfo.nPhotoMapType
    local dwPhotoMapID = tInfo.dwPhotoMapID

    local bOwner = ShareStationData.IsSelfShare(szShareCode)
    local bHaveCollect = ShareStationData.IsCollectShare(szShareCode)
    if nRewards then
        local szRewardMoney = UIHelper.GetGoldAndBrickText(nRewards, nil, nil, true)
        UIHelper.SetRichText(self.LabelRewardNum, szRewardMoney)
    end

    local bNeedUpdate = bOwner and (nOpenStatus == SHARE_OPEN_STATUS.COVER_ILLEGAL or string.is_nil(tInfo.szCoverLink))
    self.bNeedUpdate = nDataType ~= SHARE_DATA_TYPE.PHOTO and bNeedUpdate -- 拍照模板不能重新上传

    UIHelper.SetVisible(self.ImgCollectSelect, bHaveCollect)
    UIHelper.SetVisible(self.ImgCertified, bCertified)
    UIHelper.SetVisible(self.LayoutHeat, nOpenStatus == SHARE_OPEN_STATUS.PUBLIC)
    UIHelper.SetString(self.LabelFaceName, szName)
    UIHelper.SetString(self.LabelHeat, nHeat)
    UIHelper.SetString(self.LabelOwner, szUser)
    UIHelper.SetString(self.LabelShareCode, szShareCode)
    UIHelper.SetString(self.LabelFaceDescribe, szDesc)
    self:UpdateBtn(bOwner, nOpenStatus)
    self:UpdateTag(szUploadSource, tTags)
    self:UpdateExterior(tbData)
    self:UpdatePhotoMapInfo(tbData)

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollShareContent, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollShareContent)
end

function UIShareStationRightCardInfo:UpdateTag(szUploadSource, tbTag)
    UIHelper.RemoveAllChildren(self.LayoutFlag)

    if szUploadSource and g_tStrings.tUploadSourceName[szUploadSource] then
        local szName = g_tStrings.tUploadSourceName[szUploadSource]
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetShareStationFlag, self.LayoutFlag)
        UIHelper.SetString(script.LabelFlag, szName)
        UIHelper.SetString(script.LabelFlagCheck, szName)
        UIHelper.SetVisible(script.ImgFlagSpecial, true)
        UIHelper.SetEnable(script.TogFlag, false)
    end

    tbTag = tbTag or {}
    for index, nTagID in ipairs(tbTag) do
        local tUIInfo = Table_GetShareStationTagInfo(nTagID)
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetShareStationFlag, self.LayoutFlag)
        UIHelper.SetString(script.LabelFlag, UIHelper.GBKToUTF8(tUIInfo.szName))
        UIHelper.SetString(script.LabelFlagCheck, UIHelper.GBKToUTF8(tUIInfo.szName))
        UIHelper.SetEnable(script.TogFlag, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutFlag)
    UIHelper.SetVisible(self.WidgetShareFlag, UIHelper.GetChildrenCount(self.LayoutFlag) > 0)
end

function UIShareStationRightCardInfo:UpdateExterior(tbData)
    self.tbScriptExteriorItem = {}
    local tbShareData = ShareCodeData.GetShareCodeData(tbData.szShareCode)
    local tExterior = tbShareData and tbShareData.tExterior
    if not tExterior then
        UIHelper.SetVisible(self.WidgetDressUp, false)
        return
    end

    local tDetail = tExterior.tDetail
    local tSortData = ShareExteriorData.GetSortDataByExteriorData(tExterior)
    for nSort = SHARE_EXTERIOR_SHOP_STATE.HAVE, SHARE_EXTERIOR_SHOP_STATE.OTHER do
        local tBoxList = tSortData[nSort]
        local widget = self.tbDressUpWidget[nSort]
        local layout = self.tbDressUpItemLayout[nSort]
        if #tBoxList > 0 then
            self.tbScriptExteriorItem[nSort] = {}
            UIHelper.RemoveAllChildren(layout)
            for _, tExteriorBox in ipairs(tBoxList) do
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, layout)
                self:UpdateExteriorItem(script, tExteriorBox, tDetail, nSort)
                table.insert(self.tbScriptExteriorItem[nSort], script)
            end
            UIHelper.SetVisible(widget, true)
            UIHelper.SetVisible(layout, true)
            UIHelper.LayoutDoLayout(layout)
            UIHelper.SetSelected(self.tbDressUpToggle[nSort], true, false)
        else
            UIHelper.SetVisible(widget, false)
            UIHelper.SetVisible(layout, false)
        end
    end

    UIHelper.SetSelected(self.tbDressUpToggle[SHARE_EXTERIOR_SHOP_STATE.OTHER], true, true)

    UIHelper.SetVisible(self.WidgetDressUp, true)
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetDressUp, true, true)
    UIHelper.ScrollViewDoLayout(self.ScrollShareContent)
end

function UIShareStationRightCardInfo:UpdatePhotoMapInfo(tData)
    UIHelper.SetVisible(self.WidgetLocate, false)
    if not tData or not tData.nPhotoMapType or not tData.dwPhotoMapID then
        return
    end

    local szMapName = SelfieTemplateBase.GetPhotoMapName(tData.nPhotoMapType, tData.dwPhotoMapID)
    if not szMapName then
        return
    end

    UIHelper.SetString(self.LabelLocate, szMapName)
    UIHelper.SetVisible(self.WidgetLocate, true)
end

local function IsOtherSchoolExterior(dwID, eGoodsType, nSort)
    local bOtherSchool = false
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return bOtherSchool
    end

    -- 非已拥有的外装/武器，检查是否非本门派
    if nSort ~= SHARE_EXTERIOR_SHOP_STATE.HAVE then
        if eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then -- 校服
            local tInfo = GetExterior().GetExteriorInfo(dwID)
            if tInfo and tInfo.nGenre == EXTERIOR_GENRE.SCHOOL and tInfo.nForceID ~= pPlayer.dwForceID then
                bOtherSchool = true
            end
        elseif eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then -- 武器
            local tInfo = CoinShop_GetWeaponExteriorInfo(dwID)
            local nForceMask = tInfo and tInfo.nForceMask or 0
            if nForceMask > 0 then
                bOtherSchool = not GetNumberBit(nForceMask, pPlayer.dwBitOPForceID + 1)
            end
        end
    end
    return bOtherSchool
end

local function IsCustomized(tDetail, nSub)
    if not nSub then
        return false
    end

    local tSubDetail = tDetail and tDetail[nSub]
    if not tSubDetail then
        return false
    end

    local bIsCustomized = false -- 自定义位置
    local bHideBackClock = false
    local bHaveColor = false -- 染色标记
    local bHasCustomData = false -- 是否有自定义数据

    if tSubDetail.tCustomData then
        local tCustomData = tSubDetail.tCustomData
        bHasCustomData = not IsTableEqual(tCustomData, DEFAULT_CUSTOM_DATA)
        bIsCustomized = bHasCustomData
    end

    if nSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND and tSubDetail then
        bHideBackClock = tSubDetail.bVisible == true
    end

    if nSub == EQUIPMENT_REPRESENT.HELM_STYLE then -- 外装收集-帽子
        local nDyeingID = tSubDetail.nNowDyeingID
        bHaveColor = nDyeingID and nDyeingID > 0
    -- elseif nSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then -- 披风
    --     local tColorID = tSubDetail.tColorID or {}
    --     local bDyeing = false
    --     for _, nColorID in pairs(tColorID) do
    --         if nColorID > 0 then
    --             bDyeing = true
    --             bHaveColor = true
    --             break
    --         end
    --     end
    end

    return bIsCustomized, bHideBackClock, bHaveColor, bHasCustomData
end

local function IsColorDye(dwID, nSub, tSubDetail)
    local bColorDye = false
    local bCanDyeColor = false
    local pPlayer = GetClientPlayer()

    if not nSub or not tSubDetail or not pPlayer then
        return false, false
    end

    -- 染色标记
    if nSub == EQUIPMENT_REPRESENT.HELM_STYLE then -- 外装收集-帽子
        local nDyeingID = tSubDetail.nNowDyeingID
        local nNowDyeingID = pPlayer.GetExteriorDyeingID(dwID)
        bColorDye = nDyeingID and nDyeingID > 0
        bCanDyeColor = nDyeingID and nNowDyeingID ~= nDyeingID
    elseif nSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then -- 披风
        local tColorID = tSubDetail.tColorID or {}
        local bDyeing = false
        for _, nColorID in pairs(tColorID) do
            if nColorID > 0 then
                bDyeing = true
                break
            end
        end
        bColorDye = bDyeing
    elseif nSub == EQUIPMENT_REPRESENT.HAIR_STYLE then -- 发型
        local bHaveDying = false
        local tDyeingData = tSubDetail.tDyeingData or {}
        if tDyeingData and not table.is_empty(tDyeingData) then
            local tList = pPlayer.GetHairCustomDyeingList(dwID) or {}
            for nIndex, tMyDyeintData in ipairs(tList) do
                if IsTableEqual(tMyDyeintData, tDyeingData) then
                    bHaveDying = true
                end
            end
            bColorDye = true
            bCanDyeColor = not bHaveDying
        end
    end

    return bColorDye, bCanDyeColor
end

local function IsCut(tSubDetail)
    return tSubDetail and tSubDetail.nFlag and tSubDetail.nFlag > 0 
end

function UIShareStationRightCardInfo:UpdateExteriorItem(script, tExteriorBox, tDetail, nSort)
    local dwID = tExteriorBox.dwID
    local eGoodsType = tExteriorBox.eGoodsType
    local nItemType = tExteriorBox.nItemType
    local dwItemIndex = tExteriorBox.dwItemIndex
    local bEffect = tExteriorBox.bEffect
    local nSub = tExteriorBox.nSub

    local bIsCustomized, bHideBackClock, bHaveColor, bHasCustomData = IsCustomized(tDetail, nSub)
    local bOtherSchool = IsOtherSchoolExterior(dwID, eGoodsType, nSort)
    local bColorDye, bCanDyeColor = IsColorDye(dwID, nSub, tDetail[nSub])
    local bCut = IsCut(tDetail[nSub])
    local bHave = nSort == SHARE_EXTERIOR_SHOP_STATE.HAVE
    local bHide = false

    -- 披风隐藏开关
    if nSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then
        bHide = tDetail[nSub] and not tDetail[nSub].bVisible
    end

    tExteriorBox.bIsCustomized = bIsCustomized
    tExteriorBox.bHasCustomData = bHasCustomData
    tExteriorBox.bHideBackClock = bHideBackClock
    tExteriorBox.bHaveColor = bHaveColor
    tExteriorBox.bOtherSchool = bOtherSchool
    tExteriorBox.bColorDye = bColorDye
    tExteriorBox.bShow = true
    script.tExteriorBox = tExteriorBox
    script.nSort = nSort
    script.nSub = nSub

    if bEffect then --称号特效
        if nItemType and dwItemIndex then
            script:OnInitWithTabID(nItemType, dwItemIndex)
        else
            script:OnInitWithIconID(1241, 5, 1)
        end
    elseif eGoodsType then
        if eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then -- 发型
            script:OnInitWithIconID(10775, 2, 1)
        elseif eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then -- 【成衣】或【外装收集部位】
            script:OnInitWithTabID("EquipExterior", dwID)
        elseif eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then -- 武器
            script:OnInitWithTabID("WeaponExterior", dwID)
        elseif eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then -- 挂宠/普通挂件/其他道具
            script:OnInitWithTabID(nItemType, dwItemIndex)
        end
    end

    local scriptIcon = script.WidgetExteriorIcons and UIHelper.GetBindScript(script.WidgetExteriorIcons)
    if scriptIcon then
        script.bOtherSchool = bOtherSchool
        UIHelper.SetVisible(scriptIcon.ImgHide, bHide)
        UIHelper.SetVisible(scriptIcon.ImgOtherSchool, bOtherSchool)

        UIHelper.SetVisible(scriptIcon.ImgCut, bCut)
        UIHelper.SetVisible(scriptIcon.ImgHide, bHide)
        UIHelper.SetVisible(scriptIcon.ImgCustom, bIsCustomized)
        UIHelper.SetVisible(scriptIcon.ImgCustomClose, bHasCustomData and not bIsCustomized)
        UIHelper.SetVisible(scriptIcon.ImgOtherSchool, bOtherSchool)
        UIHelper.SetVisible(scriptIcon.ImgDye, bColorDye)
        UIHelper.SetVisible(scriptIcon.ImgDyeHat, bHaveColor)
        UIHelper.SetVisible(scriptIcon.ImgNeedToColor, bCanDyeColor)

        UIHelper.SetVisible(scriptIcon._rootNode, true)
        UIHelper.LayoutDoLayout(scriptIcon._rootNode)
        UIHelper.SetVisible(scriptIcon.ImgExteriorIconHide, bHideBackClock) -- 不在WidgetExteriorIcon里面，不需要一起doLayout
    end

    script:SetClearSeletedOnCloseAllHoverTips(true)
    script:SetClickCallback(function()
        local tbGoods = {
            eGoodsType = eGoodsType,
            dwGoodsID = dwID,
            dwTabType = nItemType,
            dwTabIndex = dwItemIndex,
        }

        local tbBtnInfo = {}
        -- 只有有自定义数据时才显示自定义开关
        if bHasCustomData then
            if UIHelper.GetVisible(scriptIcon.ImgCustom) then
                table.insert(tbBtnInfo, {
                    szName = "取消自定义",
                    OnClick = function ()
                        script.tExteriorBox.bIsCustomized = false
                        self:DoUpdateChange()
                        UIHelper.SetVisible(scriptIcon.ImgCustom, false)
                        UIHelper.SetVisible(scriptIcon.ImgCustomClose, true)
                        Event.Dispatch(EventType.HideAllHoverTips)
                    end
                })
            elseif UIHelper.GetVisible(scriptIcon.ImgCustomClose) then
                table.insert(tbBtnInfo, {
                    szName = "打开自定义",
                    OnClick = function ()
                        script.tExteriorBox.bIsCustomized = true
                        self:DoUpdateChange()
                        UIHelper.SetVisible(scriptIcon.ImgCustom, true)
                        UIHelper.SetVisible(scriptIcon.ImgCustomClose, false)
                        Event.Dispatch(EventType.HideAllHoverTips)
                    end
                })
            end
        end

        -- 预览/取消预览按钮
        if not bOtherSchool then
            table.insert(tbBtnInfo, {
                szName = script.tExteriorBox.bShow and "取消预览" or "预览",
                OnClick = function ()
                    script.tExteriorBox.bShow = not script.tExteriorBox.bShow
                    self:DoUpdateChange()
                    Event.Dispatch(EventType.HideAllHoverTips)
                end
            })
        end

        if UIHelper.GetVisible(scriptIcon.ImgNeedToColor) then
            table.insert(tbBtnInfo, {
                szName = "前往染色",
                OnClick = function ()
                    if nSort == SHARE_EXTERIOR_SHOP_STATE.HAVE then
                        if nSub == EQUIPMENT_REPRESENT.HELM_STYLE then
                            local nDyeingID = tDetail[nSub].nNowDyeingID
                            Event.Dispatch(EventType.OnShareStationChangeHelmDye, dwID, nDyeingID)
                        elseif eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
                            local tDyeingData = tDetail[nSub].tDyeingData
                            Event.Dispatch(EventType.OnCoinShopStartBuildHairDye, dwID, tDyeingData)
                        end
                    else
                        TipsHelper.ShowNormalTip("未拥有该外观，不可染色")
                    end
                end
            })
        end

        local _, scriptTips = TipsHelper.ShowItemTips(script._rootNode, "Effect", dwID, false)
        if bEffect then
            scriptTips:SetBtnState(tbBtnInfo)
            return
        end

        local scriptTips = CoinShopPreview.InitItemTips(tbGoods, nil, script._rootNode)
        scriptTips:SetBtnState(tbBtnInfo)
    end)
end

function UIShareStationRightCardInfo:UpdateBtn(bOwner, nOpenStatus)
    local bIsLogin = ShareStationData.bIsLogin
    UIHelper.SetVisible(self.WidgetShare, not bIsLogin and nOpenStatus == SHARE_OPEN_STATUS.PUBLIC)
    UIHelper.SetVisible(self.WidgetCollect, not bOwner)
    UIHelper.SetVisible(self.WidgetReport, not bOwner)
    UIHelper.SetVisible(self.WidgetReward, not bOwner and not bIsLogin)
    UIHelper.SetVisible(self.WidgetDel, bOwner and not bIsLogin)
    UIHelper.SetVisible(self.WidgetEdit, bOwner and not bIsLogin)
    if self.nDataType == SHARE_DATA_TYPE.PHOTO and (nOpenStatus ~= SHARE_OPEN_STATUS.PUBLIC and nOpenStatus ~= SHARE_OPEN_STATUS.PRIVATE) then
        UIHelper.SetVisible(self.WidgetEdit, false)
    end
    UIHelper.LayoutDoLayout(self.WidgetBtnShareNormal)

    local bAllEmpty = true
    for index, widget in ipairs(UIHelper.GetChildren(self.WidgetBtnShareNormal)) do
        if UIHelper.GetVisible(widget) then
            bAllEmpty = false
            break
        end
    end
    UIHelper.SetVisible(self.WidgetBtnShareNormal, not bAllEmpty)
end

local function GetExteriorBoxBySub(tSelList, nSub)
    for nSort, v in pairs(tSelList) do
        for _, item in pairs(v) do
            if item.nSub == nSub then
                return item
            end
        end
    end
end

function UIShareStationRightCardInfo:GetSelectExterior()
    local tNewExterior = {}
    local tbShareData = ShareCodeData.GetShareCodeData(self.tbData.szShareCode)
    local tExterior = tbShareData and tbShareData.tExterior
    if not tExterior then
        return tNewExterior
    end

    tNewExterior = clone(tExterior)
    local tNewExteriorID = tNewExterior.tExteriorID
    local tNewDetail = tNewExterior.tDetail
    for nSub, v in pairs(tNewExteriorID) do
        local scriptItem = GetExteriorBoxBySub(self.tbScriptExteriorItem, nSub) or {}
        local nSort = scriptItem.nSort
        local tExteriorBox = scriptItem.tExteriorBox
        local tog = self.tbDressUpToggle[nSort]
        if tExteriorBox and tExteriorBox.bShow and tog and UIHelper.GetSelected(tog) and not scriptItem.bOtherSchool then
            --处理是否勾选了自定义位置的预览
            local eGoodsType = tExteriorBox.eGoodsType
            local nItemType = tExteriorBox.nItemType
            local dwItemIndex = tExteriorBox.dwItemIndex
            local bEffect = tExteriorBox.bEffect
            local bIsCustomized = tExteriorBox.bIsCustomized

            if IsCustomPendantType(nSub) or bEffect then
                local tSubDetail = tNewDetail[nSub]
                local tCustomData = tSubDetail and tSubDetail.tCustomData
                if not tCustomData or not bIsCustomized then
                    if bEffect then
                        tCustomData = ShareExteriorData.GetDefaultSFXCustomData(tNewExteriorID[nSub])
                    elseif dwItemIndex then
                        tCustomData = ShareExteriorData.GetDefaultPendantCustomData(nSub, dwItemIndex)
                    end
                end
                tNewDetail[nSub] = tNewDetail[nSub] or {}
                tNewDetail[nSub].tCustomData = tCustomData
            end
        else
            -- 去掉没勾选的部位
            tNewExteriorID[nSub] = nil
        end
    end

    return tNewExterior
end

function UIShareStationRightCardInfo:DoUpdateChange()
    local tbNewExterior = {}
    Timer.AddFrame(self, 1, function()
        tbNewExterior = self:GetSelectExterior()
        if not table.is_empty(tbNewExterior) then
            ExteriorCharacter.PreviewExteriorInShareStation(tbNewExterior)
        end
    end)
end

function UIShareStationRightCardInfo:UpdateInvisible(szPage)
    if not self.tbData or not self.tbData.nOpenStatus then
        return
    end

    local bOwner = ShareStationData.IsSelfShare(self.tbData.szShareCode)
    local nOpenStatus = self.tbData.nOpenStatus
    if szPage == "Rank" then
        self.bEnablePreview = nOpenStatus == SHARE_OPEN_STATUS.PUBLIC
    elseif szPage == "Like" then
        self.bEnablePreview = nOpenStatus == SHARE_OPEN_STATUS.PUBLIC
    elseif szPage == "Self" then
        self.bEnablePreview = nOpenStatus == SHARE_OPEN_STATUS.PUBLIC
                                or nOpenStatus == SHARE_OPEN_STATUS.PRIVATE
                                or nOpenStatus == SHARE_OPEN_STATUS.COVER_ILLEGAL
    end

    UIHelper.SetVisible(self.WidgetShareOwner, self.bEnablePreview)
    UIHelper.SetVisible(self.WidgetShareCode, self.bEnablePreview)
    UIHelper.SetVisible(self.WidgetShareFlag, self.bEnablePreview and UIHelper.GetChildrenCount(self.LayoutFlag) > 0)
    UIHelper.SetVisible(self.WidgetDescribe, self.bEnablePreview)
    UIHelper.SetVisible(self.WidgetLocate, self.bEnablePreview and self.nDataType == SHARE_DATA_TYPE.PHOTO)
    UIHelper.SetVisible(self.WidgetDressUp, self.bEnablePreview and self.tbScriptExteriorItem and not table.is_empty(self.tbScriptExteriorItem))
    UIHelper.SetVisible(self.WidgetHide, not self.bEnablePreview)
    UIHelper.SetVisible(self.WidgetShareReward, self.bEnablePreview and (not not self.tbData.nRewards) and bOwner)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollShareContent)
    return self.bEnablePreview
end

return UIShareStationRightCardInfo