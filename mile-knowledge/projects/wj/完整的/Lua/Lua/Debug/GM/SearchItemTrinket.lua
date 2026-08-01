if not SearchItemTrinket then
    SearchItemTrinket = {
        className = "SearchItemTrinket",
        text = '【饰品】',
        szPlaceHolder = '输入饰品ID或名称',
        nViewID = VIEW_ID.PanelGMRightView,
        tItem = {},
        tTabBase = {},
    }
end

function SearchItemTrinket:ShowSubWindow(tbGMView)
    tbGMView.PanelRightView:setVisible(true)
    tbGMView.LabelExtension:setVisible(true)
    tbGMView.EditSearchRight:setPlaceHolder(SearchItemTrinket.szPlaceHolder)
    if tbGMView.tbLastData~=nil and next(tbGMView.tbLastData) then
        UIHelper.SetString(tbGMView.EditSearchRight, tbGMView.tbLastData.EditLabelRight)
    else
        UIHelper.SetString(tbGMView.EditSearchRight, "")
    end
    UIHelper.SetString(tbGMView.LabelExtension, SearchItemTrinket.text)
end

function SearchItemTrinket:OnClick(tbGMView)
    if not next(SearchItemTrinket.tItem) then
        OutputMessage("MSG_SYS", "第一次加载需要一点时间, 请稍等...\n")
        Timer.AddFrame(SearchItemTrinket, 15, function()
            SearchItemTrinket.FillAll()
            UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
            UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
        end);
    end
    SearchItemTrinket:ShowSubWindow(tbGMView)
    UIHelper.SetString(tbGMView.EditSearchRight, "")
    tbGMView.tbGMPanelRight = SearchItemTrinket
    tbGMView.tbRawDataRight = SearchItemTrinket.tItem
    tbGMView.tbSearchResultRight = SearchItemTrinket.tItem
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end


local tItemBaseHead
if not _G.bClassic then
    tItemBaseHead = {
        Path = "\\settings\\item\\Custom_Trinket.tab",--PAK需要拷贝的表
        Title =
        {
            {f = "i", t = "ID"},
            {f = "s", t = "Name"},
            {f = "s", t = "UiID"},
            {f = "s", t = "RepresentID"},
            {f = "s", t = "ColorID"},
            {f = "s", t = "ColorID1"},--2015.10.07新加列，注意列的顺序必须完全跟表的一样，否则读表数据错乱；
            {f = "s", t = "ColorID2"},--2015.10.07新加列
            {f = "s", t = "Genre"},
            {f = "s", t = "SubType"},
            {f = "s", t = "DetailType"},
            {f = "s", t = "Price"},
            {f = "s", t = "Level"},
            {f = "s", t = "BindType"},
            {f = "s", t = "MaxDurability"},
            {f = "s", t = "AbradeRate"},
            {f = "s", t = "MaxExistTime"},
            {f = "s", t = "MaxExistAmount"},
            {f = "s", t = "CanTrade"},
            {f = "s", t = "CanDestroy"},
            {f = "s", t = "SetID"},
            {f = "s", t = "ScriptName"},
            {f = "s", t = "Quality"},
            {f = "s", t = "Base1Type"},
            {f = "s", t = "Base1Min"},
            {f = "s", t = "Base1Max"},
            {f = "s", t = "Base2Type"},
            {f = "s", t = "Base2Min"},
            {f = "s", t = "Base2Max"},
            {f = "s", t = "Base3Type"},
            {f = "s", t = "Base3Min"},
            {f = "s", t = "Base3Max"},
            {f = "s", t = "Base4Type"},
            {f = "s", t = "Base4Min"},
            {f = "s", t = "Base4Max"},
            {f = "s", t = "Base5Type"},
            {f = "s", t = "Base5Min"},
            {f = "s", t = "Base5Max"},
            {f = "s", t = "Base6Type"},
            {f = "s", t = "Base6Min"},
            {f = "s", t = "Base6Max"},
            {f = "s", t = "Require1Type"},
            {f = "s", t = "Require1Value"},
            {f = "s", t = "Require2Type"},
            {f = "s", t = "Require2Value"},
            {f = "s", t = "Require3Type"},
            {f = "s", t = "Require3Value"},
            {f = "s", t = "Require4Type"},
            {f = "s", t = "Require4Value"},
            {f = "s", t = "Require5Type"},
            {f = "s", t = "Require5Value"},
            {f = "s", t = "Require6Type"},
            {f = "s", t = "Require6Value"},
            {f = "s", t = "Magic1Type"},
            {f = "s", t = "Magic2Type"},
            {f = "s", t = "Magic3Type"},
            {f = "s", t = "Magic4Type"},
            {f = "s", t = "Magic5Type"},
            {f = "s", t = "Magic6Type"},
            {f = "s", t = "Magic7Type"},
            {f = "s", t = "Magic8Type"},
            {f = "s", t = "Magic9Type"},
            {f = "s", t = "Magic10Type"},
            {f = "s", t = "Magic11Type"},
            {f = "s", t = "Magic12Type"},
            {f = "s", t = "Magic13Type"},
            {f = "s", t = "Magic14Type"},
            {f = "s", t = "Magic15Type"},
            {f = "s", t = "Magic16Type"},
            {f = "s", t = "SkillID"},
            {f = "s", t = "SkillLevel"},
            {f = "s", t = "BelongSchool"},
            {f = "s", t = "MagicKind"},
            {f = "s", t = "MagicType"},
            {f = "s", t = "GetType"},
            {f = "s", t = "_CATEGORY"},
            {f = "s", t = "CoolDownID"},
            {f = "s", t = "IconTag1"},
            {f = "s", t = "IconTag2"},
            {f = "s", t = "IsSpecialIcon"},
            {f = "s", t = "IsSpecialRepresent"},
            {f = "s", t = "IconID"},
            {f = "s", t = "CanSetColor"},
            {f = "s", t = "AucGenre"},
            {f = "s", t = "AucSubType"},
            {f = "s", t = "RequireCamp"},
            {f = "s", t = "RequireProfessionID"},
            {f = "s", t = "RequireProfessionLevel"},
            {f = "s", t = "RequireProfessionBranch"},
            {f = "s", t = "PackageGenerType"},
            {f = "s", t = "PackageSubType"},
            {f = "s", t = "TargetType"},
            {f = "s", t = "EnchantRepresentID1"},
            {f = "s", t = "EnchantRepresentID2"},
            {f = "s", t = "EnchantRepresentID3"},
            {f = "s", t = "EnchantRepresentID4"},
            {f = "s", t = "ExistType"},
            {f = "s", t = "EquipCoolDownID"},
            {f = "s", t = "RecommendID"},
            {f = "s", t = "DiamondTypeMask1"},
            {f = "s", t = "DiamondAttributeID1"},
            {f = "s", t = "DiamondTypeMask2"},
            {f = "s", t = "DiamondAttributeID2"},
            {f = "s", t = "DiamondTypeMask3"},
            {f = "s", t = "DiamondAttributeID3"},
            {f = "s", t = "MaxStrengthLevel"},
            {f = "s", t = "CanApart"},
            {f = "i", t = "IgnoreBindMask"},
            {f = "i", t = "CanExterior"},
            {f = "i", t = "BelongForceMask"},
            {f = "i", t = "MapBanUseItemMask"}, --2013.05.07，新加列
            {f = "i", t = "Represent1"},
            {f = "i", t = "SpecialRepair"},
            {f = "i", t = "CanChangeMagic"},--2013.09.03,新加列
            {f = "i", t = "GrowthTabIndex"},--2016.03.31,新加列
            {f = "i", t = "NeedGrowthExp"},--2016.03.31,新加列
            {f = "i", t = "CanShared"}, --2017.10.05,新加列
            {f = "i", t = "MapBanTradeItemMask"}, --2017.11.21,新加列
            {f = "i", t = "MapCanExistItemMask"}, --2017.12.12,新加列
            {f = "i", t = "MapBanEquipItemMask"}, --2017.12.12,新加列
            {f = "i", t = "EquipUsage"}, --2018.5.25,新加列
            {f = "i", t = "RepairPriceRebate"}, --2018.12.26,新加列
            {f = "i", t = "AucMountRecommendMask"}, --2025.3.3,新加列 交易行心法分类掩码，默认值是0不区分心法
			{f = "i", t = "BelongSchoolMask"}, --2025.09.25 心法需求优先分配掩码
        }
    }
else
    tItemBaseHead = {
    Path = "\\settings\\item\\Custom_Trinket.tab",--PAK需要拷贝的表
    Title =
        {
            {f = "i", t = "ID"},
            {f = "s", t = "Name"},
            {f = "s", t = "UiID"},
            {f = "s", t = "RepresentID"},
            {f = "s", t = "ColorID"},
            {f = "s", t = "ColorID1"},
            {f = "s", t = "ColorID2"},
            {f = "s", t = "Genre"},
            {f = "s", t = "SubType"},
            {f = "s", t = "DetailType"},
            {f = "s", t = "Price"},
            {f = "s", t = "Level"},
            {f = "s", t = "BindType"},
            {f = "s", t = "MaxDurability"},
            {f = "s", t = "AbradeRate"},
            {f = "s", t = "MaxExistTime"},
            {f = "s", t = "MaxExistAmount"},
            {f = "s", t = "CanTrade"},
            {f = "s", t = "CanDestroy"},
            {f = "s", t = "SetID"},
            {f = "s", t = "ScriptName"},
            {f = "s", t = "Quality"},
            {f = "s", t = "Base1Type"},
            {f = "s", t = "Base1Min"},
            {f = "s", t = "Base1Max"},
            {f = "s", t = "Base2Type"},
            {f = "s", t = "Base2Min"},
            {f = "s", t = "Base2Max"},
            {f = "s", t = "Base3Type"},
            {f = "s", t = "Base3Min"},
            {f = "s", t = "Base3Max"},
            {f = "s", t = "Base4Type"},
            {f = "s", t = "Base4Min"},
            {f = "s", t = "Base4Max"},
            {f = "s", t = "Base5Type"},
            {f = "s", t = "Base5Min"},
            {f = "s", t = "Base5Max"},
            {f = "s", t = "Base6Type"},
            {f = "s", t = "Base6Min"},
            {f = "s", t = "Base6Max"},
            {f = "s", t = "Require1Type"},
            {f = "s", t = "Require1Value"},
            {f = "s", t = "Require2Type"},
            {f = "s", t = "Require2Value"},
            {f = "s", t = "Require3Type"},
            {f = "s", t = "Require3Value"},
            {f = "s", t = "Require4Type"},
            {f = "s", t = "Require4Value"},
            {f = "s", t = "Require5Type"},
            {f = "s", t = "Require5Value"},
            {f = "s", t = "Require6Type"},
            {f = "s", t = "Require6Value"},
            {f = "s", t = "Magic1Type"},
            {f = "s", t = "Magic2Type"},
            {f = "s", t = "Magic3Type"},
            {f = "s", t = "Magic4Type"},
            {f = "s", t = "Magic5Type"},
            {f = "s", t = "Magic6Type"},
            {f = "s", t = "Magic7Type"},
            {f = "s", t = "Magic8Type"},
            {f = "s", t = "Magic9Type"},
            {f = "s", t = "Magic10Type"},
            {f = "s", t = "Magic11Type"},
            {f = "s", t = "Magic12Type"},
            {f = "s", t = "SkillID"},
            {f = "s", t = "SkillLevel"},
            {f = "s", t = "BelongSchool"},
            {f = "s", t = "MagicKind"},
            {f = "s", t = "MagicType"},
            {f = "s", t = "GetType"},
            {f = "s", t = "BelongMap"},
            {f = "s", t = "_CATEGORY"},
            {f = "s", t = "CoolDownID"},
            {f = "s", t = "IconTag1"},
            {f = "s", t = "IconTag2"},
            {f = "s", t = "IsSpecialIcon"},
            {f = "s", t = "IsSpecialRepresent"},
            {f = "s", t = "IconID"},
            {f = "s", t = "CanSetColor"},
            {f = "s", t = "AucGenre"},
            {f = "s", t = "AucSubType"},
            {f = "s", t = "RequireCamp"},
            {f = "s", t = "RequireProfessionID"},
            {f = "s", t = "RequireProfessionLevel"},
            {f = "s", t = "RequireProfessionBranch"},
            {f = "s", t = "PackageGenerType"},
            {f = "s", t = "PackageSubType"},
            {f = "s", t = "TargetType"},
            {f = "s", t = "EnchantRepresentID1"},
            {f = "s", t = "EnchantRepresentID2"},
            {f = "s", t = "EnchantRepresentID3"},
            {f = "s", t = "EnchantRepresentID4"},
            {f = "s", t = "ExistType"},
            {f = "s", t = "EquipCoolDownID"},
            {f = "s", t = "RecommendID"},
            {f = "s", t = "DiamondTypeMask1"},
            {f = "s", t = "DiamondAttributeID1"},
            {f = "s", t = "DiamondTypeMask2"},
            {f = "s", t = "DiamondAttributeID2"},
            {f = "s", t = "DiamondTypeMask3"},
            {f = "s", t = "DiamondAttributeID3"},
            {f = "s", t = "MaxStrengthLevel"},
            {f = "s", t = "CanApart"},
            {f = "i", t = "IgnoreBindMask"},
            {f = "i", t = "CanExterior"},
            {f = "i", t = "BelongForceMask"},
            {f = "i", t = "MapBanUseItemMask"},
            {f = "i", t = "Represent1"},
            {f = "i", t = "SpecialRepair"},
            {f = "i", t = "CanChangeMagic"},
            {f = "i", t = "GrowthTabIndex"},
            {f = "i", t = "NeedGrowthExp"},
        }
    }
end


function SearchItemTrinket.LoadTable(tItemBaseHead)
    SearchItemTrinket.tTabBase = KG_Table.Load(tItemBaseHead.Path, tItemBaseHead.Title, TABLE_FILE_OPEN_MODE.NORMAL)
end

function SearchItemTrinket.FillAll()
    SearchItemTrinket.LoadTable(tItemBaseHead)
    local nCount = SearchItemTrinket.tTabBase:GetRowCount()
    for i = 1, nCount do
        local tItem = SearchItemTrinket.tTabBase:GetRow(i)
        local szItemName = '['..tItem.ID..'] '..tItem.Name
        local tTemp = {ID = tItem.ID, Name = szItemName, ButtonLabel = '获取',
                        tBtnStatus = {
                            BtnOperate = true, BtnOperate1 = false, BtnOperate2 = false,
                            BtnOperate3 = false, BtnOperate4 = false
                                }
    } --这里修改
        table.insert(SearchItemTrinket.tItem, tTemp)
    end
end

function SearchItemTrinket:BtnOperate(tbData)
    SendGMCommand("player.AddItem(8 ,".. tbData.ID ..")") --这里要修改道具类型
    OutputMessage("MSG_ANNOUNCE_NORMAL", "获得饰品【" ..UIHelper.GBKToUTF8(tbData.Name).. "】\n")
end

function SearchItemTrinket:GetAllData(tbGMView)
    tbGMView.tbSearchResultRight = SearchItemTrinket.tItem
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbSearchResultRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end