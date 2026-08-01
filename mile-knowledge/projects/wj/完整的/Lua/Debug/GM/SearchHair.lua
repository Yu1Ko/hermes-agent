if not SearchHair then
    SearchHair = {
        text = "发型查询",
        szPlaceHolder = "输入发型HeadID或名称",
        nViewID = VIEW_ID.PanelGMRightView,
        lastStartSearchTime = 0,
        lastResultsInfo = '',
        bLastPartMode = false,
        bLastFileMode = false,
        --bLastHD = true,
        isCallBack = 1,
        bInit = false,
        tHair = {},
        tPartFile = {}, --用于存储已加载的部件表现表；
    }
end

local tPartFileNameMap = { --根据输入的关键词快速定位到具体哪个表现表
	["plait"] = { --辫子
		[1] = "Hair_m2.txt", --M2，标男
		[2] = "Hair_f2.txt", --F2，标女
		[3] = "Hair_m3.txt", --M3，魁梧男
		[4] = "Hair_f3.txt", --F3，性感女
		[5] = "Hair_m1.txt", --M1，小男孩
		[6] = "Hair_f1.txt", --F1，小女孩
	},

	["bang"] = { --刘海
		[1] = "Hair_m2.txt", --M2，标男
		[2] = "Hair_f2.txt", --F2，标女
		[3] = "Hair_m3.txt", --M3，魁梧男
		[4] = "Hair_f3.txt", --F3，性感女
		[5] = "Hair_m1.txt", --M1，小男孩
		[6] = "Hair_f1.txt", --F1，小女孩
	},

	["head"] = { --头发
		[1] = "Hair_m2.txt", --M2，标男
		[2] = "Hair_f2.txt", --F2，标女
		[3] = "Hair_m3.txt", --M3，魁梧男
		[4] = "Hair_f3.txt", --F3，性感女
		[5] = "Hair_m1.txt", --M1，小男孩
		[6] = "Hair_f1.txt", --F1，小女孩
	},
}

local tBodyTypeMap = {  --根据玩家体型快速生成目录路径
	[1]  = "M2",
	[2]  = "F2",
	[3]  = "M3",
	[4]  = "F3",
	[5]  = "M1",
	[6]  = "F1",
}

local tBeHeadPartIndex = {
	["plait"]="PlaitID",
	["bang"]="BangID",
	["head"]="HeadformID",
}

-- function SearchHair:FillAll()
--     local tbHair = g_tTable.Hair
--     local nRow = tbHair:GetRowCount()
--     for i = 2, nRow do
--         local tHairStringInfo = tbHair:GetRow(i)
--         if tHairStringInfo then
--             local szHairName = '['..tHairStringInfo.nSet..'] '..tHairStringInfo.szSetName
--             local tTemp = {ID = tHairStringInfo.nSet, Name = szHairName, ButtonLabel = '获取',
--                             tBtnStatus = {
--                                     BtnOperate = true, BtnOperate1 = false, BtnOperate2 = false,
--                                     BtnOperate3 = false, BtnOperate4 = false
--                                         }
--                             }
--             table.insert(SearchHair.tHair, tTemp)
--         end
--     end
-- end

function SearchHair:ShowSubWindow(tbGMView)
    tbGMView.PanelRightView:setVisible(true)
    tbGMView.BtnExecute:setVisible(true)
    UIHelper.SetString(tbGMView.LabelExecute, "应用")
    tbGMView.WidgetExterior:setVisible(true)
    tbGMView.TogFileMode:setVisible(true)
	tbGMView.WidgetSwitch:setVisible(true)
    tbGMView.EditSearchRight:setPlaceHolder(SearchHair.szPlaceHolder)
    if tbGMView.tbLastData~=nil and next(tbGMView.tbLastData) then
        UIHelper.SetString(tbGMView.EditSearchRight, tbGMView.tbLastData.EditLabelRight)
    else
        UIHelper.SetString(tbGMView.EditSearchRight, "")
    end
    UIHelper.SetString(tbGMView.LabelTitle, SearchHair.text)
    -- 设置勾选状态
    UIHelper.SetSelected(tbGMView.TogPartMode, SearchHair.bLastPartMode)
    UIHelper.SetString(tbGMView.LabelPartMode, '部件模式')
    UIHelper.SetSelected(tbGMView.TogFileMode, SearchHair.bLastFileMode)
    UIHelper.SetString(tbGMView.LabelFileMode, '文件模式')
    UIHelper.SetString(tbGMView.LabelExteriorDescript, SearchHair.lastResultsInfo)
end

function SearchHair:OnClick(tbGMView)
    if not SearchHair.bInit then
        -- SearchHair:FillAll()
        SearchHair.InitTools()
    end
    SearchHair:ShowSubWindow(tbGMView)
    UIHelper.SetString(tbGMView.EditSearchRight, "")
    tbGMView.tbGMPanelRight = SearchHair
    tbGMView.tbRawDataRight = SearchHair.tHair
    tbGMView.tbSearchResultRight = SearchHair.tHair
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end


-- function SearchHair:BtnOperate(tbData)
--     SearchHair.Apply(tbData.ID)
-- end

function SearchHair:BtnExecute(tbGMView)
    local szSerchInfo = UIHelper.GetString(tbGMView.EditSearchRight)
    local bPartCheckBox = UIHelper.GetSelected(tbGMView.TogPartMode)
    SearchHair.bLastPartMode = bPartCheckBox
    if UIHelper.GetSelected(tbGMView.TogFileMode) then
        SearchHair.bLastFileMode = true
        SearchHair.Apply_ByName_Head(szSerchInfo, tbGMView.LabelExteriorDescript)
    else
        SearchHair.bLastFileMode = false
        SearchHair.Apply_Head(szSerchInfo, tbGMView.LabelExteriorDescript)
    end
end

function SearchHair:SwitchLeft(tbGMView)
	-- 注意前后按钮只适用按ID查询的情况
	if not UIHelper.GetSelected(tbGMView.TogFileMode)  then
        local szSerchID = UIHelper.GetString(tbGMView.EditSearchRight)
        if szSerchID == "" then
            szSerchID = SearchExterior.lastSearchID
        end
        if szSerchID then
            szSerchID = tostring(szSerchID - 1)
            UIHelper.SetString(tbGMView.EditSearchRight, szSerchID)
            SearchHair.Apply_Head(szSerchID, tbGMView.LabelExteriorDescript)
        else
            LOG.INFO("【警告】当前ID为空不支持前进后退！！")
            OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】当前ID为空不支持前进后退！！")
        end
    else
        LOG.INFO("【警告】文件查询模式下不支持前进后退！！")
        OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】文件查询模式下不支持前进后退！！")
    end
end

function SearchHair:SwitchRight(tbGMView)
        -- 注意前后按钮只适用按ID查询的情况
		if not UIHelper.GetSelected(tbGMView.TogFileMode)  then
			local szSerchID = UIHelper.GetString(tbGMView.EditSearchRight)
			if szSerchID == "" then
				szSerchID = SearchExterior.lastSearchID
			end
			if szSerchID then
				szSerchID = tostring(szSerchID + 1)
				UIHelper.SetString(tbGMView.EditSearchRight, szSerchID)
				SearchHair.Apply_Head(szSerchID, tbGMView.LabelExteriorDescript)
			else
				LOG.INFO("【警告】当前ID为空不支持前进后退！！")
				OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】当前ID为空不支持前进后退！！")
			end
		else
			LOG.INFO("【警告】文件查询模式下不支持前进后退！！")
			OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】文件查询模式下不支持前进后退！！")
		end
end

-- function SearchHair:GetAllData(tbGMView)
--     tbGMView.tbSearchResultRight = SearchHair.tHair
--     UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbSearchResultRight, PREFAB_ID.WidgetSunmon)
--     UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
-- end

function SearchHair.InitTools()
	if GMMgr then
        SearchHair.bInit = true
		local index_temp_HeadIndex_Settings = {"HeadID","HeadformID","BangID","PlaitID"}
		GMMgr.HeadIndex_Settings = GMMgr.LoadFile("","settings\\HairShop\\HeadIndex.tab",index_temp_HeadIndex_Settings,true)
	end
end

function SearchHair.ReturnFile(szSerchInfo,roleType)
	local filename_get = nil
	for index,filelist in pairs(tPartFileNameMap) do
		if string.find(szSerchInfo,index) then
			if filelist[roleType] then
				filename_get = filelist[roleType]
			else
                OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】tPartFileNameMap没有当前体型信息，请维护插件！！")
				----OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】tPartFileNameMap没有当前体型信息，请维护插件！！")
			end
			return filename_get
		end
	end
	return filename_get
end

function SearchHair.ReturnHeadPartName(szSerchInfo)
	local sPartName = nil
	for index,value in pairs(tBeHeadPartIndex) do
		if string.find(szSerchInfo,index) then
			sPartName = value
			break
		end
	end
	return sPartName
end




function SearchHair.GetFileName(path)
	local filename
	local fn_flag = string.find(path, "\\")
	if fn_flag then
		filename = string.match(path, ".+\\([^\\]*%.%w+)$")
	end
	local fn_flag2 = string.find(path, "/")
	if fn_flag2 then
		filename = string.match(path, ".+/([^/]*%.%w+)$")
	end
	return filename
end

function SearchHair.Apply_ByName_Head(szSerchInfo, szLabel)
	--[[注意：
	1.有的表现表，文件路径大小写不规范，如"Data\\source“，”data\\source”,使用LUA的大小写转换接口转换处理string.lower(s)，string.upper(s) ；
	2.如果同一个MESH文件被多个表现ID占用的，目前就选第一个找到的穿上，不会找下面的；
	3.因效率问题，目前只支持查询符合命名规范的文件，文件名必须包含"plait"，"head"，"bang"之一；
	--]]

	--防止点击过快
--~ 	if SearchHair.isCallBack == 0 then --说明上一次的回调还没执行就不能点
--~ 		OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】上次的发型请求还未处理完成，稍安勿躁！！", 2)
--~ 		return
--~ 	end
	
	local difSearchTime = GetTickCount() - SearchHair.lastStartSearchTime
	if difSearchTime < 500 then
		OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】点击频率过快，请稍等0.5秒再点击！！")
		return
	else
--~ 		SearchHair.isCallBack == 0
		local ResultsInfo = ""
		UIHelper.SetString(szLabel, "")

		local roleType = GetClientPlayer().nRoleType --数据类型是number
		local roleTypeInfo_Get = tBodyTypeMap[roleType]
		if not roleTypeInfo_Get then
			OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】tBodyTypeMap没有当前体型信息，请维护插件！！")
			return		
		end
		--完善查询信息，如果文件命名不规范将不做查询，效率低
		local szSerchID = "Data\\source\\player\\"..roleTypeInfo_Get.."\\部件\\"..roleTypeInfo_Get.."_"..szSerchInfo..".mesh" --补充出完整的匹配内容
--~ 			Output(szSerchID)
		--接下来是读取对应的表现表
		local filename_get = SearchHair.ReturnFile(szSerchInfo,roleType)
		if not filename_get then
			OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】查询的文件命名不规范，因效率问题不做全文件搜索！！")
			return		
		end
		local filepath_get = "represent\\player\\equip\\"..filename_get
--~ 			Output(filepath_get)
		if not SearchHair.tPartFile[filename_get] then
			local index_temp_UI = {"RepresentEquipID","Mesh"}
			SearchHair.tPartFile[filename_get] = GMMgr.LoadFile("",filepath_get,index_temp_UI,true)
		end
--~ 			Output(SearchHair.tPartFile[filename_get][1])
		local tRow_representID = GMMgr.Search(SearchHair.tPartFile[filename_get],"Mesh",szSerchID)
		if not tRow_representID then
			--表里大小写不规范，有时是"Data\\source“有时是”data\\source”
			tRow_representID = GMMgr.Search(SearchHair.tPartFile[filename_get],"Mesh",szSerchID,true) --开启模糊搜索
			if not tRow_representID then
				UIHelper.SetString(szLabel, filepath_get .. " 里不存在该命名的文件信息！")
				return
			end
		end
		
		local szPartName = SearchHair.ReturnHeadPartName(szSerchInfo) or "HeadformID" --给默认值
		local representID_Now = tRow_representID.RepresentEquipID
		local tRow_settings = GMMgr.Search(GMMgr.HeadIndex_Settings,szPartName,representID_Now)
		if (not tRow_settings) or (not tRow_settings.HeadID) then
			-- SearchHair.Edit_Info:SetText("settings\\HairShop\\HeadIndex.tab 下没有找到所查发型信息！")
			UIHelper.SetString(szLabel, "settings\\HairShop\\HeadIndex.tab 下没有找到所查发型信息！")
            return
		end
		
		szSerchID = tRow_settings.HeadID --表现ID，其实这里tRow_settings.SetID已经可以获取到
		SendGMCommand("player.SetRepresentID(EQUIPMENT_REPRESENT.HAIR_STYLE,"..szSerchID..")") --设置最终表现
		ResultsInfo = ResultsInfo.." HeadID:"..tRow_settings.HeadID.."   HeadformID:"..tRow_settings.HeadformID.."   BangID:"..tRow_settings.BangID.."   PlaitID:"..tRow_settings.PlaitID.."   部位:"..szPartName.."\n".."(要查看其他偏色，请去掉文件模式的勾选，输入当前HeadID加1-6执行即可)"
		-- SearchHair.Edit_Info:SetText(ResultsInfo)
		-- UIHelper.SetString(szLabel, "5555555555555")
        print(ResultsInfo)
        UIHelper.SetString(szLabel, ResultsInfo)
        SearchHair.lastStartSearchTime = GetTickCount()
--~ 		SearchHair.isCallBack == 1
--~ 		SearchHair.lastSearchID = szSerchID
		return true
	end
end

function SearchHair.Apply_Head(szSerchID, szLabel)
	--防止点击过快
--~ 	if SearchHair.isCallBack == 0 then --说明上一次的回调还没执行就不能点
--~ 		OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】上次的发型请求还未处理完成，稍安勿躁！", 2)
--~ 		return
--~ 	end

	local difSearchTime = GetTickCount() - SearchHair.lastStartSearchTime
	if difSearchTime < 500 then
		OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】点击频率过快，请稍等0.5秒再点击！")
		return
	else
--~ 		SearchHair.isCallBack == 0
		local ResultsInfo = ""
		UIHelper.SetString(szLabel,"")
		local tRow_settings = GMMgr.Search(GMMgr.HeadIndex_Settings,"HeadID",szSerchID)
		if not tRow_settings then
			UIHelper.SetString(szLabel,"settings\\HairShop\\HeadIndex.tab 下没有找到所查发型信息！")
			return
		end
		SendGMCommand("player.SetRepresentID(EQUIPMENT_REPRESENT.HAIR_STYLE,"..szSerchID..")") --设置最终表现
		
		------------------------------------------此段代码用于通过表现ID获得文件名------------------------------------------
		--接下来是读取对应的表现表
		local roleType = GetClientPlayer().nRoleType --数据类型是number
		local filename_get = SearchHair.ReturnFile("head",roleType)
--~ 		if not filename_get then
--~ 			OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】查询的文件命名不规范，因效率问题不做全文件搜索！！")
--~ 			return		
--~ 		end
		local filepath_get = "represent\\player\\equip\\"..filename_get
--~ 			Output(filepath_get)
		if not SearchHair.tPartFile[filename_get] then
			local index_temp_UI = {"RepresentEquipID","Mesh"}
			SearchHair.tPartFile[filename_get] = GMMgr.LoadFile("",filepath_get,index_temp_UI,true)
		end
--~ 			Output(SearchHair.tPartFile[filename_get][1])
		local representID_Mesh_Info = ""
		local tRow_representID_Mesh = ""
		local tRow_representID = GMMgr.Search(SearchHair.tPartFile[filename_get],"RepresentEquipID",tRow_settings.HeadformID)
		if tRow_representID then
			tRow_representID_Mesh = tRow_representID.Mesh
			representID_Mesh_Info = representID_Mesh_Info.."Head_Mesh:"..UIHelper.GBKToUTF8(tRow_representID_Mesh).."\n"
		end
		tRow_representID = GMMgr.Search(SearchHair.tPartFile[filename_get],"RepresentEquipID",tRow_settings.BangID)
		if tRow_representID then
			tRow_representID_Mesh = tRow_representID.Mesh
			representID_Mesh_Info = representID_Mesh_Info.."Bang_Mesh:"..UIHelper.GBKToUTF8(tRow_representID_Mesh).."\n"
		end
		tRow_representID = GMMgr.Search(SearchHair.tPartFile[filename_get],"RepresentEquipID",tRow_settings.PlaitID)
		if tRow_representID then
			tRow_representID_Mesh = tRow_representID.Mesh		
			representID_Mesh_Info = representID_Mesh_Info.."Plait_Mesh:"..UIHelper.GBKToUTF8(tRow_representID_Mesh).."\n"
		end	
		------------------------------------------
		
		ResultsInfo = ResultsInfo.." HeadID:"..tRow_settings.HeadID.."   HeadformID:"..tRow_settings.HeadformID.."   BangID:"..tRow_settings.BangID.."   PlaitID:"..tRow_settings.PlaitID.."\n"
		ResultsInfo = ResultsInfo..representID_Mesh_Info
		
		-- SearchHair.Edit_Info:SetText(ResultsInfo)
        UIHelper.SetString(szLabel,ResultsInfo)
		SearchHair.lastStartSearchTime = GetTickCount()
		SearchHair.lastSearchID = szSerchID
--~ 		SearchHair.isCallBack == 1
		return true
	end
end