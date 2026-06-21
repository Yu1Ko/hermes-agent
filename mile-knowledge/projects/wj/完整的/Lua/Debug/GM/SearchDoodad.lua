if not SearchDoodad then
    SearchDoodad = {
        className = "SearchDoodad",
        text = "Doodad",
        szPlaceHolder = "输入Doodad ID或名称",
        nViewID = VIEW_ID.PanelGMRightView,
        tDoodad = {},
        tTabBase = {},
    }
end

function SearchDoodad:FillAll()
    local tDoodad = g_tTable.DoodadTemplate
    local nRow = tDoodad:GetRowCount()
    for i = 2, nRow  do
        local tDoodadStringInfo = tDoodad:GetRow(i)
        local szDoodadName = '['..tDoodadStringInfo.nID..'] '..tDoodadStringInfo.szName
        if tDoodadStringInfo then
            local tTemp = { ID = tDoodadStringInfo.nID, Name = szDoodadName, ButtonLabel = '召唤',
                            tBtnStatus = {
                                        BtnOperate = true, BtnOperate1 = false, BtnOperate2 = false,
                                        BtnOperate3 = false, BtnOperate4 = false
                                        }
                            }
            table.insert(SearchDoodad.tDoodad, tTemp)
        end
    end
end

function SearchDoodad:ShowSubWindow(tbGMView)
    tbGMView.PanelRightView:setVisible(true)
    tbGMView.LabelExtension:setVisible(true)
    tbGMView.EditSearchRight:setPlaceHolder(SearchDoodad.szPlaceHolder)
    if tbGMView.tbLastData~=nil and next(tbGMView.tbLastData) then
        UIHelper.SetString(tbGMView.EditSearchRight, tbGMView.tbLastData.EditLabelRight)
    else
        UIHelper.SetString(tbGMView.EditSearchRight, "")
    end
    UIHelper.SetString(tbGMView.LabelExtension, SearchDoodad.text)
end

function SearchDoodad:OnClick(tbGMView)
    if not next(SearchDoodad.tDoodad) then
        OutputMessage("MSG_SYS", "第一次加载需要一点时间, 请稍等...\n")
        Timer.AddFrame(SearchDoodad, 15, function()
            SearchDoodad.FillAll()
            UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
            UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
        end);

    end
    SearchDoodad:ShowSubWindow(tbGMView)
    UIHelper.SetString(tbGMView.EditSearchRight, "")
    tbGMView.tbGMPanelRight = SearchDoodad
    tbGMView.tbRawDataRight = SearchDoodad.tDoodad
    tbGMView.tbSearchResultRight = SearchDoodad.tDoodad
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end

function SearchDoodad:BtnOperate(tbData)
    local player = GetClientPlayer()
    SendGMCommand("player.GetScene().CreateDoodad(" .. tbData.ID .. "," .. player.nX .. "," .. player.nY .. "," .. player.nZ .. ", 0)")
    OutputMessage("MSG_ANNOUNCE_NORMAL", "Doodad【" .. UIHelper.GBKToUTF8(tbData.Name) .. "】已召唤到你的位置，请关注服务器信息\n")
    OutputMessage("MSG_SYS", "Doodad【" .. UIHelper.GBKToUTF8(tbData.Name) .. "】已召唤到你的位置，请关注服务器信息\n")
    return
end

function SearchDoodad:GetAllData(tbGMView)
    tbGMView.tbSearchResultRight = SearchDoodad.tDoodad
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbSearchResultRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end
