-- ---------------------------------------------------------------------------------
-- Name: UIPanelAllotMaterialsPop
-- Desc: 分配装置弹出框
-- Prefab:PanelAllotMaterialsPop
-- ---------------------------------------------------------------------------------

local UIPanelAllotMaterialsPop = class("UIPanelAllotMaterialsPop")

function UIPanelAllotMaterialsPop:_LuaBindList()
    self.BtnClose          = self.BtnClose

    self.LabelMaterialName = self.LabelMaterialName -- 装备name

    self.ScrollView        = self.ScrollView -- 加载 WidgettAllotPlayerListCell
    self.WidgetEmpty       = self.WidgetEmpty -- 空白widget

    self.BtnCancel         = self.BtnCancel -- 分配取消
    self.BtnAccept         = self.BtnAccept -- 分配确认
end

function UIPanelAllotMaterialsPop:OnEnter(nIndex)
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
    self.nIndex = nIndex
    CommandBaseData.SetGoodsIndex(nIndex)
    CommandBaseData.ClearGoodsAllotInfo()
    self:UpdateInfo(nIndex)
end

function UIPanelAllotMaterialsPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
    CommandBaseData.ClearGoodsAllotInfo()
end

function UIPanelAllotMaterialsPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        CommandBaseData.ClearGoodsAllotInfo()
        self:UpdateInfo(self.nIndex)
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function()
        self:AllotMaterial()
        UIMgr.Close(self)
    end)
end

function UIPanelAllotMaterialsPop:RegEvent()
    
end

function UIPanelAllotMaterialsPop:UnRegEvent()

end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelAllotMaterialsPop:UpdateInfo(nIndex)

    UIHelper.SetString(self.LabelMaterialName, CommandBaseData.tGoodsTypeToName[nIndex])

    -- local tSortedInfos = self:SortAllPlayer()
    CommandBaseData.InitManagerList()
    local tSortedInfos = CommandBaseData.GetPlayerSortedInfo()
    if #tSortedInfos == 0 then
        UIHelper.SetVisible(self.ScrollView, false)
        UIHelper.SetVisible(self.WidgetEmpty, true)
    else
        UIHelper.SetVisible(self.ScrollView, true)
        UIHelper.SetVisible(self.WidgetEmpty, false)

        UIHelper.RemoveAllChildren(self.ScrollView)
        for _, tInfo in pairs(tSortedInfos) do
            local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgettAllotPlayerListCell, self.ScrollView)
            assert(scriptCell)
            scriptCell:UpdateInfo(tInfo)
            scriptCell:SetEditBox()
        end

        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollView)
    end
end

function UIPanelAllotMaterialsPop:SortAllPlayer()
    local tSortedInfos = {}
	for dwID, tInfo in pairs(CommandBaseData.tPlayerInfo) do
		if CommandBaseData.tPlayerIDInMemberList[tInfo.tNumberInfo.dwDeputyID] == true then 
			if  tInfo.tNumberInfo.DeputyInfo[5] == 1 then 
				table.insert(tSortedInfos, 1, tInfo)
			else
				table.insert(tSortedInfos, tInfo)
			end
		end
	end
	return tSortedInfos
end

function UIPanelAllotMaterialsPop:AllotMaterial()
    local tInfo = CommandBaseData.GetGoodsAllotInfo()
    local tRes = {}
    if tInfo == {} then 
        UIMgr.Close(self)
    else
        for _, v in pairs(tInfo) do
            if v.nAddCount ~= 0 then 
                table.insert(tRes, v)
            end
        end
    end
    if #tRes ~= 0 then 
        RemoteCallToServer("On_Camp_GFAssignItem", self.nIndex, tRes)
    end
end


return UIPanelAllotMaterialsPop