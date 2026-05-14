LootSetting = {
    -- 常规设置 -------------------------------------------
    {
        szName = "常规设置",
        tbButtonList = {
            {
                szName = "恢复默认",
                szBgColor = "Blue",
                fnBtnCallBack = function (tbGroupList)
                    LootSetting.ResetSection(tbGroupList)
                end,
            },
        },
        tbGroupList =
        {
            [1] =
            {
                szName = "书籍设置",
                nVersion = 1,
                bVisible = true,
                tbClassList =
                {
                    {
                        nType = MINI_SETTING_COM_TYPE.SWITCH,
                        szName = "已读书籍不拾取",
                        fnGetDefaultValue = function ()
                            return false
                        end,
                        fnFunc = function (bOpen)
                            Storage.LootSetting.bForbidBookHasRead = bOpen
                        end,
                        fnGetValue = function ()
                            return Storage.LootSetting.bForbidBookHasRead
                        end
                    },
                    {
                        nType = MINI_SETTING_COM_TYPE.SWITCH,
                        szName = "已有书籍不拾取",
                        fnGetDefaultValue = function ()
                            return false
                        end,
                        fnFunc = function (bOpen)
                            Storage.LootSetting.bForbidBookHasOwned = bOpen
                        end,
                        fnGetValue = function ()
                            return Storage.LootSetting.bForbidBookHasOwned
                        end
                    },
                }
            },
            [2] =
            {
                szName = "自动拾取以下品质",
                nVersion = 1,
                bVisible = true,
                tbClassList =
                {
                    {
                        nType = MINI_SETTING_COM_TYPE.SWITCH,
                        szName = "根据品质拾取",
                        fnGetDefaultValue = function ()
                            return false
                        end,
                        fnFunc = function (bOpen)
                            Storage.LootSetting.bAutoLootByQuality = bOpen
                            Event.Dispatch(EventType.OnMiniSettingAllUpdate)
                        end,
                        fnGetValue = function ()
                            return Storage.LootSetting.bAutoLootByQuality
                        end
                    },
                    {
                        nType = MINI_SETTING_COM_TYPE.SWITCH,
                        szName = "占位空白组件",
                        bHideAllChild = true,
                        fnFunc = function (bOpen)
                            
                        end
                    },
                    {
                        nType = MINI_SETTING_COM_TYPE.OPTION_S,
                        szName = "灰色",
                        fnGetDefaultValue = function ()
                            return true
                        end,
                        fnFunc = function (bCheck)
                            Storage.LootSetting.tAutoLootQualityList[1] = bCheck
                        end,
                        fnGetValue = function ()
                            return Storage.LootSetting.tAutoLootQualityList[1]
                        end,
                        fnEnable = function ()
                            return Storage.LootSetting.bAutoLootByQuality, "请先打开按品质拾取设置，再选择品质"
                        end
                    },
                    {
                        nType = MINI_SETTING_COM_TYPE.OPTION_S,
                        szName = "白色",
                        fnGetDefaultValue = function ()
                            return true
                        end,
                        fnFunc = function (bCheck)
                            Storage.LootSetting.tAutoLootQualityList[2] = bCheck
                        end,
                        fnGetValue = function ()
                            return Storage.LootSetting.tAutoLootQualityList[2]
                        end,
                        fnEnable = function ()
                            return Storage.LootSetting.bAutoLootByQuality, "请先打开按品质拾取设置，再选择品质"
                        end
                    },
                    {
                        nType = MINI_SETTING_COM_TYPE.OPTION_S,
                        szName = "绿色",
                        fnGetDefaultValue = function ()
                            return true
                        end,
                        fnFunc = function (bCheck)
                            Storage.LootSetting.tAutoLootQualityList[3] = bCheck
                        end,
                        fnGetValue = function ()
                            return Storage.LootSetting.tAutoLootQualityList[3]
                        end,
                        fnEnable = function ()
                            return Storage.LootSetting.bAutoLootByQuality, "请先打开按品质拾取设置，再选择品质"
                        end
                    },
                    {
                        nType = MINI_SETTING_COM_TYPE.OPTION_S,
                        szName = "蓝色",
                        fnGetDefaultValue = function ()
                            return true
                        end,
                        fnFunc = function (bCheck)
                            Storage.LootSetting.tAutoLootQualityList[4] = bCheck
                        end,
                        fnGetValue = function ()
                            return Storage.LootSetting.tAutoLootQualityList[4]
                        end,
                        fnEnable = function ()
                            return Storage.LootSetting.bAutoLootByQuality, "请先打开按品质拾取设置，再选择品质"
                        end
                    },
                    {
                        nType = MINI_SETTING_COM_TYPE.OPTION_S,
                        szName = "紫色",
                        fnGetDefaultValue = function ()
                            return true
                        end,
                        fnFunc = function (bCheck)
                            Storage.LootSetting.tAutoLootQualityList[5] = bCheck
                        end,
                        fnGetValue = function ()
                            return Storage.LootSetting.tAutoLootQualityList[5]
                        end,
                        fnEnable = function ()
                            return Storage.LootSetting.bAutoLootByQuality, "请先打开按品质拾取设置，再选择品质"
                        end
                    },
                    {
                        nType = MINI_SETTING_COM_TYPE.OPTION_S,
                        szName = "橙色",
                        fnGetDefaultValue = function ()
                            return true
                        end,
                        fnFunc = function (bCheck)
                            Storage.LootSetting.tAutoLootQualityList[6] = bCheck
                        end,
                        fnGetValue = function ()
                            return Storage.LootSetting.tAutoLootQualityList[6]
                        end,
                        fnEnable = function ()
                            return Storage.LootSetting.bAutoLootByQuality, "请先打开按品质拾取设置，再选择品质"
                        end
                    },
                }
            },
        }
    },
    -- 道具自定义 -------------------------------------------
    {
        szName = "道具自定义",
        tbButtonList = {
            {
                szName = "批量删除",
                szBgColor = "Blue",
                fnBtnCallBack = function ()
                    LootSetting.bDeleteItemState = true
                    Event.Dispatch(EventType.OnMiniSettingRefreshButton)
                    Event.Dispatch(EventType.OnMiniSettingAllRefresh)
                end,
                fnGetVisible = function ()
                    return not LootSetting.bDeleteItemState
                end
            },
            {
                szName = "添加",
                szBgColor = "Blue",
                fnBtnCallBack = function ()
                    UIMgr.Open(VIEW_ID.PanelPromptPop, "", "请输入完整道具名", function (szSearchkey)
                        for _, tInfo in ipairs(Storage.LootSetting.tItemSettingList) do
                            if tInfo[1] == szSearchkey then
                                TipsHelper.ShowNormalTip("已经设置了相同的道具关键字")
                                return
                            end
                        end

                        table.insert(Storage.LootSetting.tItemSettingList, {
                            szSearchkey, 1, 0
                        })

                        Event.Dispatch(EventType.OnMiniSettingAllUpdate)
                    end)
                end,
                fnGetVisible = function ()
                    return not LootSetting.bDeleteItemState
                end
            },
            {
                szName = "取消",
                szBgColor = "Blue",
                fnBtnCallBack = function ()
                    LootSetting.bDeleteItemState = false
                    Event.Dispatch(EventType.OnMiniSettingRefreshButton)
                    Event.Dispatch(EventType.OnMiniSettingAllRefresh)
                end,
                fnGetVisible = function ()
                    return LootSetting.bDeleteItemState
                end
            },
            {
                szName = "删除",
                szBgColor = "Yellow",
                fnBtnCallBack = function ()
                    LootSetting.bDeleteItemState = false
                    for szName, bSelect in pairs(LootSetting.tbDeleteItem) do
                        if bSelect then
                            for nIndex, tInfo in ipairs(Storage.LootSetting.tItemSettingList) do
                                if tInfo[1] == szName then
                                    table.remove(Storage.LootSetting.tItemSettingList, nIndex)
                                    break
                                end
                            end
                        end
                    end

                    Event.Dispatch(EventType.OnMiniSettingRefreshButton)
                    Event.Dispatch(EventType.OnMiniSettingAllUpdate)
                end,
                fnGetVisible = function ()
                    return LootSetting.bDeleteItemState
                end
            },
        },
        tbGroupList =
        {
            [1] =
            {
                szName = "物品列表",
                nVersion = 1,
                bVisible = true,                
                fnGetDataList = function ()
                    local tDataList = {}
                    for nChildIndex, tInfo in ipairs(Storage.LootSetting.tItemSettingList) do
                        table.insert(tDataList, {
                            nIndex = nChildIndex,
                            szName = tInfo[1],
                            nPrefabID = PREFAB_ID.WidgetAutoGetCell,
                            tbTogTextList = {"自动拾取", "禁止拾取"},
                            fnOnSelectChanged = function (nTogIndex)
                                tInfo[2] = 1
                                tInfo[3] = nTogIndex - 1
                            end,
                            fnGetSelectIndex = function ()
                                return tInfo[3] + 1
                            end,
                            fnGetVisible = function ()
                                return not LootSetting.bDeleteItemState
                            end,
                            fnOnSelectOption = function (bSelect)
                                LootSetting.tbDeleteItem[tInfo[1]] = bSelect
                            end,
                            fnOnBtnDeleteClick = function (tbConfig)
                                UIHelper.ShowConfirm(string.format("请问是否删除关于【%s】的设置？", tbConfig.szName), function ()
                                    for nIndex, tInfo in ipairs(Storage.LootSetting.tItemSettingList) do
                                        if tInfo[1] == tbConfig.szName then
                                            table.remove(Storage.LootSetting.tItemSettingList, nIndex)
                                            break
                                        end
                                    end
                                    Event.Dispatch(EventType.OnMiniSettingAllUpdate)
                                end)
                            end
                        })
                    end
                    return tDataList
                end,
            },
        }
    },
    -- 春节年兽砸罐活动 -------------------------------------------
    {
        szName = "年兽陶罐",
        fnGetVisible = function()
            return ActivityData.IsActivityOn(33) or UI_IsActivityOn(33)
        end,
        tbButtonList = {

        },
        tbGroupList =
        {
            [1] =
            {
                szName = "物品列表",
                nVersion = 1,
                bVisible = true,
                fnGetDataList = function ()
                    local tDataList = {}
                    for nIndex, tInfo in ipairs(MY_Taoguan.FILTER_ITEM) do
                        table.insert(tDataList, {
                            nIndex = nIndex,
                            szName = tInfo.szName,
                            nPrefabID = PREFAB_ID.WidgetAutoGetCell,
                            tbTogTextList = {"自动拾取", "禁止拾取"},
                            fnOnSelectChanged = function (nTogIndex)
                                MY_Taoguan.O.tFilterItem[tInfo.szName] = nTogIndex == 2
                                MY_Taoguan.O.Flush()
                            end,
                            fnGetSelectIndex = function ()
                                return MY_Taoguan.O.tFilterItem[tInfo.szName] and 2 or 1
                            end,
                        })
                    end
                    return tDataList
                end,
            },
        }
    }
}

function LootSetting.Init()
    if LootSetting.bInit then return end

    LootSetting.bInit = true
    LootSetting.ReloadTempData()
end

function LootSetting.ReloadTempData()
    LootSetting.bDeleteItemState = nil
    LootSetting.tbDeleteItem = {}
end


local function extract_chinese(str)
    local chinese_characters = {}
    for ch in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
        if ch:match("[\128-\255]+") then
            table.insert(chinese_characters, ch)
        end
    end
    return table.concat(chinese_characters)
end

function LootSetting.ResetSection(tbGroupList)
    for _, tGroup in ipairs(tbGroupList) do
        for _, tClass in ipairs(tGroup.tbClassList) do
            if tClass.fnGetDefaultValue and tClass.fnFunc then
                local defaultValue = tClass.fnGetDefaultValue()
                tClass.fnFunc(defaultValue)
            end
        end
    end
    Event.Dispatch(EventType.OnMiniSettingAllUpdate)
end

function LootSetting.CanAutoLoot(dwItemID)
    local bSwitchOpened = GameSettingData.GetNewValue(UISettingKey.AutoLootAll)
    if not bSwitchOpened then return true end

    local item = GetItem(dwItemID)
    if not item then return false end

    local szItemName = ItemData.GetItemNameByItem(item)
    szItemName = UIHelper.GBKToUTF8(szItemName)
    szItemName = extract_chinese(szItemName)

    local bCustomAutoLoot

    -- 自定义黑白名单都是最高优先级
    for _, tInfo in ipairs(Storage.LootSetting.tItemSettingList) do
        local szName = tInfo[1]
        szName = extract_chinese(szName)
        if szItemName == szName then
            bCustomAutoLoot = tInfo[3] == 0
        end
    end

    -- 年兽陶罐过滤
    for szName, bFilter in pairs(MY_Taoguan.O and MY_Taoguan.O.tFilterItem or {}) do
        local szName = extract_chinese(szName)
        if szItemName == szName and bFilter then
            bCustomAutoLoot = false
        end
    end

    if bCustomAutoLoot ~= nil then
        return bCustomAutoLoot
    end

    -- 检查书籍设置
    if item.nGenre == ITEM_GENRE.BOOK and item.nBookID then
        if Storage.LootSetting.bForbidBookHasRead then
            local nBookID, nSegmentID = GlobelRecipeID2BookID(item.nBookID)
            local bRead = g_pClientPlayer.IsBookMemorized(nBookID, nSegmentID)
             if bRead then return false end
        end
        
        if Storage.LootSetting.bForbidBookHasOwned then
            local nBookNum = ItemData.GetBookAllStackNum(item, true)
            if nBookNum > 0 then return false end
        end
    end

    -- 检查品质设置
    if Storage.LootSetting.bAutoLootByQuality then
        if not Storage.LootSetting.tAutoLootQualityList[item.nQuality+1] then return false end
    end

    return true
end

Event.Reg(LootSetting, EventType.OnClientPlayerEnter, function ()
    LootSetting.Init()
end)