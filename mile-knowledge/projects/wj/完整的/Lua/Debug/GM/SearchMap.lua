if not SearchMap then 
    SearchMap = {
        text = '地图传送',
        szPlaceHolder = '输入地图ID或名称或坐标x,y,z',
        nViewID = VIEW_ID.PanelGMRightView,
        tMap = {},
        nTimerID = nil
    }
end



-- 部分特殊场景直接传送到指定坐标，例如JJC地图
tSpecialMap = {
    --JJC
    [127] = {23255, 17863, 1046656},
    [128] = {11948, 16613, 1071296},
    [129] = {17632, 15207, 1050688},
    [137] = {15800, 23773, 1079104},
    [238] = {15364, 12413, 1049408},
    [277] = {17969, 15910, 1108352},
    [362] = {3217, 17151, 1058240},
    [526] = {99548, 87992, 2034368}, --北天药宗传送到指定坐标点
    [529] = {16410, 16759, 1051584},
    [624] = {21635, 15816, 1147648},
    --室内副本
    [32] = {32239, 1819, 1048960}, --战宝
    [46] = {32239, 1819, 1048960}, --英雄战宝
    [160] = {10583, 10978, 1052096}, --战宝军械
    [171] = {10583, 10978, 1052096}, --英雄战宝军械
    [262] = {25595, 2505, 1755328}, --刀轮
    [275] = {25595, 2505, 1755328}, --英雄刀轮
    --
    [74] = {14835, 3590, 1099840},
}

function SearchMap:FillAll()
    SearchMap.tMap = {}
    for i = 1, g_tTable.MapList:GetRowCount() do
        local tRow = g_tTable.MapList:GetRow(i)
        local szMapName = '[' .. tRow.nID .. '] ' .. tRow.szName
        local tTemp = {ID = tRow.nID, Name = szMapName, Type = tRow.szType, Position = {nX = 30000, nY = 30000, nZ = 30000},
                       ButtonLabel = '传送',
                       tBtnStatus = {
                            BtnOperate = true, BtnOperate1 = false, BtnOperate2 = false,
                            BtnOperate3 = false, BtnOperate4 = false
                                }
                        }
        if tRow.nID ~= 0 then
            if tSpecialMap[tRow.nID] then
                tTemp.Position.nX = tSpecialMap[tRow.nID][1]
                tTemp.Position.nY = tSpecialMap[tRow.nID][2]
                tTemp.Position.nZ = tSpecialMap[tRow.nID][3]
            end
            table.insert(SearchMap.tMap, tTemp)
        end
    end
end

function SearchMap:ShowSubWindow(tbGMView)
    tbGMView.PanelRightView:setVisible(true)
    tbGMView.LabelExtension:setVisible(true)
    tbGMView.BtnExecute:setVisible(true)
    UIHelper.SetString(tbGMView.LabelExecute, "传送")
    tbGMView.EditSearchRight:setPlaceHolder(SearchMap.szPlaceHolder)
    if tbGMView.tbLastData~=nil and next(tbGMView.tbLastData) then
        UIHelper.SetString(tbGMView.EditSearchRight, tbGMView.tbLastData.EditLabelRight)
    else
        UIHelper.SetString(tbGMView.EditSearchRight, "")
    end
    UIHelper.SetString(tbGMView.LabelExtension, SearchMap.text)
end

function SearchMap:OnClick(tbGMView)
    if not next(SearchMap.tMap) then
        OutputMessage("MSG_SYS", "第一次加载需要一点时间, 请稍等...\n")
        SearchMap.FillAll()
    end
    SearchMap:ShowSubWindow(tbGMView)
    UIHelper.SetString(tbGMView.EditSearchRight, "")
    tbGMView.tbGMPanelRight = SearchMap
    tbGMView.tbRawDataRight = SearchMap.tMap
    tbGMView.tbSearchResultRight = SearchMap.tMap
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end

function SearchMap:BtnOperate(tbData)
        local nSwitchMapID = tbData.ID
        local szMapName = UIHelper.GBKToUTF8(tbData.Name)
        local szMapType = tbData.Type
        local szGM
        local nX, nY, nZ  = tbData.Position.nX, tbData.Position.nY, tbData.Position.nZ
        local szNoticeMsg = "已执行传送【" .. szMapName .. "】指令,注意服务器有无报错。\n"
        -- if tSpecialMap[nSwitchMapID] then
        --     local nX, nY, nZ = tSpecialMap[nSwitchMapID][1], tSpecialMap[nSwitchMapID][2], tSpecialMap[nSwitchMapID][3]
        -- end
        if szMapType and (szMapType == "BATTLE_FIELD" or szMapType == "ARENA") then
            szGM = nSwitchMapID .. ", 1, " .. nX .. ", " .. nY .. ", " .. nZ
        else
            if  szMapType == "TONG" then
                local dwTongID = GetClientPlayer().dwTongID
                if dwTongID ~= 0 then
                    szGM = nSwitchMapID .. ", player.dwTongID," .. nX .. ", " .. nY .. ", " .. nZ
                else
                    OutputMessage("MSG_SYS", "你还没有加入帮会")
                    return
                end
            else
                szGM = nSwitchMapID .. ", " .. nX .. ", " .. nY .. ", " .. nZ
            end
        end
        OutputMessage("MSG_SYS", szNoticeMsg)
        SendGMCommand("local scene=player.GetScene();if scene.nType == MAP_TYPE.NORMAL_MAP or scene.nType == MAP_TYPE.BIRTH_MAP then player.SetLastEntry(scene.dwMapID, scene.nCopyIndex, player.nX, player.nY, player.nZ, 1) end;player.SwitchMap(".. szGM ..")")
        UIMgr.Close(VIEW_ID.PanelGM)
end

function SearchMap:BtnExecute(tbGMView)
    local szPosition = UIHelper.GetString(tbGMView.EditSearchRight)
    SendGMCommand(string.format("player.SetPosition(%s)", szPosition))
end

function SearchMap:GetAllData(tbGMView)
    tbGMView.tbSearchResultRight = SearchMap.tMap
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbSearchResultRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end