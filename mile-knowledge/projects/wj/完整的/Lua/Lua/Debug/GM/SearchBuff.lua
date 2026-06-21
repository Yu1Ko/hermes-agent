if not SearchBuff then
    SearchBuff = {
        className = "SearchBuff",
        text = 'Buff查询',
        szPlaceHolder = '输入Buff ID或名称',
        nViewID = VIEW_ID.PanelGMRightView,
        tbLastGMView = {},
        ClickFunc,
        tBuff = {},
        -- tTabBase = {},
        tbLastClick = {ID = '', Level = '1,3600', StackNum = 1, BtnName = ''},
        bInit = false,
    }
end

function SearchBuff:FillAll()
    local index_temp_Buff = {"ID","Name","Level"}
    local tDXBuff = GMMgr.LoadFile("","settings\\skill\\Buff.tab",index_temp_Buff) --BUFF没有默认行！
    local tVKBuff = GMMgr.LoadFile("","settings\\skill_mobile\\Buff.tab",index_temp_Buff) --BUFF没有默认行！
    -- DX buff表插入
    local nRow = GMMgr.GetRowCount(tDXBuff)
    for i = 2, nRow  do
        local tBufftringInfo = GMMgr.GetRow(tDXBuff, i)
        if tBufftringInfo then
            local szBuffName = string.format("[%s](%s)%s", tBufftringInfo.ID, tBufftringInfo.Level, tBufftringInfo.Name)
            local tTemp = { ID = tonumber(tBufftringInfo.ID), Name = szBuffName,  Level = tBufftringInfo.Level,
                            tBtnStatus = {
                                            BtnOperate = false, BtnOperate1 = true, BtnOperate2 = true,
                                            BtnOperate3 = true, BtnOperate4 =true
                                        },
                            tBtnLabel = {
                                            LabelOperate1 = '自身删除', LabelOperate2 = '自身添加',
                                            LabelOperate3 = '目标删除', LabelOperate4 = '目标添加'
                                        }
                            }
            table.insert(SearchBuff.tBuff, tTemp)
        end
    end

    -- VK buff表插入
    nRow = GMMgr.GetRowCount(tVKBuff)
    for i = 2, nRow  do
        local tBufftringInfo = GMMgr.GetRow(tVKBuff, i)
        if tBufftringInfo then
            -- local szBuffName = '['..tBufftringInfo.ID..']'..tBufftringInfo.Name
            local tTemp = { ID = tonumber(tBufftringInfo.ID), Name = tBufftringInfo.Name,  Level = tBufftringInfo.Level,
                            tBtnStatus = {
                                            BtnOperate = false, BtnOperate1 = true, BtnOperate2 = true,
                                            BtnOperate3 = true, BtnOperate4 =true
                                        },
                            tBtnLabel = {
                                            LabelOperate1 = '自身删除', LabelOperate2 = '自身添加',
                                            LabelOperate3 = '目标删除', LabelOperate4 = '目标添加'
                                        }
                            }
            table.insert(SearchBuff.tBuff, tTemp)
        end
    end

end

function SearchBuff:ShowSubWindow(tbGMView)
    if not SearchBuff.bInit then
        tbGMView.LabelExtension:setVisible(true)
        tbGMView.WidgetBuffInfo:setVisible(true)
        tbGMView.BtnExecute:setVisible(true)
        UIHelper.SetString(tbGMView.LabelExtension, SearchBuff.tbLastClick.ID)
        UIHelper.SetString(tbGMView.EditLevel, SearchBuff.tbLastClick.Level)
        UIHelper.SetString(tbGMView.EditStackNum, SearchBuff.tbLastClick.StackNum)
        UIHelper.SetString(tbGMView.LabelExecute, SearchBuff.tbLastClick.BtnName)
    end
    tbGMView.PanelRightView:setVisible(true)
    tbGMView.EditSearchRight:setPlaceHolder(SearchBuff.szPlaceHolder)
    if tbGMView.tbLastData~=nil and next(tbGMView.tbLastData) then
        UIHelper.SetString(tbGMView.EditSearchRight, tbGMView.tbLastData.EditLabelRight)
    else
        UIHelper.SetString(tbGMView.EditSearchRight, "")
    end
    SearchBuff.bInit  = false
    SearchBuff.tbLastGMView = tbGMView
end

function SearchBuff:OnClick(tbGMView)
    SearchBuff.bInit = true
    if not next(SearchBuff.tBuff) then
        OutputMessage("MSG_SYS", "第一次加载需要一点时间, 请稍等...\n")
        Timer.AddFrame(SearchBuff, 15, function()
            SearchBuff.FillAll()
            UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
            UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
        end);
    end
    SearchBuff:ShowSubWindow(tbGMView)
    UIHelper.SetString(tbGMView.EditSearchRight, "")
    tbGMView.tbGMPanelRight = SearchBuff
    tbGMView.tbRawDataRight = SearchBuff.tBuff
    tbGMView.tbSearchResultRight = SearchBuff.tBuff
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end

function SearchBuff:BtnExecute(tbGMView)
    SearchBuff.tbLastGMView = tbGMView
    if not SearchBuff.ClickFunc then
        return
    end
    local nLevel = UIHelper.GetString(tbGMView.EditLevel)
    local StackNum = UIHelper.GetString(tbGMView.EditStackNum)
    SearchBuff.tbLastClick.Level = nLevel
    SearchBuff.tbLastClick.StackNum = StackNum
    SearchBuff.ClickFunc(nLevel, StackNum)
end

function SearchBuff:BtnOperate1(tbData)
    SearchBuff.tbLastGMView.LabelExtension:setVisible(true)
    UIHelper.SetString(SearchBuff.tbLastGMView.LabelExtension, "ID:"..tbData.ID)
    UIHelper.SetString(SearchBuff.tbLastGMView.EditLevel, 1)
    SearchBuff.tbLastGMView.BtnExecute:setVisible(true)
    SearchBuff.tbLastGMView.WidgetBuffInfo:setVisible(true)
    UIHelper.SetString(SearchBuff.tbLastGMView.LabelExecute, "执行自身删除")
    SearchBuff.tbLastClick.ID = "ID:"..tbData.ID
    SearchBuff.tbLastClick.BtnName = "执行自身删除"
    SearchBuff.ClickFunc = function(nLevel, StackNum)
        local szMsg = "删除自身Buff ID:"..tbData.ID..' '..UIHelper.GBKToUTF8(tbData.Name) .."等级: Lv."..nLevel.."\n"
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        SendGMCommand("for i=1,"..StackNum.." do player.DelBuff("..tbData.ID..','..nLevel..") end")
    end

end

function SearchBuff:BtnOperate2(tbData)
    SearchBuff.tbLastGMView.LabelExtension:setVisible(true)
    UIHelper.SetString(SearchBuff.tbLastGMView.LabelExtension, "ID:"..tbData.ID)
    UIHelper.SetString(SearchBuff.tbLastGMView.EditLevel, '1,3600')
    UIHelper.SetString(SearchBuff.tbLastGMView.EditStackNum, 1)
    SearchBuff.tbLastGMView.BtnExecute:setVisible(true)
    SearchBuff.tbLastGMView.WidgetBuffInfo:setVisible(true)
    UIHelper.SetString(SearchBuff.tbLastGMView.LabelExecute, "执行自身添加")
    SearchBuff.tbLastClick.ID = "ID:"..tbData.ID
    SearchBuff.tbLastClick.BtnName = "执行自身添加"
    SearchBuff.ClickFunc = function(nLevel, StackNum)
        local szMsg = "添加自身Buff ID:"..tbData.ID..' '..UIHelper.GBKToUTF8(tbData.Name) .."  等级, 跳数: Lv."..nLevel.."\n"
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        SendGMCommand("for i=1,"..StackNum.." do player.AddBuff(player.dwID,player.nLevel,"..tbData.ID..','..nLevel..") end")
    end
end

function SearchBuff:BtnOperate3(tbData)
    SearchBuff.tbLastGMView.LabelExtension:setVisible(true)
    UIHelper.SetString(SearchBuff.tbLastGMView.LabelExtension, "ID:"..tbData.ID)
    UIHelper.SetString(SearchBuff.tbLastGMView.EditLevel, 1)
    SearchBuff.tbLastGMView.BtnExecute:setVisible(true)
    SearchBuff.tbLastGMView.WidgetBuffInfo:setVisible(true)
    UIHelper.SetString(SearchBuff.tbLastGMView.LabelExecute, "执行目标删除")
    SearchBuff.tbLastClick.ID = "ID:"..tbData.ID
    SearchBuff.tbLastClick.BtnName = "执行目标删除"
    SearchBuff.ClickFunc = function(nLevel, StackNum)
        local szMsg = "删除目标Buff ID:"..tbData.ID..' '..UIHelper.GBKToUTF8(tbData.Name) .."  等级: Lv."..nLevel.."\n"
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        SendGMCommand("for i=1,"..StackNum.." do player.GetSelectCharacter().DelBuff("..tbData.ID..','..nLevel..") end")
    end
end

function SearchBuff:BtnOperate4(tbData)
    SearchBuff.tbLastGMView.LabelExtension:setVisible(true)
    UIHelper.SetString(SearchBuff.tbLastGMView.LabelExtension, "ID:"..tbData.ID)
    UIHelper.SetString(SearchBuff.tbLastGMView.EditLevel, '1,3600')
    UIHelper.SetString(SearchBuff.tbLastGMView.EditStackNum, 1)
    SearchBuff.tbLastGMView.BtnExecute:setVisible(true)
    SearchBuff.tbLastGMView.WidgetBuffInfo:setVisible(true)
    UIHelper.SetString(SearchBuff.tbLastGMView.LabelExecute, "执行目标添加")
    SearchBuff.tbLastClick.ID = "ID:"..tbData.ID
    SearchBuff.tbLastClick.BtnName = "执行目标添加"
    SearchBuff.ClickFunc = function(nLevel, StackNum)
        local szMsg = "添加目标Buff ID:"..tbData.ID..' '..UIHelper.GBKToUTF8(tbData.Name) .."  等级, 跳数: Lv."..nLevel.."\n"
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        SendGMCommand("for i=1,"..StackNum.." do player.GetSelectCharacter().AddBuff(player.dwID,player.nLevel,"..tbData.ID..','..nLevel..") end")
    end
end

function SearchBuff:GetAllData(tbGMView)
    tbGMView.tbSearchResultRight = SearchBuff.tBuff
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbSearchResultRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end