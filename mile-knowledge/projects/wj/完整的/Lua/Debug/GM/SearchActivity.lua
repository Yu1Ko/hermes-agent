--活动状态 0是关闭，1是延迟关闭，2是正常开，3是延迟开

if not SearchActivity then
    SearchActivity = {
        className = "SearchActivity",
        text = "【活动】",
        szPlaceHolder = "输入活动ID或名称",
        nViewID = VIEW_ID.PanelGMRightView,
        tActivity = {},
        tTabBase = {}, --这里修改
    }
    end

local tBaseHead
if not _G.bClassic then
    tBaseHead = {
        Path = "\\settings\\Activity.tab",--PAK需要拷贝的表
        Title =
        {
            {f = "i", t = "ID"},
            {f = "s", t = "Activity"},
            {f = "i", t = "ParentID1"},
            {f = "i", t = "ParentID2"},
            {f = "i", t = "ParentID3"},
            {f = "i", t = "ParentID4"},
            {f = "i", t = "ParentID5"},
            {f = "s", t = "StartTimeRule"},
            {f = "i", t = "Cycle"},
            {f = "i", t = "Duration"},
            {f = "i", t = "ShowUI"},
            {f = "s", t = "ServerScript"},
            {f = "s", t = "CenterScript"},
            {f = "i", t = "IsSyncState"},
        }
    }
else
    tBaseHead = {
        Path = "\\settings\\Activity.tab",--PAK需要拷贝的表
        Title =
        {
            {f = "i", t = "ID"},
            {f = "s", t = "Activity"},
            {f = "i", t = "ParentID1"},
            {f = "i", t = "ParentID2"},
            {f = "i", t = "ParentID3"},
            {f = "i", t = "ParentID4"},
            {f = "i", t = "ParentID5"},
            {f = "s", t = "StartTimeRule"},
            {f = "i", t = "Cycle"},
            {f = "i", t = "Duration"},
            {f = "i", t = "ShowUI"},
            {f = "s", t = "ServerScript"},
            {f = "s", t = "CenterScript"},
        }
    }
end

function SearchActivity.LoadTable(tBaseHead)
    SearchActivity.tTabBase = KG_Table.Load(tBaseHead.Path, tBaseHead.Title, TABLE_FILE_OPEN_MODE.NORMAL)
end


function SearchActivity:FillAll()
    SearchActivity.LoadTable(tBaseHead)
    local nCount = SearchActivity.tTabBase:GetRowCount()
    for i = 1, nCount do
        local tActivity = SearchActivity.tTabBase:GetRow(i)
        local szItemName = '['..tActivity.ID..'] '..tActivity.Activity
        local tTemp = {ID = tActivity.ID, Name = szItemName,
                        tBtnStatus = {
                                        BtnOperate = false, BtnOperate1 = true, BtnOperate2 = true,
                                        BtnOperate4 = true
                                    },
                        tBtnLabel = {
                                        LabelOperate1 = '查看状态', LabelOperate2 = '开启',
                                        LabelOperate4 = '关闭'
                                    }
                        }
        table.insert(SearchActivity.tActivity, tTemp)
    end
end

function SearchActivity:ShowSubWindow(tbGMView)
    tbGMView.PanelRightView:setVisible(true)
    tbGMView.LabelExtension:setVisible(true)
    tbGMView.EditSearchRight:setPlaceHolder(SearchActivity.szPlaceHolder)
    if tbGMView.tbLastData~=nil and next(tbGMView.tbLastData) then
        UIHelper.SetString(tbGMView.EditSearchRight, tbGMView.tbLastData.EditLabelRight)
    else
        UIHelper.SetString(tbGMView.EditSearchRight, "")
    end
    UIHelper.SetString(tbGMView.LabelExtension, SearchActivity.text)
end

function SearchActivity:OnClick(tbGMView)
    if not next(SearchActivity.tActivity) then
        OutputMessage("MSG_SYS", "第一次加载需要一点时间, 请稍等...\n")
        Timer.AddFrame(SearchActivity, 15, function()
            SearchActivity.FillAll()
            UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
            UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
        end);
    end
    SearchActivity:ShowSubWindow(tbGMView)
    UIHelper.SetString(tbGMView.EditSearchRight, "")
    tbGMView.tbGMPanelRight = SearchActivity
    tbGMView.tbRawDataRight = SearchActivity.tActivity
    tbGMView.tbSearchResultRight = SearchActivity.tActivity
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end

function SearchActivity:BtnOperate1(tbData)
    if not _G.bClassic then
        local szMsg = UIHelper.UTF8ToGBK('活动')..tbData.Name..","..UIHelper.UTF8ToGBK('当前状态：')
        SendGMCommand("player.SendSystemMessage('"..szMsg.."'..GetActivityState("..tbData.ID.."))")
        OutputMessage("MSG_ANNOUNCE_NORMAL", "活动状态已输出到聊天系统频道\n")
    else
        local szMsg = UIHelper.UTF8ToGBK('活动')..tbData.Name..","..UIHelper.UTF8ToGBK('当前状态：')
        SendGMCommand("player.SendSystemMessage('"..szMsg.."'..GetActivityMgrServer().GetActivityState("..tbData.ID..").nState)")
        OutputMessage("MSG_ANNOUNCE_NORMAL", "活动状态已输出到聊天系统频道\n")
    end
end


function SearchActivity:BtnOperate2(tbData)
    if not _G.bClassic then
        SendGMCommand("GCCommand('ForceStartActivity("..tbData.ID..")')")
    else
        SendGMCommand("RemoteCallToCenter('OnForceStartActivity', "..tbData.ID..")")
    end
    local szActivityName = UIHelper.GBKToUTF8(tbData.Name)
    OutputMessage("MSG_ANNOUNCE_NORMAL", "已执行开启活动【" .. szActivityName .. "】\n")
    OutputMessage("MSG_SYS", "已执行开启活动【" .. szActivityName .. "】\n")
end

function SearchActivity:BtnOperate4(tbData)
    if not _G.bClassic then
        SendGMCommand("GCCommand('ForceEndActivity("..tbData.ID..")')")
    else
        SendGMCommand("RemoteCallToCenter('OnForceEndActivity', "..tbData.ID..")")
    end
    local szActivityName = UIHelper.GBKToUTF8(tbData.Name)
    OutputMessage("MSG_ANNOUNCE_NORMAL", "已执行关闭活动【" .. szActivityName .. "】\n")
    OutputMessage("MSG_SYS", "已执行关闭活动【" .. szActivityName .. "】\n")
end

function SearchActivity:GetAllData(tbGMView)
    tbGMView.tbSearchResultRight = SearchActivity.tActivity
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbSearchResultRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end