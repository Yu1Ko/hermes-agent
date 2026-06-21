if not SearchCraft then
    SearchCraft = {
        text = "配方学习",
        szPlaceHolder = "输入配方ID或名称",
        nViewID = VIEW_ID.PanelGMRightView,
        bInit = false,
        szLastCraftLabel = '',
        tCookingTabBase = {}, 
        tTailoringTabBase = {},
        tFoundingTabBase = {}, 
        tMedicineTabBase = {},
        tFurnitureTabBase = {},
        tTabBase = {},
    }
end

TogLeftToID = {
    {["nMaseterID"] = 22, ["nProfessionID"] = 6},
    {["nMaseterID"] = 16, ["nProfessionID"] = 7},
    {["nMaseterID"] = 1, ["nProfessionID"] = 4},
    {["nMaseterID"] = 10, ["nProfessionID"] = 5},
    {["nMaseterID"] = 31, ["nProfessionID"] = 15},
}

function SearchCraft:GetProfession()
    for _, data in pairs(TogLeftToID) do
        if data.nProfessionID == SearchCraft.nSelectPushType then
            local tbProfession = GetMasterRecipeList(data.nMaseterID, true, true, true)--根据条件返回配方
            return tbProfession
        end
    end
end



function SearchCraft:UpdateRecipeTable()
    if next(SearchCraft.tTabBase[SearchCraft.nSelectPushType]) then
        return
    end
    local tbProfession = SearchCraft.GetProfession()
    local tRes = {}
    local tbRecipe = {}
    for i=1, #tbProfession, 1 do
        local v = tbProfession[i]
        local recipe = GetRecipe(v.dwCraftID, v.dwRecipeID)
        local szName = Table_GetRecipeName(v.dwCraftID, v.dwRecipeID)
        if recipe and szName ~= '' then
            local szRecipeName = '['..v.dwRecipeID..'] '..UIHelper.UTF8ToGBK(szName)
            local tTemp = {ID = v.dwRecipeID, Name = szRecipeName,
                                tBtnStatus = { 
                                                BtnOperate = false, BtnOperate2 = true,
                                                BtnOperate4 = true
                                            },
                                tBtnLabel = {
                                                LabelOperate2 = '获取材料', LabelOperate4 = '学习配方'
                                            }
                            }
            table.insert(SearchCraft.tTabBase[v.dwCraftID], tTemp)
        end
    end
end



local function GetRequireItems(recipe)
    local player = GetClientPlayer()
    local tItems = {}
    for nIndex = 1, 6, 1 do
        local nType  = recipe["dwRequireItemType"..nIndex]
        local nID     = recipe["dwRequireItemIndex"..nIndex]
        local nNeed  = recipe["dwRequireItemCount"..nIndex]

        local nSatisfy = 1
        if nNeed > 0 then
            local nCount = player.GetItemAmount(nType, nID)
            if nNeed > nCount then
                nSatisfy = 0
            end
            table.insert(tItems, {["nType"]=nType, ["nID"]=nID, ["nNeed"]=nNeed, ["nCount"]=nCount, ["nSatisfy"]=nSatisfy})
        end
    end
    table.sort(tItems, function(a, b) return a.nSatisfy < b.nSatisfy end)

    return tItems
end


function SearchCraft:ShowSubWindow(tbGMView)
    tbGMView.PanelRightView:setVisible(true)
    -- tbGMView.LabelTitleCraft:setVisible(true)
    tbGMView.WidgetCraft:setVisible(true)
    tbGMView.EditSearchRight:setPlaceHolder(SearchCraft.szPlaceHolder)
    if tbGMView.tbLastData~=nil and next(tbGMView.tbLastData) then
        UIHelper.SetString(tbGMView.EditSearchRight, tbGMView.tbLastData.EditLabelRight)
        -- 设置勾选状态, 恢复原来的配方勾选
        UIHelper.SetString(tbGMView.LabelDropList, SearchCraft.szLastCraftLabel)
        tbGMView.tbGMPanelRight = SearchCraft
        tbGMView.tbRawDataRight = SearchCraft.tTabBase[SearchCraft.nSelectPushType]
        tbGMView.tbRawDataRight = SearchCraft.tTabBase[SearchCraft.nSelectPushType]
        UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
        UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
    else
        UIHelper.SetString(tbGMView.EditSearchRight, "")
    end
    self:ToggleSelect(tbGMView)
end

function SearchCraft:OnClick(tbGMView)
    UIHelper.RemoveAllChildren(tbGMView.ScrollViewDropList)
    if not SearchCraft.bInit then
        SearchCraft.tbDropItemSort = {
            { nKey = 4, szText = "烹饪", tTabBase = SearchCraft.tCookingTabBase},
            { nKey = 5, szText = "缝纫", tTabBase = SearchCraft.tTailoringTabBase},
            { nKey = 6, szText = "铸造", tTabBase = SearchCraft.tFoundingTabBase},
            { nKey = 7, szText = "医术", tTabBase = SearchCraft.tMedicineTabBase},
            { nKey = 15, szText = "梓匠", tTabBase = SearchCraft.tFurnitureTabBase},
        }
        SearchCraft.tbItems = {}
        for _, v in ipairs(SearchCraft.tbDropItemSort) do
            table.insert(SearchCraft.tbItems, {nKey = v.nKey, szText = v.szText})
            SearchCraft.tTabBase[v.nKey] = v.tTabBase
        end
        SearchCraft.bInit = true
        SearchCraft.nSelectPushType = 4
        local _MsgError = function ()
            OutputMessage("MSG_ANNOUNCE_NORMAL", "获得失败请登入场景后再尝试!\n")
            SearchCraft.bInit = false
        end
        xpcall(SearchCraft.UpdateRecipeTable, _MsgError)
    end
    SearchCraft:ShowSubWindow(tbGMView)
    UIHelper.SetString(tbGMView.EditSearchRight, "")
    UIHelper.SetString(tbGMView.LabelDropList, '烹饪')
    tbGMView.tbGMPanelRight = SearchCraft
    tbGMView.tbRawDataRight = SearchCraft.tCookingTabBase
    tbGMView.tbSearchResultRight = SearchCraft.tCookingTabBase
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end

function SearchCraft:ToggleSelect(tbGMView)
        UIHelper.RemoveAllChildren(tbGMView.ScrollViewDropList)
        for _, tbItem in ipairs(SearchCraft.tbItems) do
            local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetSelectTog358X86, tbGMView.ScrollViewDropList)
            scriptItem:OnEnter(tbItem.nKey, tbItem.szText, function (nKey, szText)
                SearchCraft.nSelectPushType = nKey
                UIHelper.SetSelected(tbGMView.TogDropList, false)
                UIHelper.SetString(tbGMView.LabelDropList, szText)
                SearchCraft:UpdateRecipeTable()
                tbGMView.tbRawDataRight = SearchCraft.tTabBase[SearchCraft.nSelectPushType]
                tbGMView.tbSearchResultRight = SearchCraft.tTabBase[SearchCraft.nSelectPushType]
                UIHelper.SetString(tbGMView.EditSearchRight, "")
                UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbSearchResultRight, PREFAB_ID.WidgetSunmon)
                UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
                SearchCraft.szLastCraftLabel = tbItem.szText
            end, tbItem.nKey == SearchCraft.nSelectPushType)
    
            if tbItem.nKey == SearchCraft.nSelectPushType then
                UIHelper.SetString(tbGMView.LabelDropList, tbItem.szText)
            end
            UIHelper.ToggleGroupAddToggle(tbGMView.WidgetCraft, scriptItem.ToggleSelect)
        end
        UIHelper.ScrollViewDoLayout(tbGMView.ScrollViewDropList)
        UIHelper.ScrollToTop(tbGMView.ScrollViewDropList, 0)
end


function SearchCraft:BtnSummon(tbGMView)
    if not _G.bClassic then
        SendGMCommand("local tdoodad = {183,342,343,344,8169};for k, v in ipairs(tdoodad) do player.GetScene().CreateDoodad(v, player.nX+100*k,player.nY,player.nZ,0) end")
    else
        SendGMCommand("local tdoodad = {183,342,343,344};for k, v in ipairs(tdoodad) do player.GetScene().CreateDoodad(v, player.nX+100*k,player.nY,player.nZ,0) end")
        SendGMCommand("local tItem = {192,193,194,195,196,3094};for k, v in ipairs(tItem) do player.AddItem(5, v) end")
        OutputMessage("MSG_ANNOUNCE_NORMAL", "技艺需求item已添加 \n")
    end
    OutputMessage("MSG_ANNOUNCE_NORMAL", "技艺需求doodad已召唤\n")
end


function SearchCraft:BtnOperate2(tbData)
    local recipe  = GetRecipe(SearchCraft.nSelectPushType, tbData.ID)
    local tItems = GetRequireItems(recipe)
    for i, v in ipairs(tItems) do
        SendGMCommand("player.AddItem(" ..v.nType ..", " ..v.nID ..")")
        local szItemName = Table_GetItemName(v.nID)
        OutputMessage("MSG_ANNOUNCE_NORMAL", "获得材料【" .. UIHelper.GBKToUTF8(szItemName) .. "】\n")
    end
end

function SearchCraft:BtnOperate4(tbData)
    SendGMCommand("if player.CanLearnProfession(" .. SearchCraft.nSelectPushType ..") then player.LearnProfession(" .. SearchCraft.nSelectPushType ..") end")
    SendGMCommand("player.LearnRecipe(" .. SearchCraft.nSelectPushType .." ,".. tbData.ID ..")") --这里要修改道具类型
    OutputMessage("MSG_ANNOUNCE_NORMAL", "学习配方【" .. UIHelper.GBKToUTF8(tbData.Name) .. "】\n")
end

function SearchCraft:GetAllData(tbGMView)
    SearchCraft:UpdateRecipeTable()
    tbGMView.tbRawDataRight = SearchCraft.tTabBase[SearchCraft.nSelectPushType]
    tbGMView.tbSearchResultRight = SearchCraft.tTabBase[SearchCraft.nSelectPushType]
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbSearchResultRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end