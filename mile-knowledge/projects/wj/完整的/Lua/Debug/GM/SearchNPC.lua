if not SearchNPC then
    SearchNPC = {
        className = "SearchNPC",
        text = "NPC查询",
        szPlaceHolder = "输入NPC ID或名称",
        nViewID = VIEW_ID.PanelGMRightView,
        tNPC = {},
        tTabBase = {},
    }
end

function SearchNPC:FillAll()
    local tNPC = g_tTable.NpcTemplate
    local nRow = tNPC:GetRowCount()
    for i = 2, nRow  do
        local tNpcStringInfo = tNPC:GetRow(i)
        local szNpcName = '['..tNpcStringInfo.nID..'] '..tNpcStringInfo.szName
        if tNpcStringInfo then
            local tTemp = { ID = tNpcStringInfo.nID, Name = szNpcName, ButtonLabel = '召唤',
                            tBtnStatus = {
                                        BtnOperate = true, BtnOperate1 = false, BtnOperate2 = false,
                                        BtnOperate3 = false, BtnOperate4 = false
                                        }
                            }
            table.insert(SearchNPC.tNPC, tTemp)
        end
    end
end


function SearchNPC:ShowSubWindow(tbGMView)
    tbGMView.PanelRightView:setVisible(true)
    tbGMView.LabelExtension:setVisible(true)
    tbGMView.EditSearchRight:setPlaceHolder(SearchNPC.szPlaceHolder)
    if tbGMView.tbLastData~=nil and next(tbGMView.tbLastData) then
        UIHelper.SetString(tbGMView.EditSearchRight, tbGMView.tbLastData.EditLabelRight)
    else
        UIHelper.SetString(tbGMView.EditSearchRight, "")
    end
    UIHelper.SetString(tbGMView.LabelExtension, SearchNPC.text)
end

function SearchNPC:OnClick(tbGMView)
    if not next(SearchNPC.tNPC) then
        OutputMessage("MSG_SYS", "第一次加载需要一点时间, 请稍等...\n")
        Timer.AddFrame(SearchNPC, 15, function()
            SearchNPC.FillAll()
            UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
            UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
        end);
    end
    SearchNPC:ShowSubWindow(tbGMView)
    UIHelper.SetString(tbGMView.EditSearchRight, "")
    tbGMView.tbGMPanelRight = SearchNPC
    tbGMView.tbRawDataRight = SearchNPC.tNPC
    tbGMView.tbSearchResultRight = SearchNPC.tNPC
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end

function SearchNPC:BtnOperate(tbData)
    local player = GetClientPlayer()
    local nFaceDirection = player.nFaceDirection
    SendGMCommand("player.GetScene().CreateNpc(" .. tbData.ID .. "," .. player.nX .. "," .. player.nY .. "," .. player.nZ .. ", " .. nFaceDirection .. ", -1)")
    OutputMessage("MSG_ANNOUNCE_NORMAL", "NPC【" .. UIHelper.GBKToUTF8(tbData.Name) .. "】已召唤到你的位置，请关注服务器信息\n")
    OutputMessage("MSG_SYS", "NPC【" .. UIHelper.GBKToUTF8(tbData.Name) .. "】已召唤到你的位置，请关注服务器信息\n")
    return
end

function SearchNPC:GetAllData(tbGMView)
    tbGMView.tbSearchResultRight = SearchNPC.tNPC
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbSearchResultRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end