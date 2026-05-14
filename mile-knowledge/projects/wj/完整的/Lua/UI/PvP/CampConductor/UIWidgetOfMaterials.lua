-- ---------------------------------------------------------------------------------
-- Name: UIWidgetOfMaterials
-- Desc: 阵营指挥管理--物资管理分页
-- Prefab:PanelCampConductor--WidgetContentMaterials
-- ---------------------------------------------------------------------------------

local UIWidgetOfMaterials = class("UIWidgetOfMaterials")

local Role2Img = {
	[0] = "UIAtlas2_Pvp_CampConductor_PvpCore_img_zhuzhihui",
	[1] = "UIAtlas2_Pvp_CampConductor_PvpCore_img_fuguan",
	[2] = "UIAtlas2_Pvp_CampConductor_PvpCore_img_diaoduguan",
	[3] = "UIAtlas2_Pvp_CampConductor_PvpCore_img_fuzhihui",
}


function UIWidgetOfMaterials:_LuaBindList()
    self.LabelPlayerStatus    = self.LabelPlayerStatus --- 玩家权限总指挥、副指挥
    self.BtnAddFunds          = self.BtnAddFunds --- 追加资金

    self.LabelMoney_Jin       = self.LabelMoney_Jin --- jin数字
    self.LabelMoney_Zhuan     = self.LabelMoney_Zhuan --- jinzhuan数字

    self.LayouttMaterialsManagement  = self.LayouttMaterialsManagement --- 加载物资cell的layout WidgetCampMaterialCell
end

function UIWidgetOfMaterials:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
		self:InitCell()
        self.bInit = true
    end
end

function UIWidgetOfMaterials:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetOfMaterials:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnAddFunds, EventType.OnClick, function()
		UIMgr.Open(VIEW_ID.PanelCampFundsDonatePop)
    end)
end

function UIWidgetOfMaterials:RegEvent()
    
end

function UIWidgetOfMaterials:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetOfMaterials:SetMaterialsCallback(func)
	self.func = func
end

function UIWidgetOfMaterials:ShowMaterialsTips(nIndex)
    if not self.scriptMaterialsTip then
        self.scriptMaterialsTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTip)
    end
    self.scriptMaterialsTip:OnInitConductorMaterialsTip(nIndex, self.bHaveRight)
	UIHelper.SetVisible(self.scriptMaterialsTip._rootNode, true)
end

function UIWidgetOfMaterials:HideMaterialsTips()
	if not self.scriptMaterialsTip then
        return false
    end 
	UIHelper.SetVisible(self.scriptMaterialsTip._rootNode, false)
end

function UIWidgetOfMaterials:GetMaterialsTips()
	if not self.scriptMaterialsTip then
        return false
    end 
	return UIHelper.GetVisible(self.scriptMaterialsTip._rootNode)
end

function UIWidgetOfMaterials:InitCell()
	if not self.tscriptItem then
		self.tscriptItem = {}
		UIHelper.RemoveAllChildren(self.LayouttMaterialsManagement)
	end
	for i = 1, 3 do
		self:GetCellScript(i)
	end
	UIHelper.LayoutDoLayout(self.LayouttMaterialsManagement)
	UIHelper.CascadeDoLayoutDoWidget(self.WidgetMaterialsManagement, true, true)
end

function UIWidgetOfMaterials:GetCellScript(nIndex)
    if #self.tscriptItem < nIndex then
        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetCampMaterialCell, self.LayouttMaterialsManagement)
		assert(scriptItem)
        table.insert(self.tscriptItem, scriptItem)
    end
    return self.tscriptItem[nIndex]
end

function UIWidgetOfMaterials:InitPermissionInfo()
    local nRoleType = CommandBaseData.GetRoleType()
	local nRoleLevel = CommandBaseData.GetRoleLevel()

	if nRoleType == COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER then
        UIHelper.SetString(self.LabelPlayerStatus, g_tStrings.STR_COMMAND_PRIORITY_COMMANDER)
		UIHelper.SetSpriteFrame(self.ImgStatus, Role2Img[0])
		self.bHaveRight = true
		-- szTips = g_tStrings.STR_COMMAND_PRIORITY_COMMANDER_TIP
	elseif nRoleType == COMMAND_MODE_PLAYER_ROLE.VICE_COMMANDER then
		-- szTips = g_tStrings["STR_COMMAND_PRIORITY"..nRoleLevel.."_TIP"]
        UIHelper.SetString(self.LabelPlayerStatus, g_tStrings["STR_COMMAND_PRIORITY"..nRoleLevel])
		UIHelper.SetSpriteFrame(self.ImgStatus, Role2Img[nRoleLevel])
		if nRoleLevel < 3 then
			self.bHaveRight = false
		else
			self.bHaveRight = true
		end
	end
end

function UIWidgetOfMaterials:InitMoneyInfo(nMoney)
	CommandBaseData.SetMoney(nMoney)
    local nGoldB, nGold = ConvertGoldToGBrick(nMoney)
    UIHelper.SetString(self.LabelMoney_Zhuan, nGoldB)
    UIHelper.SetString(self.LabelMoney_Jin, nGold)
	UIHelper.CascadeDoLayoutDoWidget(self.LayoutCampFunds, true, true)
end

function UIWidgetOfMaterials:InitMaterialsInfo()
	-- i 为服务端物资信息块索引 
	-- 0: 攻防资金；
	-- 1：摧城车总购买个数；    2：已经分配的摧城车数；
	-- 3：小车总购买个数；      4：已经分配的小车数；
	-- 5：箭塔钥匙总购买个数；  6：已经分配的箭塔钥匙数；
	-- 7：制导器总购买个数；    8：已经分配的制导器数；
	-- 9: 摧城车今日使用数量;
    local tGoodsCountInfo = {}
	local CP = GetCampPlantManager()
	for i = 0, 9 do
		table.insert(tGoodsCountInfo, CP.GetCustomData (0, i))
	end

    self:InitMoneyInfo(tGoodsCountInfo[1])
    
	for nIndex = 1, 3 do
		CommandBaseData.tGoodsSetting[nIndex] = {}
		CommandBaseData.tGoodsSetting[nIndex].nBuy = tGoodsCountInfo[2*nIndex]
		CommandBaseData.tGoodsSetting[nIndex].nAllot = tGoodsCountInfo[2*nIndex + 1]
		if nIndex == 1 then
			CommandBaseData.tGoodsSetting[nIndex].nUse =  tGoodsCountInfo[10]
		end
		if not self.tscriptItem or not self.tscriptItem[nIndex] then
			self:InitCell()
			self.tscriptItem[nIndex]:UpdateCell(nIndex)
			self.tscriptItem[nIndex]:SetMaterialsCallback(function(nIndex)
				self:ShowMaterialsTips(nIndex)
			end)
		else
			self.tscriptItem[nIndex]:UpdateCell(nIndex)
			self.tscriptItem[nIndex]:SetMaterialsCallback(function(nIndex)
				self:ShowMaterialsTips(nIndex)
			end)
		end
	end
end

function UIWidgetOfMaterials:UpdateInfo()
	self:InitPermissionInfo()
	self:InitMaterialsInfo()
	self:SetAddBtnRights()
end

function UIWidgetOfMaterials:SetAddBtnRights()
    if CommandBaseData.GetRoleType() == COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER then
        UIHelper.SetButtonState(self.BtnRemovePlayer, BTN_STATE.Normal)
    else
        local nRoleLevel = CommandBaseData.GetRoleLevel()
        if nRoleLevel == 1 then
			UIHelper.SetButtonState(self.BtnAddFunds, BTN_STATE.Disable, g_tStrings["STR_COMMAND_PRIORITY".. nRoleLevel .."_TIP"])
        else
			UIHelper.SetButtonState(self.BtnAddFunds, BTN_STATE.Normal)
        end
	end
end

return UIWidgetOfMaterials