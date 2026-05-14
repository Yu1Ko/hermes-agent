if not SearchQuest then
    SearchQuest = {
        className = "SearchQuest",
        text = '任务查询',
        szPlaceHolder = '输入任务ID或名称',
        nViewID = VIEW_ID.PanelGMRightView,
        tQuest = {},
        tTabBase = {},
    }
end

function SearchQuest:FillAll()
    local tbQuests = g_tTable.Quests
    local nRow = tbQuests:GetRowCount()
    for i = 2, nRow  do
        local tQuestStringInfo = tbQuests:GetRow(i)
        if tQuestStringInfo then
            if tQuestStringInfo.szObjective ~= "" and tQuestStringInfo.szMobileObjective ~= "" then
                tQuestStringInfo.szObjective = tQuestStringInfo.szMobileObjective
            end
            local szQuestName = '['..tQuestStringInfo.nID..']'..tQuestStringInfo.szName
            local tTemp = { ID = tQuestStringInfo.nID, Name = szQuestName, Object = tQuestStringInfo.szObjective,
                            tBtnStatus = {
                                            BtnOperate = false, BtnOperate1 = true, BtnOperate2 = true,
                                            BtnOperate3 = true, BtnOperate4 =true
                                        },
                            tBtnLabel = {
                                            LabelOperate1 = '接受', LabelOperate2 = '完成',
                                            LabelOperate3 = '详情', LabelOperate4 = '重置'
                                        }
                            }
            local tbQuestInfo = GetQuestInfo(tonumber(tQuestStringInfo.nID))
            if tbQuestInfo == nil then
                tTemp.StartNpcTemplateID = 0
                tTemp.EndNpcTemplateID = 0
            else
                tTemp.StartNpcTemplateID = tbQuestInfo.dwStartNpcTemplateID
                tTemp.EndNpcTemplateID = tbQuestInfo.dwEndNpcTemplateID
            end
            table.insert(SearchQuest.tQuest, tTemp)
        end
    end
end

function SearchQuest:ShowSubWindow(tbGMView)
    tbGMView.PanelRightView:setVisible(true)
    tbGMView.LabelExtension:setVisible(true)
    tbGMView.EditSearchRight:setPlaceHolder(SearchQuest.szPlaceHolder)
    if tbGMView.tbLastData~=nil and next(tbGMView.tbLastData) then
        UIHelper.SetString(tbGMView.EditSearchRight, tbGMView.tbLastData.EditLabelRight)
    else
        UIHelper.SetString(tbGMView.EditSearchRight, "")
    end
    UIHelper.SetString(tbGMView.LabelExtension, SearchQuest.text)
end


function SearchQuest:OnClick(tbGMView)
    if not next(SearchQuest.tQuest) then
        OutputMessage("MSG_SYS", "第一次加载需要一点时间, 请稍等...\n")
        Timer.AddFrame(SearchQuest, 15, function()
            SearchQuest.FillAll()
            UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
            UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
        end);
    end
    SearchQuest:ShowSubWindow(tbGMView)
    UIHelper.SetString(tbGMView.EditSearchRight, "")
    tbGMView.tbGMPanelRight = SearchQuest
    tbGMView.tbRawDataRight = SearchQuest.tQuest
    tbGMView.tbSearchResultRight = SearchQuest.tQuest
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end

function SearchQuest:BtnOperate1(tbData)
    SendGMCommand("player.AcceptQuest(1,1,".. tbData.ID ..",1)")
    local szTaskName = UIHelper.GBKToUTF8(tbData.Name)
    OutputMessage("MSG_ANNOUNCE_NORMAL", "接受任务【" ..szTaskName.. "】\n")
    OutputMessage("MSG_SYS", "接受任务【" ..szTaskName.. "】\n")
end

function SearchQuest:BtnOperate2(tbData)
    SendGMCommand("player.ForceFinishQuest(".. tbData.ID ..")")
    local szTaskName = UIHelper.GBKToUTF8(tbData.Name)
    OutputMessage("MSG_ANNOUNCE_NORMAL", "完成任务【" ..szTaskName.. "】\n")
    OutputMessage("MSG_SYS", "完成任务【"..szTaskName.."】\n")
end

function SearchQuest:BtnOperate3(tbData)
    UIMgr.Open(VIEW_ID.PanelTaskInformation, tbData)
end

function SearchQuest:BtnOperate4(tbData)
    SendGMCommand("player.ClearQuest(".. tbData.ID ..")")
    local szTaskName = UIHelper.GBKToUTF8(tbData.Name)
    OutputMessage("MSG_ANNOUNCE_NORMAL", "重置任务【" ..szTaskName.. "】\n")
    OutputMessage("MSG_SYS", "重置任务【"..szTaskName.."】\n")
end

function SearchQuest:GetAllData(tbGMView)
    tbGMView.tbSearchResultRight = SearchQuest.tQuest
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbSearchResultRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end