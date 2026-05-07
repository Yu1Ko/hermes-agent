if not SearchPanel then
    SearchPanel = {
        tSearchResult = {},
        tMapList = {},
        tNPCList = {},
        tInfo = {},
        nSelectPushType = 1,
        szMapName = '',
        bTogDelivery = false
    }
end

function SearchPanel.NpcTemplate_Load()
    if not SearchPanel.NpcTemplate then
        SearchPanel.NpcTemplate = GMMgr.ReadTabFile("settings/NpcTemplate.tab")
    end
end

function SearchPanel.GetMapList()
    local tTempMapList = {}
    if not next(SearchPanel.tMapList) then
        tTempMapList =  GMMgr.ReadTabFile("settings/MapList.tab")
    end
    for _, v in ipairs(tTempMapList) do
        table.insert(SearchPanel.tMapList, {nKey = v.ID, szText = UIHelper.GBKToUTF8(v.Name)})
    end
end


function SearchPanel.OnClickCell(szMapName, tPanelCell)
    SearchPanel.bTogDelivery = UIHelper.GetSelected(tPanelCell.tbPanel.TogDelivery)
    if SearchPanel.bTogDelivery then
        tPanelCell.tbPanel.SearchPanelRight:setVisible(false)
        local player = GetClientPlayer()
        if not player then
            return
        end
        local nCurrentMapID = player.GetMapID()
        local nSearchPanelMapID
        for k, v in ipairs(SearchPanel.tMapList) do
            -- if v.Name == SearchPanel.szMapName and k == SearchPanel.dwShopID then
            --     nSearchPanelMapID = tonumber(v.ID)
            -- end
            if v.szText == szMapName  then
                nSearchPanelMapID = tonumber(v.nKey)
                break
            end
        end

        -- 这里先进行一次判断如果已经是搜索模式下的结果就直接走CMD
        if tPanelCell.tbCell.nIndex then
            local tNPCInfo = tPanelCell.tbCell
            local szGMCMD
            if nCurrentMapID == nSearchPanelMapID then
                szGMCMD = "player.SetPosition(" .. tNPCInfo.nX .. ", "
                .. tNPCInfo.nY .. ", " .. tNPCInfo.nZ .. ")"
            else
                szGMCMD = "player.SwitchMap(" .. nSearchPanelMapID .. ","
                .. tNPCInfo.nX .. ", " .. tNPCInfo.nY .. ", " .. tNPCInfo.nZ .. ")"
                OutputMessage("MSG_ANNOUNCE_NORMAL", "准备切换地图 【"..szMapName.."】请稍等\n")
            end
            SendGMCommand(szGMCMD)
            return
        end

        SearchPanel.SearchNPC(szMapName, UIHelper.GBKToUTF8(tPanelCell.tbCell.szName))

        local tNPCInfo = SearchPanel.tInfo[1]
        local szGMCMD
        if nCurrentMapID == nSearchPanelMapID then
            szGMCMD = "player.SetPosition(" .. tNPCInfo.nX .. ", "
            .. tNPCInfo.nY .. ", " .. tNPCInfo.nZ .. ")"
        else
            szGMCMD = "player.SwitchMap(" .. nSearchPanelMapID .. ","
            .. tNPCInfo.nX .. ", " .. tNPCInfo.nY .. ", " .. tNPCInfo.nZ .. ")"
            OutputMessage("MSG_ANNOUNCE_NORMAL", "准备切换地图 【"..szMapName.."】请稍等\n")
        end
        SendGMCommand(szGMCMD)
        SearchPanel.ListNPC(szMapName)
        UIHelper.TableView_init(tPanelCell.tbPanel.NPCTableView, #SearchPanel.tInfo, PREFAB_ID.WidgetSearchPanel)
        UIHelper.TableView_reloadData(tPanelCell.tbPanel.NPCTableView)
        return
    end

    if SearchPanel.szInfoType ~= "NPC" then
        SearchPanel.SearchNPC(szMapName, UIHelper.GBKToUTF8(tPanelCell.tbCell.szName))
        UIHelper.TableView_init(tPanelCell.tbPanel.NPCTableView, #SearchPanel.tInfo, PREFAB_ID.WidgetSearchPanel)
        UIHelper.TableView_reloadData(tPanelCell.tbPanel.NPCTableView)
        -- 关于当前点击的转换
        SearchPanel.tLastCell = nil
    else
        if not SearchPanel.tLastCell then
            SearchPanel.tLastCell = tPanelCell
        else
            SearchPanel.tLastCell:UpdateInfo() --上一次的点击cell显示恢复, 并指向当前点击的cell
            SearchPanel.tLastCell = tPanelCell
        end

        local szNpcText = UIHelper.GBKToUTF8(tPanelCell.tbCell.szName) .. ",Index:" .. tPanelCell.tbCell.nIndex.. "(当前)"
        UIHelper.SetString(tPanelCell.LabelInfo, szNpcText)

        local szText = ""
        local szText2 = ""
        local player = GetClientPlayer()
        if not player then
            return
        end
        local nCurrentMapID = player.GetMapID()
        local nSearchPanelMapID
        for k, v in ipairs(SearchPanel.tMapList) do
            -- if v.Name == SearchPanel.szMapName and k == SearchPanel.dwShopID then
            --     nSearchPanelMapID = tonumber(v.ID)
            -- end
            if v.szText == szMapName  then
                nSearchPanelMapID = tonumber(v.nKey)
                break
            end
        end

        local tGMCMD = {}

        local tNPCInfo = tPanelCell.tbCell

        szText = szText .. "NPC名字： " .. UIHelper.GBKToUTF8(tNPCInfo.szName)
            .. "\nNPC别名： " .. tNPCInfo.szNickName
            .. "\nNPC模板ID： " .. tNPCInfo.nTempleteID
            .. "\nNPC坐标： " .. "(" .. tNPCInfo.nX .. ", " .. tNPCInfo.nY .. ", " .. tNPCInfo.nZ .. ")"
        UIHelper.SetString(tPanelCell.tbPanel.EditSearchInfo, szText)

        local szGMCMDSetNPCPosition = "player.SetPosition(" .. tNPCInfo.nX .. ", "
            .. tNPCInfo.nY .. ", " .. tNPCInfo.nZ .. ")"
        local szGMCMDSwitchNPCMap = "player.SwitchMap(" .. nSearchPanelMapID .. ","
            .. tNPCInfo.nX .. ", " .. tNPCInfo.nY .. ", " .. tNPCInfo.nZ .. ")"

        -- MapHelper.InitMiddleMapInfo(nSearchPanelMapID)
        -- local test  =  MapHelper.tbMiddleMapNpc[nSearchPanelMapID] or {}
        --MapMgr.SetTracePoint(self.szName, self.nMapID, self.tbInfo.tPoint[1])

        local szGMCMDMarkNPC = ''
        local markNPCCallback = function ()
            if not UIMgr.GetView(VIEW_ID.PanelMiddleMap) then
                UIMgr.Open(VIEW_ID.PanelMiddleMap, nSearchPanelMapID, 0)
            elseif MapMgr.nMapID ~= nSearchPanelMapID then
                UIMgr.Close(VIEW_ID.PanelMiddleMap)
                UIMgr.Open(VIEW_ID.PanelMiddleMap, nSearchPanelMapID, 0)
            end
            local tNpcPos = {tNPCInfo.nX , tNPCInfo.nY, tNPCInfo.nZ}
            MapMgr.SetTracePoint(UIHelper.GBKToUTF8(tNPCInfo.szName), nSearchPanelMapID, tNpcPos)
        end

        local szGMCMDMarkNPC_Clear = ''
        local clearMarkNPCCallback = function ()
            MapMgr.ClearTracePoint()
        end

        local szGMCMDCallNPC = "player.GetScene().CreateNpc(" .. tNPCInfo.nTempleteID .. ", player.nX+100, player.nY+100, player.nZ, 0, -1, '"..tNPCInfo.szNickName.."')"
        -- local szGMCMDMarkNPCMult = "SearchPanel.MarkNpcMult_Panel("..tNPCInfo.nTempleteID..")"  --临时测试用
        -- local szGMCMDMarkNPCMult_Del = "SearchPanel.MarkNpcMult_Del_Panel("..tNPCInfo.nTempleteID..")"  --临时测试用

        tGMCMD[#tGMCMD + 1] = {}
        tGMCMD[#tGMCMD].szText = '点我传送到NPC位置'
        if nCurrentMapID == nSearchPanelMapID then
            tGMCMD[#tGMCMD].szGMCMD = szGMCMDSetNPCPosition
        else
            tGMCMD[#tGMCMD].szGMCMD = szGMCMDSwitchNPCMap
        end

        tGMCMD[#tGMCMD + 1] = {}
        tGMCMD[#tGMCMD].szText = '点我在地图上标记NPC位置'
        tGMCMD[#tGMCMD].szGMCMD = szGMCMDMarkNPC
        tGMCMD[#tGMCMD].callback = markNPCCallback

        tGMCMD[#tGMCMD + 1] = {}
        tGMCMD[#tGMCMD].szText = '点我在中地图清除NPC标记'
        tGMCMD[#tGMCMD].szGMCMD = szGMCMDMarkNPC_Clear
        tGMCMD[#tGMCMD].callback = clearMarkNPCCallback

        tGMCMD[#tGMCMD + 1] = {}
        tGMCMD[#tGMCMD].szText = '点我CALL出该NPC'
        tGMCMD[#tGMCMD].szGMCMD = szGMCMDCallNPC

        -- tGMCMD[#tGMCMD + 1] = {}
        -- tGMCMD[#tGMCMD].szText = '点我在中地图标记所有指定NPC'
        -- tGMCMD[#tGMCMD].szGMCMD = szGMCMDMarkNPCMult --临时测试用

        -- tGMCMD[#tGMCMD + 1] = {}
        -- tGMCMD[#tGMCMD].szText = '点我一键删除指定类型NPC标记'
        -- tGMCMD[#tGMCMD].szGMCMD = szGMCMDMarkNPCMult_Del --临时测试用

        SearchPanel.tGMCMD = tGMCMD
        -- szText2 = szText2 .. "NPC名字： " .. tNPCInfo.szName
        --     .. "\nNPC别名： " .. tNPCInfo.szNickName
        --     .. "\nNPC模板ID： " .. tNPCInfo.nTempleteID
        --     .. "\nNPC坐标： " .. "(" .. tNPCInfo.nX .. ", " .. tNPCInfo.nY .. ", " .. tNPCInfo.nZ .. ")"
        --     .. "\n/gm player.SwitchMap(" .. nSearchPanelMapID .. "," .. tNPCInfo.nX .. ", " .. tNPCInfo.nY .. ", " .. tNPCInfo.nZ .. ")"
        --     .. "\n/gm player.AddMapMark(" .. tNPCInfo.nX .. ", " .. tNPCInfo.nY .. ", "
        --         .. tNPCInfo.nZ .. ", 1, \"" .. tNPCInfo.szName .. "\")"
        UIHelper.TableView_init(tPanelCell.tbPanel.TableViewCMD, #SearchPanel.tGMCMD, PREFAB_ID.WidgetSearchPanel)
        UIHelper.TableView_reloadData(tPanelCell.tbPanel.TableViewCMD)
    end
end

function SearchPanel.SearchNPC(szMapName, szSearchValue)
    SearchPanel.tInfo = {}
    SearchPanel.szInfoType = "NPC"
    SearchPanel.tInfo = SearchPanel.GetNPCInfo(szMapName, szSearchValue)
end

function SearchPanel.GetNPCInfo(szMapName, szSearchValue)
    if Platform.IsWindows()then
        szDataFile =  UIHelper.UTF8ToGBK("data\\source\\maps\\" ..szMapName .."\\" ..szMapName ..".Map.Logical")
    else
        szDataFile =  "data\\source\\maps\\" ..UIHelper.UTF8ToGBK(szMapName) .."\\" ..UIHelper.UTF8ToGBK(szMapName) ..".Map.Logical"
    end
    local tInfo = {}
    local tData = Lib.IniFile:LoadFile(szDataFile)

    if not tData then
        --SearchPanel.fnInfoMSG("对应的逻辑文件不存在" .. szDataFile)
        OutputMessage("MSG_ANNOUNCE_NORMAL", "对应的逻辑文件不存在".. UIHelper.GBKToUTF8(szDataFile))
        LOG.ERROR("对应的逻辑文件不存在" .. UIHelper.GBKToUTF8(szDataFile))
        return
    end

    local num = tData:GetValue("MAIN", "NumNPC")
    local nNPCID = tonumber(szSearchValue)

    if nNPCID then
        local nNpcCount = 0
        for section, _ in pairs(tData.tbData) do
            if string.find(section, 'NPC') and not string.find(section, 'NpcReviveSection') then
                nNpcCount = nNpcCount + 1
                if tData:GetValue(section, "nTempleteID")== szSearchValue then
                    tInfo[#tInfo + 1] = tData:GetSection(section)
                    tInfo[#tInfo].nIndex = nNpcCount
                end
            end
            if nNpcCount == num then
                break
            end
        end
    else
        local nNpcCount = 0
        for section, _ in pairs(tData.tbData) do
            if string.find(section, 'NPC') then
                nNpcCount = nNpcCount + 1
                local szName = UIHelper.GBKToUTF8(tData:GetValue(section, "szName"))
                if szName and string.find(szName, szSearchValue) then
                    tInfo[#tInfo + 1] = tData:GetSection(section)
                    tInfo[#tInfo].nIndex = nNpcCount
                end
            end
            if nNpcCount == num then
                break
            end
        end
    end
    return tInfo
end

function SearchPanel.GetAllNPCInfo(szMapName)
    local szDataFile
    if Platform.IsWindows()then
        szDataFile =  UIHelper.UTF8ToGBK("data\\source\\maps\\" ..szMapName .."\\" ..szMapName ..".Map.Logical")
    else
        szDataFile =  "data\\source\\maps\\" ..UIHelper.UTF8ToGBK(szMapName) .."\\" ..UIHelper.UTF8ToGBK(szMapName) ..".Map.Logical"
    end
    local tInfo = {}
    local tData = Lib.IniFile:LoadFile(szDataFile)

    if not tData then
        OutputMessage("MSG_ANNOUNCE_NORMAL", "对应的逻辑文件不存在".. UIHelper.GBKToUTF8(szDataFile))
        LOG.ERROR("对应的逻辑文件不存在" .. UIHelper.GBKToUTF8(szDataFile))
        return
    end

    local num = tData:GetValue("MAIN", "NumNPC")
    local nNpcCount = 0
    for section, _ in pairs(tData.tbData) do
        if string.find(section, 'NPC') and not string.find(section, 'NpcReviveSection') then
            nNpcCount = nNpcCount + 1
            local tNpcInfo  = tData:GetSection(section)
            if tNpcInfo then
                tInfo[#tInfo + 1] = tNpcInfo
                tInfo[#tInfo].nIndex = nNpcCount
            end
        end
        if nNpcCount == num then
            break
        end
    end
    return tInfo
end

function SearchPanel.ListNPC(szMapName)
    if SearchPanel.tNPCList[szMapName] then
        SearchPanel.szMapName = szMapName
        SearchPanel.szInfoType = "NPCList"
        SearchPanel.tInfo = SearchPanel.tNPCList[szMapName]
        return
    end
    local szDataFile
    if Platform.IsWindows()then
        szDataFile =  UIHelper.UTF8ToGBK("data\\source\\maps\\" ..szMapName .."\\" ..szMapName ..".Map.Logical")
    else
        szDataFile =  "data\\source\\maps\\" ..UIHelper.UTF8ToGBK(szMapName) .."\\" ..UIHelper.UTF8ToGBK(szMapName) ..".Map.Logical"
    end
    SearchPanel.tInfo = {}
    SearchPanel.szInfoType = "NPCList"
    local tData = Lib.IniFile:LoadFile(szDataFile)
    if not tData then
        OutputMessage("MSG_ANNOUNCE_NORMAL", "对应的逻辑文件不存在".. UIHelper.GBKToUTF8(szDataFile))
        LOG.ERROR("对应的逻辑文件不存在" .. UIHelper.GBKToUTF8(szDataFile))
        return
    end
    SearchPanel.szMapName = szMapName
    -- MAIN", "NumNPC 是包含同名npc的数量, 但是再逻辑地图表中id并不是连续的
    local num = tData:GetValue("MAIN", "NumNPC")
    local nNpcCount = 0
    for section, v in pairs(tData.tbData) do
        if string.find(section, 'NPC') and not string.find(section, 'NpcReviveSection') then
            nNpcCount = nNpcCount + 1
            if v.szName == "" then
                v.szName = v.nTempleteID
            end
            local nInfoKey = SearchPanel.IsNPCOrDoodadInList(v.szName)
            if nInfoKey then
                SearchPanel.tInfo[nInfoKey].nCount = SearchPanel.tInfo[nInfoKey].nCount + 1
            else
                SearchPanel.tInfo[#SearchPanel.tInfo + 1] = {}
                SearchPanel.tInfo[#SearchPanel.tInfo].szName = v.szName
                SearchPanel.tInfo[#SearchPanel.tInfo].nCount = 1
                if v.nX == "" then
                    SearchPanel.tInfo[#SearchPanel.tInfo].Source = "(脚本)"
                else
                    SearchPanel.tInfo[#SearchPanel.tInfo].Source = ""
                end
            end
        end
        if nNpcCount == num then
            break
        end
    end
    SearchPanel.tNPCList[szMapName] = SearchPanel.tInfo
end

function SearchPanel.IsNPCOrDoodadInList(szName)
    for k, v in ipairs(SearchPanel.tInfo) do
        if v.szName == szName then
            return k
        end
    end
end
