if not SearchExterior then
    SearchExterior = {
        className = "SearchExterior",
        text = "外装测试",
        szPlaceHolder = "输入外装Set ID或名称",
        nViewID = VIEW_ID.PanelGMRightView,
        lastStartSearchTime = 0,
        lastResultsInfo = '',
        bLastPartMode = false,
        bLastFileMode = false,
        --bLastHD = true,
        isCallBack = 1,
        bInit = false,
        tExterior = {},
        tPartFile = {}, --用于存储已加载的部件表现表；
    }
end

local tPartFileNameMap = { --根据输入的关键词快速定位到具体哪个表现表
	["hand"] = { --护手
		[1] = "Bangle_m2.txt", --M2，标男
		[2] = "Bangle_f2.txt", --F2，标女
		[3] = "Bangle_m3.txt", --M3，魁梧男
		[4] = "Bangle_f3.txt", --F3，性感女
		[5] = "Bangle_m1.txt", --M1，小男孩
		[6] = "Bangle_f1.txt", --F1，小女孩
	},

	["body"] = { --上衣
		[1] = "Chest_m2.txt", --M2，标男
		[2] = "Chest_f2.txt", --F2，标女
		[3] = "Chest_m3.txt", --M3，魁梧男
		[4] = "Chest_f3.txt", --F3，性感女
		[5] = "Chest_m1.txt", --M1，小男孩
		[6] = "Chest_f1.txt", --F1，小女孩
	},

	["belt"] = { --腰带
		[1] = "Waist_m2.txt", --M2，标男
		[2] = "Waist_f2.txt", --F2，标女
		[3] = "Waist_m3.txt", --M3，魁梧男
		[4] = "Waist_f3.txt", --F3，性感女
		[5] = "Waist_m1.txt", --M1，小男孩
		[6] = "Waist_f1.txt", --F1，小女孩
	},

	["hat"] = { --头盔
		[1] = "Hat_m2.txt", --M2，标男
		[2] = "Hat_f2.txt", --F2，标女
		[3] = "Hat_m3.txt", --M3，魁梧男
		[4] = "Hat_f3.txt", --F3，性感女
		[5] = "Hat_m1.txt", --M1，小男孩
		[6] = "Hat_f1.txt", --F1，小女孩
	},

	["leg"] = { --鞋子
		[1] = "Pants_m2.txt", --M2，标男
		[2] = "Pants_f2.txt", --F2，标女
		[3] = "Pants_m3.txt", --M3，魁梧男
		[4] = "Pants_f3.txt", --F3，性感女
		[5] = "Pants_m1.txt", --M1，小男孩
		[6] = "Pants_f1.txt", --F1，小女孩
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

local tBodyPartNameMap = { --根据输入的关键字对应ExteriorInfo.tab里的SUBType
	["hand"] = 10, --护手
	["body"] = 2, --上衣
	["belt"] = 6, --腰带
	["hat"] = 3, --头盔
	["leg"] = 9, --鞋子
}

local tPartFileNameMap_BodyPart = { --根据输入的关键词快速定位到具体哪个表现表
	["BangleID"] = { --护手
		[1] = "Bangle_m2.txt", --M2，标男
		[2] = "Bangle_f2.txt", --F2，标女
		[3] = "Bangle_m3.txt", --M3，魁梧男
		[4] = "Bangle_f3.txt", --F3，性感女
		[5] = "Bangle_m1.txt", --M1，小男孩
		[6] = "Bangle_f1.txt", --F1，小女孩
	},

	["ChestID"] = { --上衣
		[1] = "Chest_m2.txt", --M2，标男
		[2] = "Chest_f2.txt", --F2，标女
		[3] = "Chest_m3.txt", --M3，魁梧男
		[4] = "Chest_f3.txt", --F3，性感女
		[5] = "Chest_m1.txt", --M1，小男孩
		[6] = "Chest_f1.txt", --F1，小女孩
	},

	["WaistID"] = { --腰带
		[1] = "Waist_m2.txt", --M2，标男
		[2] = "Waist_f2.txt", --F2，标女
		[3] = "Waist_m3.txt", --M3，魁梧男
		[4] = "Waist_f3.txt", --F3，性感女
		[5] = "Waist_m1.txt", --M1，小男孩
		[6] = "Waist_f1.txt", --F1，小女孩
	},

	["HelmID"] = { --头盔
		[1] = "Hat_m2.txt", --M2，标男
		[2] = "Hat_f2.txt", --F2，标女
		[3] = "Hat_m3.txt", --M3，魁梧男
		[4] = "Hat_f3.txt", --F3，性感女
		[5] = "Hat_m1.txt", --M1，小男孩
		[6] = "Hat_f1.txt", --F1，小女孩
	},

	["BootsID"] = { --鞋子
		[1] = "Pants_m2.txt", --M2，标男
		[2] = "Pants_f2.txt", --F2，标女
		[3] = "Pants_m3.txt", --M3，魁梧男
		[4] = "Pants_f3.txt", --F3，性感女
		[5] = "Pants_m1.txt", --M1，小男孩
		[6] = "Pants_f1.txt", --F1，小女孩
	},
}

function SearchExterior:FillAll()
    local tbExterior = g_tTable.ExteriorBox
    local nRow = tbExterior:GetRowCount()
    for i = 2, nRow do
        local tExteriorStringInfo = tbExterior:GetRow(i)
        if tExteriorStringInfo then
            local szExteriorName = '['..tExteriorStringInfo.nSet..'] '..tExteriorStringInfo.szSetName
            local tTemp = {ID = tExteriorStringInfo.nSet, Name = szExteriorName, ButtonLabel = '获取',
                            tBtnStatus = {
                                    BtnOperate = true, BtnOperate1 = false, BtnOperate2 = false,
                                    BtnOperate3 = false, BtnOperate4 = false
                                        }
                            }
            table.insert(SearchExterior.tExterior, tTemp)
        end
    end
end

function SearchExterior:ShowSubWindow(tbGMView)
    tbGMView.PanelRightView:setVisible(true)
    tbGMView.BtnExecute:setVisible(true)
    UIHelper.SetString(tbGMView.LabelExecute, "应用")
    tbGMView.WidgetExterior:setVisible(true)
    tbGMView.TogFileMode:setVisible(true)
    tbGMView.WidgetSwitch:setVisible(true)
    tbGMView.EditSearchRight:setPlaceHolder(SearchExterior.szPlaceHolder)
    if tbGMView.tbLastData~=nil and next(tbGMView.tbLastData) then
        UIHelper.SetString(tbGMView.EditSearchRight, tbGMView.tbLastData.EditLabelRight)
    else
        UIHelper.SetString(tbGMView.EditSearchRight, "")
    end

    UIHelper.SetString(tbGMView.LabelTitle, SearchExterior.text)
    -- 设置勾选状态
    UIHelper.SetSelected(tbGMView.TogPartMode, SearchExterior.bLastPartMode)
    UIHelper.SetString(tbGMView.LabelPartMode, '部件模式')
    UIHelper.SetSelected(tbGMView.TogFileMode, SearchExterior.bLastFileMode)
    UIHelper.SetString(tbGMView.LabelFileMode, '文件模式')
    UIHelper.SetString(tbGMView.LabelExteriorDescript, SearchExterior.lastResultsInfo)
end

function SearchExterior:OnClick(tbGMView)
    if not SearchExterior.bInit then
        -- SearchExterior:FillAll()
        SearchExterior.InitTools()
    end
    SearchExterior:ShowSubWindow(tbGMView)
    UIHelper.SetString(tbGMView.EditSearchRight, "")
    tbGMView.tbGMPanelRight = SearchExterior
    tbGMView.tbRawDataRight = SearchExterior.tExterior
    tbGMView.tbSearchResultRight = SearchExterior.tExterior
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end


-- function SearchExterior:BtnOperate(tbData)
--     SearchExterior.Apply(tbData.ID)
-- end

function SearchExterior:BtnExecute(tbGMView)
    local szSerchInfo = UIHelper.GetString(tbGMView.EditSearchRight)
    local bPartCheckBox = UIHelper.GetSelected(tbGMView.TogPartMode)
    SearchExterior.bLastPartMode = bPartCheckBox
    if UIHelper.GetSelected(tbGMView.TogFileMode) then
        SearchExterior.bLastFileMode = true
        SearchExterior.Apply_ByName(szSerchInfo, bPartCheckBox, tbGMView.LabelExteriorDescript)
    else
        SearchExterior.bLastFileMode = false
        SearchExterior.Apply(szSerchInfo, bPartCheckBox, tbGMView.LabelExteriorDescript)
    end
end

function SearchExterior:SwitchLeft(tbGMView)
    -- 注意前后按钮只适用按ID查询的情况
    if not UIHelper.GetSelected(tbGMView.TogFileMode)  then
        local szSerchID = UIHelper.GetString(tbGMView.EditSearchRight)
        local bPartCheckBox = UIHelper.GetSelected(tbGMView.TogPartMode)
        if szSerchID == "" then
            szSerchID = SearchExterior.lastSearchID
        end
        if szSerchID then
            szSerchID = tostring(szSerchID - 1)
            UIHelper.SetString(tbGMView.EditSearchRight, szSerchID)
            SearchExterior.Apply(szSerchID, bPartCheckBox, tbGMView.LabelExteriorDescript)
        else
            LOG.INFO("【警告】当前ID为空不支持前进后退！！")
            OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】当前ID为空不支持前进后退！！")
        end
    else
        LOG.INFO("【警告】文件查询模式下不支持前进后退！！")
        OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】文件查询模式下不支持前进后退！！")
    end
end

function SearchExterior:SwitchRight(tbGMView)
    -- 注意前后按钮只适用按ID查询的情况
    if not UIHelper.GetSelected(tbGMView.TogFileMode)  then
        local szSerchID = UIHelper.GetString(tbGMView.EditSearchRight)
        local bPartCheckBox = UIHelper.GetSelected(tbGMView.TogPartMode)
        if szSerchID == "" then
            szSerchID = SearchExterior.lastSearchID
        end
        if szSerchID then
            szSerchID = tostring(szSerchID + 1)
            UIHelper.SetString(tbGMView.EditSearchRight, szSerchID)
            SearchExterior.Apply(szSerchID, bPartCheckBox, tbGMView.LabelExteriorDescript)
        else
            LOG.INFO("【警告】当前ID为空不支持前进后退！！")
            OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】当前ID为空不支持前进后退！！")
        end
    else
        LOG.INFO("【警告】文件查询模式下不支持前进后退！！")
        OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】文件查询模式下不支持前进后退！！")
    end
end

function SearchExterior.ReturnFile(szSerchInfo,roleType)
	local filename_get = nil
	for index,filelist in pairs(tPartFileNameMap) do
		if string.find(szSerchInfo,index) then
			if filelist[roleType] then
				filename_get = filelist[roleType]
			else
                OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】tPartFileNameMap没有当前体型信息，请维护插件！！")
				----OutputWarningMessage("MSG_ADVERT_RED", "【警告】tPartFileNameMap没有当前体型信息，请维护插件！！", 8)
			end
			return filename_get
		end
	end
	return filename_get
end

function SearchExterior.ReturnSubType(szSerchInfo)
	local subType_get = nil
	for index,subTypeNow in pairs(tBodyPartNameMap) do
		if string.find(szSerchInfo,index) then
			subType_get = subTypeNow
			return subType_get
		end
	end
	return subType_get
end

function SearchExterior.InitTools()
	if GMMgr then
        SearchExterior.bInit = true
		local index_temp_Exterior_UI = {"Set","SetName","HelmID","ChestID","BangleID","WaistID","BootsID"}
		GMMgr.Exterior_UI = GMMgr.LoadFile("","ui\\Scheme\\Case\\Exterior\\ExteriorBox.txt",index_temp_Exterior_UI,true)
		local index_temp_Exterior_Settings = {"ID","SubType","RepresentID","ColorID","SetID"}
		GMMgr.Exterior_Settings = GMMgr.LoadFile("","settings\\Exterior\\ExteriorInfo.tab",index_temp_Exterior_Settings,true)
	end
end


function SearchExterior.ReturnFileByBodyPart(bodyPart,roleType)
	local filename_get = nil
	local filelist = tPartFileNameMap_BodyPart[bodyPart]
	if not filelist then
        OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】tPartFileNameMap_BodyPart没有当前部件信息，请维护插件！！")
		--OutputWarningMessage("MSG_ADVERT_RED", "【警告】tPartFileNameMap_BodyPart没有当前部件信息，请维护插件！！", 8)
		return filename_get
	end

	if filelist[roleType] then
		filename_get = filelist[roleType]
	else
        OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】tPartFileNameMap_BodyPart没有当前体型信息，请维护插件！！")
		--OutputWarningMessage("MSG_ADVERT_RED", "【警告】tPartFileNameMap_BodyPart没有当前体型信息，请维护插件！！", 8)
		return filename_get
	end
	return filename_get
end


function SearchExterior.AddMeshInfo(bodyPart,roleType,representID,ResultsInfo)
    --~ 		local time_start = GetTickCount()
        --新增输出部件对应的资源文件名
        local filename_get = SearchExterior.ReturnFileByBodyPart(bodyPart,roleType)
        if not filename_get then
            return ResultsInfo
        end
        local filepath_get = "represent\\player\\equip\\"..filename_get
    --~ 			Output(filepath_get)
        if not SearchExterior.tPartFile[filename_get] then
            local index_temp_UI = {"RepresentEquipID","Mesh"}
            SearchExterior.tPartFile[filename_get] = GMMgr.LoadFile("",filepath_get,index_temp_UI)
        end

        local tRow_representID = GMMgr.Search(SearchExterior.tPartFile[filename_get],"RepresentEquipID",representID)
        if not tRow_representID then
            ResultsInfo = ResultsInfo .."   Mesh: 表现表" ..filename_get.."找不到该表现ID对应的资源!"
        else
            local MeshName = SearchExterior.GetFileName(tRow_representID.Mesh) or "没配置Mesh资源!"
            local indexNow = string.find(MeshName,".mesh") or string.len(MeshName)
            MeshName = string.sub(MeshName,1,indexNow-1)
            ResultsInfo = ResultsInfo .. "   Mesh: " .. MeshName
        end
    --~ 		local time_end = GetTickCount()
    --~ 		local time_dif = time_end - time_start
    --~ 		OutputMessage("MSG_SYS", "★【GMMgr】★本次外装读表查询耗时："..time_dif.." 帧!\n")
        return ResultsInfo
end

function SearchExterior.GetFileName(path)
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

function SearchExterior.Apply(szSerchID, bPartCheckBox, szLabel)
	--防止点击过快
	if SearchExterior.isCallBack == 0 then --说明上一次的回调还没执行就不能点
        OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】上次的外装请求还未处理完成，稍安勿躁！")
		--OutputWarningMessage("MSG_ADVERT_RED", "【警告】上次的外装请求还未处理完成，稍安勿躁！", 2)
		return
	end

	local difSearchTime = GetTickCount() - SearchExterior.lastStartSearchTime
	if difSearchTime < 500 then
        OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】点击频率过快，请稍等0.5秒再点击！")
		--OutputWarningMessage("MSG_ADVERT_RED", "【警告】点击频率过快，请稍等0.5秒再点击！", 8)
		return
	else
		local ResultsInfo = ""
        UIHelper.SetString(szLabel, "")
		local roleType = GetClientPlayer().nRoleType --数据类型是number

		-- if SearchExterior.CheckBox:IsCheckBoxChecked() == true then
        if bPartCheckBox then
			--部件查询模式(即是外装ID，同个表现ID结合不同部件位置和偏色就成了不同的外装ID)
			local tRow_settings = GMMgr.Search(GMMgr.Exterior_Settings,"ID",szSerchID)
			if not tRow_settings then
                UIHelper.SetString(szLabel, "settings\\Exterior\\ExteriorInfo.tab 下没有找到所查部件ID！")
				return
			end
			ResultsInfo = ResultsInfo.." ID"..tRow_settings.ID.."   SubType:"..tRow_settings.SubType.."   RepresentID:"..tRow_settings.RepresentID.."   ColorID:"..tRow_settings.ColorID.."\n"
			local tBodyPartID = { --逻辑索引表与表现索引表的映射表
				[EQUIPMENT_SUB.HELM] = {1,"HelmID"},   --EQUIPMENT_SUB.HELM对应 Exterior_Settings 里的SubType
				[EQUIPMENT_SUB.CHEST] = {0,"ChestID"},
				[EQUIPMENT_SUB.BANGLE] = {3,"BangleID"},
				[EQUIPMENT_SUB.WAIST] = {2,"WaistID"},
				[EQUIPMENT_SUB.BOOTS] = {4,"BootsID"},
			}
			local nSubType = tonumber(tRow_settings.SubType)
			ResultsInfo = ResultsInfo.."   部件:"..tBodyPartID[nSubType][2]
			local tRow_Ui = GMMgr.Search(GMMgr.Exterior_UI,tBodyPartID[nSubType][2],szSerchID)
			if not tRow_Ui then
                UIHelper.SetString(szLabel, "ui\\Scheme\\Case\\Exterior\\ExteriorBox.txt 该部件ID在UI下没有找到对应的SetID！")
				return
			end
			ResultsInfo = ResultsInfo.."   SetID:"..tRow_Ui.Set.."   SetName:"..UIHelper.GBKToUTF8(tRow_Ui.SetName)
			--添加资源信息
			ResultsInfo = SearchExterior.AddMeshInfo(tBodyPartID[nSubType][2],roleType,tRow_settings.RepresentID,ResultsInfo)
			SendGMCommand("player.AddExterior("..szSerchID..",0,2,1)") --添加到列表,有延迟
			SearchExterior.isCallBack = 0
			local fnSaveBodyPart = function()
				local tGoodsList = {}
				local tItem = {}
				tItem.dwGoodsID = tonumber(szSerchID)
				tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
				table.insert(tGoodsList,tItem)
				GetCoinShopClient().Save(tGoodsList)
				SearchExterior.isCallBack = 1
			end
            Timer.Add(SearchExterior, 1, function() fnSaveBodyPart() end)
		else
			--套装查询模式
			local tRow = GMMgr.Search(GMMgr.Exterior_UI,"Set",szSerchID)
			if not tRow then
                UIHelper.SetString(szLabel, "ui\\Scheme\\Case\\Exterior\\ExteriorBox.txt 下没有找到所查SetID！")
				return
			end
			ResultsInfo = " Set:"..tRow.Set.."\n SetName:"..UIHelper.GBKToUTF8(tRow.SetName).."\n"
			local tRow_settings = GMMgr.Search(GMMgr.Exterior_Settings,"ID",tRow.HelmID) or {RepresentID = "",ColorID=""}
			ResultsInfo = ResultsInfo.." HelmID:"..tRow.HelmID.."   represetID:"..tRow_settings.RepresentID.."   colorID:"..tRow_settings.ColorID
			--添加资源信息
			ResultsInfo = SearchExterior.AddMeshInfo("HelmID",roleType,tRow_settings.RepresentID,ResultsInfo).."\n"

			tRow_settings = GMMgr.Search(GMMgr.Exterior_Settings,"ID",tRow.ChestID) or {RepresentID = "",ColorID=""}
			ResultsInfo = ResultsInfo.." ChestID:"..tRow.ChestID.."   represetID:"..tRow_settings.RepresentID.."   colorID:"..tRow_settings.ColorID
			--添加资源信息
			ResultsInfo = SearchExterior.AddMeshInfo("ChestID",roleType,tRow_settings.RepresentID,ResultsInfo).."\n"

			tRow_settings = GMMgr.Search(GMMgr.Exterior_Settings,"ID",tRow.BangleID) or {RepresentID = "",ColorID=""}
			ResultsInfo = ResultsInfo.." BangleID:"..tRow.BangleID.."   represetID:"..tRow_settings.RepresentID.."   colorID:"..tRow_settings.ColorID
			--添加资源信息
			ResultsInfo = SearchExterior.AddMeshInfo("BangleID",roleType,tRow_settings.RepresentID,ResultsInfo).."\n"

			tRow_settings = GMMgr.Search(GMMgr.Exterior_Settings,"ID",tRow.WaistID) or {RepresentID = "",ColorID=""}
			ResultsInfo = ResultsInfo.." WaistID:"..tRow.WaistID.."   represetID:"..tRow_settings.RepresentID.."   colorID:"..tRow_settings.ColorID
			--添加资源信息
			ResultsInfo = SearchExterior.AddMeshInfo("WaistID",roleType,tRow_settings.RepresentID,ResultsInfo).."\n"

			tRow_settings = GMMgr.Search(GMMgr.Exterior_Settings,"ID",tRow.BootsID) or {RepresentID = "",ColorID=""}
			ResultsInfo = ResultsInfo.." BootsID:"..tRow.BootsID.."   represetID:"..tRow_settings.RepresentID.."   colorID:"..tRow_settings.ColorID
			--添加资源信息
			ResultsInfo = SearchExterior.AddMeshInfo("BootsID",roleType,tRow_settings.RepresentID,ResultsInfo).."\n"

			local nCurrentSetID = GetClientPlayer().GetCurrentSetID()
			local tSet =
				{
					[EXTERIOR_INDEX_TYPE.HELM] = tonumber(tRow.HelmID), --【EXTERIOR_INDEX_TYPE.HELM】前面是部件索引位置，后面是部件ID
					[EXTERIOR_INDEX_TYPE.CHEST] = tonumber(tRow.ChestID),
					[EXTERIOR_INDEX_TYPE.BANGLE] = tonumber(tRow.BangleID),
					[EXTERIOR_INDEX_TYPE.WAIST] = tonumber(tRow.WaistID),
					[EXTERIOR_INDEX_TYPE.BOOTS] = tonumber(tRow.BootsID),
				}
			for index,value in pairs(tSet) do
				if value ~= -1 then
					SendGMCommand("player.AddExterior("..value..",0,2,1)") --添加到列表,有延迟
				end
			end


			SearchExterior.isCallBack = 0
			local fnSaveSet = function()
				local tGoodsList = {}
				for index,value in pairs(tSet) do
					if value ~= -1 then
						local tItem = {}
						tItem.dwGoodsID = value
						tItem.eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
						table.insert(tGoodsList,tItem)
					end
				end
				GetCoinShopClient().Save(tGoodsList)
				SearchExterior.isCallBack = 1
			end
            Timer.Add(SearchExterior, 1, function() fnSaveSet() end)
		end
        SearchExterior.lastResultsInfo = ResultsInfo
        UIHelper.SetString(szLabel, ResultsInfo)
		SearchExterior.lastStartSearchTime = GetTickCount()
		SearchExterior.lastSearchID = szSerchID
        return true
	end
end


function SearchExterior.Apply_ByName(szSerchInfo, bPartCheckBox, szLabel)
    --[[注意：
	1.有的表现表，文件路径大小写不规范，如"Data\\source“，”data\\source”
	2.如果同一个MESH文件被多个表现ID占用的，目前就选第一个找到的穿上，不会找下面的；
	3.因效率问题，目前只支持查询符合命名规范的文件，文件名必须包含"hand"，"body"，"belt"，"hat"，"leg"之一；
	--]]
    --防止点击过快
    if SearchExterior.isCallBack == 0 then --说明上一次的回调还没执行就不能点
        OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】上次的外装请求还未处理完成，稍安勿躁！！")
        ----OutputWarningMessage("MSG_ADVERT_RED", "【警告】上次的外装请求还未处理完成，稍安勿躁！！", 2)
        return
    end

    local difSearchTime = GetTickCount() - SearchExterior.lastStartSearchTime
    if difSearchTime < 500 then
        OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】点击频率过快，请稍等0.5秒再点击！！")
        ----OutputWarningMessage("MSG_ADVERT_RED", "【警告】点击频率过快，请稍等0.5秒再点击！！", 8)
        return
    else
        --~ 		SearchExterior.lastSearchID = szSerchID
        local ResultsInfo = ""
        UIHelper.SetString(szLabel, "")
        local roleType = GetClientPlayer().nRoleType --数据类型是number
        local roleTypeInfo_Get = tBodyTypeMap[roleType]
        if not roleTypeInfo_Get then
            OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】tBodyTypeMap没有当前体型信息，请维护插件！！")
            ----OutputWarningMessage("MSG_ADVERT_RED", "【警告】tBodyTypeMap没有当前体型信息，请维护插件！！", 8)
            return
        end
        --完善查询信息，如果文件命名不规范将不做查询，效率低
        local szSerchID =
            "Data\\source\\player\\" ..
            roleTypeInfo_Get .. "\\部件\\" .. roleTypeInfo_Get .. "_" .. szSerchInfo .. ".mesh" --补充出完整的匹配内容
        --~ 			Output(szSerchID)
        --接下来是读取对应的表现表
        local filename_get = SearchExterior.ReturnFile(szSerchInfo, roleType)
        if not filename_get then
            OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】查询的文件命名不规范，因效率问题不做全文件搜索！！")
            ----OutputWarningMessage("MSG_ADVERT_RED", "【警告】查询的文件命名不规范，因效率问题不做全文件搜索！！", 8)
            return
        end
        local filepath_get = "represent\\player\\equip\\" .. filename_get
        --~ 			Output(filepath_get)
        if not SearchExterior.tPartFile[filename_get] then
            local index_temp_UI = {"RepresentEquipID", "Mesh"}
            SearchExterior.tPartFile[filename_get] = GMMgr.LoadFile("", filepath_get, index_temp_UI)
        end
        --~ 			Output(SearchExterior.tPartFile[filename_get][1])
        local tRow_representID = GMMgr.Search(SearchExterior.tPartFile[filename_get], "Mesh", szSerchID)
        if not tRow_representID then
            --表里大小写不规范，有时是"Data\\source“有时是”data\\source”
            tRow_representID = GMMgr.Search(SearchExterior.tPartFile[filename_get], "Mesh", szSerchID, true) --开启模糊搜索
            if not tRow_representID then
                UIHelper.SetString(szLabel, filepath_get .. " 里不存在该命名的文件信息！")
                return
            end
        end

        local representID_Now = tRow_representID.RepresentEquipID
        local subTypeID_Now = tostring(SearchExterior.ReturnSubType(szSerchInfo))
        if not subTypeID_Now then
            OutputMessage("MSG_ANNOUNCE_NORMAL", "【警告】tBodyPartNameMap没有当前subType信息，请维护插件！！")
            ----OutputWarningMessage("MSG_ADVERT_RED", "【警告】tBodyPartNameMap没有当前subType信息，请维护插件！！", 8)
            return
        end

        local tRow_settings = nil
        for index, data in pairs(GMMgr.Exterior_Settings) do
            if data["RepresentID"] == representID_Now and data["SubType"] == subTypeID_Now then
                tRow_settings = data
                break
            end
        end
        if (not tRow_settings) or (not tRow_settings.ID) then
            UIHelper.SetString(szLabel, "settings\\Exterior\\ExteriorInfo.tab 下没有找到所查部件ID！")
            return
        end

        if bPartCheckBox then
            --部件查询模式(即是按外装ID查询，同个表现ID结合不同部件位置和偏色就成了不同的外装ID)
            szSerchID = tRow_settings.ID --表现ID，其实这里tRow_settings.SetID已经可以获取到
            ResultsInfo =
                ResultsInfo ..
                " ID" ..
                    tRow_settings.ID ..
                        "   SubType:" ..
                            tRow_settings.SubType ..
                                "   RepresentID:" ..
                                    tRow_settings.RepresentID .. "   ColorID:" .. tRow_settings.ColorID .. "\n"
            local tBodyPartID = {
                --逻辑索引表与表现索引表的映射表
                [EQUIPMENT_SUB.HELM] = {1, "HelmID"}, --EQUIPMENT_SUB.HELM对应 Exterior_Settings 里的SubType
                [EQUIPMENT_SUB.CHEST] = {0, "ChestID"},
                [EQUIPMENT_SUB.BANGLE] = {3, "BangleID"},
                [EQUIPMENT_SUB.WAIST] = {2, "WaistID"},
                [EQUIPMENT_SUB.BOOTS] = {4, "BootsID"}
            }
            local nSubType = tonumber(tRow_settings.SubType)
            ResultsInfo = ResultsInfo .. "   部件:" .. tBodyPartID[nSubType][2]
            local tRow_Ui = GMMgr.Search(GMMgr.Exterior_UI, tBodyPartID[nSubType][2], szSerchID)
            if not tRow_Ui then
                UIHelper.SetString(szLabel, "ui\\Scheme\\Case\\Exterior\\ExteriorBox.txt 该部件ID在UI下没有找到对应的SetID！")
                return
            end
            ResultsInfo = ResultsInfo .. "   SetID:" .. tRow_Ui.Set .. "   SetName:" .. UIHelper.GBKToUTF8(tRow_Ui.SetName)

            SendGMCommand("player.AddExterior(" .. szSerchID .. ",0,2,1)") --添加到列表,有延迟

            SearchExterior.isCallBack = 0
            local fnSaveBodyPart = function()
                local tGoodsList = {}
                local tExterior = {}
                tExterior.dwGoodsID = tonumber(szSerchID)
                tExterior.eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
                table.insert(tGoodsList, tExterior)
                GetCoinShopClient().Save(tGoodsList)
                SearchExterior.isCallBack = 1
            end
            Timer.Add(SearchExterior, 1, function() fnSaveBodyPart() end)
        else
            local szSerchID_SetID = tRow_settings.SetID
            local tRow = GMMgr.Search(GMMgr.Exterior_UI, "Set", szSerchID_SetID)
            if not tRow then
                UIHelper.SetString(szLabel, "ui\\Scheme\\Case\\Exterior\\ExteriorBox.txt 下没有找到所查SetID！")
                return
            end
            ResultsInfo = " Set:" .. tRow.Set .. "\n SetName:" .. UIHelper.GBKToUTF8(tRow.SetName) .. "\n"
            local tRow_settings =
                GMMgr.Search(GMMgr.Exterior_Settings, "ID", tRow.HelmID) or {RepresentID = "", ColorID = ""}
            ResultsInfo =
                ResultsInfo ..
                " HelmID:" ..
                    tRow.HelmID ..
                        "   represetID:" .. tRow_settings.RepresentID .. "   colorID:" .. tRow_settings.ColorID .. "\n"

            tRow_settings =
                GMMgr.Search(GMMgr.Exterior_Settings, "ID", tRow.ChestID) or {RepresentID = "", ColorID = ""}
            ResultsInfo =
                ResultsInfo ..
                " ChestID:" ..
                    tRow.ChestID ..
                        "   represetID:" .. tRow_settings.RepresentID .. "   colorID:" .. tRow_settings.ColorID .. "\n"

            tRow_settings =
                GMMgr.Search(GMMgr.Exterior_Settings, "ID", tRow.BangleID) or {RepresentID = "", ColorID = ""}
            ResultsInfo =
                ResultsInfo ..
                " BangleID:" ..
                    tRow.BangleID ..
                        "   represetID:" .. tRow_settings.RepresentID .. "   colorID:" .. tRow_settings.ColorID .. "\n"

            tRow_settings =
                GMMgr.Search(GMMgr.Exterior_Settings, "ID", tRow.WaistID) or {RepresentID = "", ColorID = ""}
            ResultsInfo =
                ResultsInfo ..
                " WaistID:" ..
                    tRow.WaistID ..
                        "   represetID:" .. tRow_settings.RepresentID .. "   colorID:" .. tRow_settings.ColorID .. "\n"

            tRow_settings =
                GMMgr.Search(GMMgr.Exterior_Settings, "ID", tRow.BootsID) or {RepresentID = "", ColorID = ""}
            ResultsInfo =
                ResultsInfo ..
                " BootsID:" ..
                    tRow.BootsID ..
                        "   represetID:" .. tRow_settings.RepresentID .. "   colorID:" .. tRow_settings.ColorID .. "\n"
            local nCurrentSetID = GetClientPlayer().GetCurrentSetID()
            local tSet = {
                [EXTERIOR_INDEX_TYPE.HELM] = tonumber(tRow.HelmID), --【EXTERIOR_INDEX_TYPE.HELM】前面是部件索引位置，后面是部件ID
                [EXTERIOR_INDEX_TYPE.CHEST] = tonumber(tRow.ChestID),
                [EXTERIOR_INDEX_TYPE.BANGLE] = tonumber(tRow.BangleID),
                [EXTERIOR_INDEX_TYPE.WAIST] = tonumber(tRow.WaistID),
                [EXTERIOR_INDEX_TYPE.BOOTS] = tonumber(tRow.BootsID)
            }
            for index, value in pairs(tSet) do
                if value ~= -1 then
                    SendGMCommand("player.AddExterior(" .. value .. ",0,2,1)") --添加到列表,有延迟
                end
            end

            SearchExterior.isCallBack = 0
            local fnSaveSet = function()
                local tGoodsList = {}
                for index, value in pairs(tSet) do
                    if value ~= -1 then
                        local tExterior = {}
                        tExterior.dwGoodsID = value
                        tExterior.eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
                        table.insert(tGoodsList, tExterior)
                    end
                end
                GetCoinShopClient().Save(tGoodsList)
                SearchExterior.isCallBack = 1
            end
            Timer.Add(SearchExterior, 1, function() fnSaveSet() end)
        end
        SearchExterior.lastResultsInfo = ResultsInfo
        UIHelper.SetString(szLabel, ResultsInfo)
        SearchExterior.lastStartSearchTime = GetTickCount()
        return true
    end
end