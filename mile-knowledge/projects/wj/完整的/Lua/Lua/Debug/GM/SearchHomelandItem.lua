if not SearchHomelandItem then
    SearchHomelandItem = {
        className = "SearchHomelandItem",
        text = '家具查询',
        szPlaceHolder = '输入家具ID或名称',
        nViewID = VIEW_ID.PanelGMRightView,
        tItem = {},
        tTabBase = {},
    }
end

function SearchHomelandItem:ShowSubWindow(tbGMView)
    tbGMView.PanelRightView:setVisible(true)
    tbGMView.LabelExtension:setVisible(true)
    tbGMView.EditSearchRight:setPlaceHolder(SearchHomelandItem.szPlaceHolder)
    if tbGMView.tbLastData~=nil and next(tbGMView.tbLastData) then
        UIHelper.SetString(tbGMView.EditSearchRight, tbGMView.tbLastData.EditLabelRight)
    else
        UIHelper.SetString(tbGMView.EditSearchRight, "")
    end
    UIHelper.SetString(tbGMView.LabelExtension, SearchHomelandItem.text)
end


function SearchHomelandItem:OnClick(tbGMView)
    if not next(SearchHomelandItem.tItem) then
        OutputMessage("MSG_SYS", "第一次加载需要一点时间, 请稍等...\n")
        Timer.AddFrame(SearchHomelandItem, 15, function()
            SearchHomelandItem.FillAll()
            UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
            UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
        end);
    end
    SearchHomelandItem:ShowSubWindow(tbGMView)
    UIHelper.SetString(tbGMView.EditSearchRight, "")
    tbGMView.tbGMPanelRight = SearchHomelandItem
    tbGMView.tbRawDataRight = SearchHomelandItem.tItem
    tbGMView.tbSearchResultRight = SearchHomelandItem.tItem
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end


local tItemBaseHead = {
	Path = "\\settings\\item\\HomelandItem.tab",--PAK需要拷贝的表
	Title =
	{
		{f = "i", t = "ID"},
		{f = "s", t = "Name"},
		{f = "s", t = "_CATEGORY"},
		{f = "s", t = "UiID"},
		{f = "s", t = "Genre"},
		{f = "s", t = "SubType"},
		{f = "s", t = "DetailType"},
		{f = "s", t = "Quality"},
		{f = "s", t = "Price"},
		{f = "s", t = "BindType"},
		{f = "s", t = "MaxExistTime"},
		{f = "s", t = "MaxExistAmount"},
		{f = "s", t = "MaxDurability"},
		{f = "s", t = "CanStack"},
		{f = "s", t = "CanConsume"},
		{f = "s", t = "CanTrade"},
		{f = "s", t = "CanDestroy"},
		{f = "s", t = "ScriptName"},
		{f = "s", t = "SkillID"},
		{f = "s", t = "SkillLevel"},
		{f = "s", t = "_LEVEL"},
		{f = "s", t = "CoolDownID"},
		{f = "s", t = "RequireLevel"},
		{f = "s", t = "RequireProfessionID"},
		{f = "s", t = "RequireProfessionBranch"},
		{f = "s", t = "RequireProfessionLevel"},
		{f = "s", t = "RequireGender"},
		{f = "s", t = "CanUseOnHorse"},
		{f = "s", t = "CanUseInFight"},
		{f = "s", t = "CanGoodCampUse"},
		{f = "s", t = "CanEvilCampUse"},
		{f = "s", t = "CanNeutralCampUse"},
		{f = "s", t = "AucGenre"},
		{f = "s", t = "AucSubType"},
		{f = "s", t = "RequireForce"},
		{f = "s", t = "RequireCamp"},
		{f = "s", t = "TargetType"},
		{f = "s", t = "ExistType"},
		{f = "i", t = "MapBanUseItemMask"}, --2013.05.07，新加列
		{f = "i", t = "IgnoreBindMask"},
		{f = "i", t = "BelongForceMask"},
		{f = "i", t = "CanShared"}, --2017.10.05,新加列
		{f = "i", t = "MapBanTradeItemMask"}, --2017.11.21,新加列
		{f = "i", t = "MapCanExistItemMask"}, --2017.12.12,新加列
		{f = "i", t = "FurnitureType"}, --2021.12.13,新加列
		{f = "i", t = "FurnitureID"}, --2017.12.12,新加列
	}
}

function SearchHomelandItem.LoadTable(tItemBaseHead)
    SearchHomelandItem.tTabBase = KG_Table.Load(tItemBaseHead.Path, tItemBaseHead.Title, TABLE_FILE_OPEN_MODE.NORMAL)
end

function SearchHomelandItem.FillAll()
    SearchHomelandItem.LoadTable(tItemBaseHead)
    local nCount = SearchHomelandItem.tTabBase:GetRowCount()
    for i = 1, nCount do
        local tItem = SearchHomelandItem.tTabBase:GetRow(i)
        local szItemName = '['..tItem.ID..'] '..tItem.Name
        local tTemp = {ID = tItem.ID, Name = szItemName, ButtonLabel = '获取',
                        tBtnStatus = {
                                BtnOperate = true, BtnOperate1 = false, BtnOperate2 = false,
                                BtnOperate3 = false, BtnOperate4 = false
                                    }
                        }
        table.insert(SearchHomelandItem.tItem, tTemp)
    end
end

function SearchHomelandItem:BtnOperate(tbData)
    SendGMCommand("player.AddItem(10 ,".. tbData.ID ..")") --这里要修改道具类型
    OutputMessage("MSG_ANNOUNCE_NORMAL", "获得家具【" ..UIHelper.GBKToUTF8(tbData.Name).. "】\n")
end

function SearchHomelandItem:GetAllData(tbGMView)
    tbGMView.tbSearchResultRight = SearchHomelandItem.tItem
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbSearchResultRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end