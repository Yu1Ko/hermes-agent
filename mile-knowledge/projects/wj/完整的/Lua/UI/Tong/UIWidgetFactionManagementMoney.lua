-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetFactionManagementMoney
-- Date: 2023-03-01
-- Desc: 帮会资金
-- Prefab: WidgetFactionManagementMoney
-- ---------------------------------------------------------------------------------

local UIWidgetFactionManagementMoney = class("UIWidgetFactionManagementMoney")

local g2u = UIHelper.GBKToUTF8
local u2g = UIHelper.UTF8ToGBK

function UIWidgetFactionManagementMoney:Init()
	self.m = {}	
	self:RegEvent()
	self:BindUIEvent()
end

function UIWidgetFactionManagementMoney:UnInit()
	self:UnRegEvent()
	UIHelper.RemoveFromParent(self._rootNode)	
	self.m = nil
end

function UIWidgetFactionManagementMoney:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
		self:OnConfirm()
	end)
	UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
		self:OnReset()
	end)
end

function UIWidgetFactionManagementMoney:OnConfirm()
	local nChangeRepairCost = 10000
	if TongData.GetFund() < nChangeRepairCost then
		--OutputMessage("MSG_RED", FormatString(g_tStrings.GUILD_CHANGE_PAY_NOT_ENOUGH_MONEY, UIHelper.GetMoneyPureText(nChangeRepairCost * 10000)))
        OutputMessage("MSG_RED", string.format("每次调整帮会资金额度需要消耗帮会资金%s，当前的帮会资金不足。", UIHelper.GetMoneyPureText(nChangeRepairCost * 10000)))
		return
	end
    -- UIHelper.ShowConfirm(FormatString(g_tStrings.GUILD_CHANGE_PAY_SURE, UIHelper.GetMoneyPureText(nChangeRepairCost * 10000)),
	UIHelper.ShowConfirm(string.format("你确定要调整帮会资金额度么？每次设置会消耗帮会资金%s。", UIHelper.GetMoneyPureText(nChangeRepairCost * 10000)), 
		function ()
			local tRepair = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
			for i, v in ipairs(self.m.tEditValArr) do
				tRepair[i] = v
			end
			RemoteCallToServer("OnModifyTongRepairDailyLimit", tRepair)			
			GetTongClient().ApplyTongInfo() -- 触发数据同步, 也用以判断是否成功
			self.m.bChangeCommit = true	
		end
	)
	
end

function UIWidgetFactionManagementMoney:OnShow()
	self:InitUI()

    if not TongData.IsDemesnePurchased() then
        TipsHelper.ShowNormalTip("当前没有帮会领地，无法进行资金管理。")
    end
end

function UIWidgetFactionManagementMoney:OnReset()
	local arr = self.m.tEditValArr
	for i = 1, #arr do
		arr[i] = 0
	end
	self:UpdateList()
	self:UpdateBtn()
end

function UIWidgetFactionManagementMoney:RegEvent()	
	Event.Reg(self, "UPDATE_TONG_INFO_FINISH", function ()		
		self:InitUI()
	end)
	Event.Reg(self, "TONG_EVENT_NOTIFY", function ()
		if arg0 == TONG_EVENT_CODE.MODIFY_INTRODUCTION_SUCCESS 
		or arg0 == TONG_EVENT_CODE.ILLEGAL_TONG_INFO
		then
			GetTongClient().ApplyTongInfo()
		end
	end)

end

function UIWidgetFactionManagementMoney:UnRegEvent()
	Event.UnRegAll(self)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetFactionManagementMoney:RequestData()

    local tong = GetTongClient()
    local nGroupID = tong.GetGroupID(g_pClientPlayer.dwID)
	self.m.bCanMeModifyGroupWage = TongData.CheckBaseOperationGroup(nGroupID, 25) -- 管理资金	
	if self.m.bCanMeModifyGroupWage and (true or tong.GetTechNodeLevel(47) > 0 or GetServerType() == SERVER_TYPE.PVP) then
		self.m.bCanModifyRepair = true
	end	

	--GetTongClient().ApplyTongInfo()
	local tDataArr = TongData.GetGroupInfo()
	self.m.tDataArr = tDataArr

	-- 为了弹出修改成功提示
	self:CheckChangeSuccess()

	-- 
	local tEditValArr = {}
	for i, tData in ipairs(tDataArr) do
		table.insert(tEditValArr, tData.nRepair)
	end
	self.m.tEditValArr = tEditValArr
end

function UIWidgetFactionManagementMoney:InitUI()
	self:RequestData()

	self:UpdateList()
	self:UpdateBtn()
end

function UIWidgetFactionManagementMoney:UpdateList()
	local list = self.ScrollViewMemberInformation
	assert(list)
	local tDataArr = self.m.tDataArr
	
	local tWidgetAnchorList = UIHelper.GetChildren(list)
	for idx, tWidgetAnchor in ipairs(tWidgetAnchorList) do
        local tChildCellList = UIHelper.GetChildren(tWidgetAnchor)
        local bShouldShow = false
        
        for idxChild, cell in ipairs(tChildCellList) do
            -- 第一个元素是img，跳过
            if idxChild ~= 1 then
                local i = (idx - 1) * 2 + idxChild - 1

                local tData = tDataArr[i]
                if tData and tData.bEnable then
                    self:UpdateCell(cell, i)
                    UIHelper.SetVisible(cell, true)
                    bShouldShow = true
                else
                    UIHelper.SetVisible(cell, false)
                end
            end
        end
        
        UIHelper.SetVisible(tWidgetAnchor, bShouldShow)
	end

	UIHelper.ScrollViewDoLayout(list)	
	UIHelper.ScrollToTop(list, 0)

end

local _CellChildNameArr = {
	"LabelPermissions",
	"LabelPermissionsNum",
	"EditBox",
    "EditArrangeMoney",
    "LayoutMoneyNoPermission",
    "LabelMoneyNoPermission",
}
local _tCellChilds = {}
function UIWidgetFactionManagementMoney:UpdateCell(cell, nIndex)
	local tData = self.m.tDataArr[nIndex]
	assert(tData)
	UIHelper.FindNodeByNameArr(cell, _tCellChilds, _CellChildNameArr)

	-- 头衔
	UIHelper.SetString(_tCellChilds.LabelPermissions, g2u(tData.szName))
	-- 人数
	UIHelper.SetString(_tCellChilds.LabelPermissionsNum, tData.nNumber)
	
    -- 可用资金
    local nMaxUsableMoney = self.m.tEditValArr[nIndex]
	UIHelper.SetString(_tCellChilds.EditBox, nMaxUsableMoney)
    UIHelper.SetMaxLength(_tCellChilds.EditBox, 6)
    UIHelper.SetString(_tCellChilds.LabelMoneyNoPermission, nMaxUsableMoney)
    
    local bEnableEdit = self.m.bCanModifyRepair == true and TongData.IsDemesnePurchased()
    _tCellChilds.EditBox:setTouchEnabled(bEnableEdit)
    
    UIHelper.SetVisible(_tCellChilds.EditArrangeMoney, bEnableEdit)
    UIHelper.SetVisible(_tCellChilds.LayoutMoneyNoPermission,  not bEnableEdit)
    
    UIHelper.LayoutDoLayout(_tCellChilds.LayoutMoneyNoPermission)

	-- 编辑事件
	if self.m.bCanModifyRepair then
		local box = _tCellChilds.EditBox
        
        local fnOnUpdateCellEditBox = function()
            local nCount = tonumber(UIHelper.GetString(box)) or 0
            if nCount > 999999 then
                nCount = 999999
            end

            UIHelper.SetString(box, tostring(nCount))
            self.m.tEditValArr[nIndex] = nCount
            self:UpdateBtn()
        end
        
		UIHelper.RegisterEditBoxEnded(box, function()
            fnOnUpdateCellEditBox()
		end)

        Event.Reg(cell, EventType.OnGameNumKeyboardChanged, function(editbox, num)
            if editbox ~= box then return end

            fnOnUpdateCellEditBox()
        end)
	end

end

function UIWidgetFactionManagementMoney:UpdateBtn()
	-- 确认
	if self.m.bCanModifyRepair then
		UIHelper.SetVisible(self.BtnConfirm, true)
		UIHelper.SetVisible(self.BtnCancel, true)

		local bChanged = false
		for i, v in ipairs(self.m.tEditValArr) do
			local tData = self.m.tDataArr[i]
			if tData.nRepair ~= v then
				bChanged = true
				break
			end
		end
		UIHelper.SetEnable(self.BtnConfirm, bChanged)
		UIHelper.SetNodeGray(self.BtnConfirm, not bChanged, true)	
	else
		UIHelper.SetVisible(self.BtnConfirm, false)
		UIHelper.SetVisible(self.BtnCancel, false)
	end	
end

function UIWidgetFactionManagementMoney:CheckChangeSuccess()
	local arr = self.m.tEditValArr
	if arr and self.m.bChangeCommit then
		local bSuccess = true
		for i = 1, #arr do
			local tData = self.m.tDataArr[i]
			if arr[i] ~= tData.nRepair then
				bSuccess = false
				break
			end
		end
		if bSuccess then
			OutputMessage("MSG_SYS", g_tStrings.STR_TONG_MONEY_SET_SUCCEED)			
		end
	end
	self.m.bChangeCommit = false
end


return UIWidgetFactionManagementMoney