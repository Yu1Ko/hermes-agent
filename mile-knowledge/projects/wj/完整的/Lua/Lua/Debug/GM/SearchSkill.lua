if not SearchSkill then
    SearchSkill = {
        className = "SearchSkill",
        text = '技能学习',
        szPlaceHolder = '输入技能ID或名称',
        nViewID = VIEW_ID.PanelGMRightView,
        tSkill = {},
        tTabBase = {},
    }
end

function SearchSkill:FillAll()
    local tbSkill = GMMgr.ReadTabFile("settings/skill_mobile/skills.tab")
    for _, v in ipairs(tbSkill) do
        local szSkillName = '['..v.SkillID..']'..v.SkillName
        local tTemp = { ID = v.SkillID, Name = szSkillName,
                        tBtnStatus = {
                                        BtnOperate = false, BtnOperate2 = true,
                                        BtnOperate4 = true
                                    },
                        tBtnLabel = {
                                        LabelOperate2 = '学习', LabelOperate4 = '遗忘'
                                    }
                        }
        table.insert(SearchSkill.tSkill, tTemp)
    end
end

function SearchSkill:ShowSubWindow(tbGMView)
    tbGMView.PanelRightView:setVisible(true)
    tbGMView.LabelExtension:setVisible(true)
    tbGMView.EditSearchRight:setPlaceHolder(SearchSkill.szPlaceHolder)
    if tbGMView.tbLastData~=nil and next(tbGMView.tbLastData) then
        UIHelper.SetString(tbGMView.EditSearchRight, tbGMView.tbLastData.EditLabelRight)
    else
        UIHelper.SetString(tbGMView.EditSearchRight, "")
    end
    UIHelper.SetString(tbGMView.LabelExtension, SearchSkill.text)
end

function SearchSkill:OnClick(tbGMView)
    if not next(SearchSkill.tSkill) then
        OutputMessage("MSG_SYS", "第一次加载需要一点时间, 请稍等...\n")
        Timer.AddFrame(SearchSkill, 15, function()
            SearchSkill.FillAll()
            UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
            UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
        end);
    end
    SearchSkill:ShowSubWindow(tbGMView)
    UIHelper.SetString(tbGMView.EditSearchRight, "")
    tbGMView.tbGMPanelRight = SearchSkill
    tbGMView.tbRawDataRight = SearchSkill.tSkill
    tbGMView.tbSearchResultRight = SearchSkill.tSkill
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end

function SearchSkill:BtnOperate2(tbData)
    SendGMCommand("player.LearnSkill(".. tbData.ID ..")")
    local szSkillName = UIHelper.GBKToUTF8(tbData.Name)
    OutputMessage("MSG_ANNOUNCE_NORMAL", "学习技能【" .. szSkillName .. "】\n")
    OutputMessage("MSG_SYS", "学习技能【" .. szSkillName .. "】\n")
end

function SearchSkill:BtnOperate4(tbData)
    SendGMCommand("player.ForgetSkill(".. tbData.ID ..")")
    local szSkillName = UIHelper.GBKToUTF8(tbData.Name)
    OutputMessage("MSG_ANNOUNCE_NORMAL", "遗忘技能【" .. szSkillName .. "】\n")
    OutputMessage("MSG_SYS", "遗忘技能【" .. szSkillName .. "】\n")
end

function SearchSkill:GetAllData(tbGMView)
    tbGMView.tbSearchResultRight = SearchSkill.tSkill
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbSearchResultRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end