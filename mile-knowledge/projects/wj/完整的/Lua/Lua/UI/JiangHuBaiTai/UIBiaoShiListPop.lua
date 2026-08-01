-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UIBiaoShiListPop
-- Date: 2023-09-08 14:47:59
-- Desc: PanelBiaoShiPop
-- ---------------------------------------------------------------------------------

local UIBiaoShiListPop = class("UIBiaoShiListPop")
local tbImgList = {
	[1] = "UIAtlas2_JiangHuBaiTai_JHBTIcon_JHBTBiaoShiLine",
	[2] = "UIAtlas2_JiangHuBaiTai_JHBTIcon_JHBTBiaoShiLeave"
}
function UIBiaoShiListPop:OnEnter(tGuradList)
	self:UpdateInfo(tGuradList)
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

end

function UIBiaoShiListPop:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIBiaoShiListPop:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		Event.Dispatch("ON_HIDE_WIDGETBIAOSHIPOP")
		JiangHuData.UpdateBiaoShiListBubble()
	end)

	for k, v in pairs(self.tbLiftBtnList) do
		UIHelper.BindUIEvent(self.tbLiftBtnList[k], EventType.OnClick, function()
			self:TwoConfirm(k)
		end)
	end

	
	for k, v in pairs(self.tbBtnList) do
		UIHelper.BindUIEvent(self.tbBtnList[k], EventType.OnClick, function()
			local tInfo = self.tGuradList[k]
			if UIHelper.GetVisible(self.tbContentUpList[k]) and tInfo then
				if tInfo.bHighLight then
					TipsHelper.ShowNormalTip("该镖师在你附近，可以承担伤害")
				else
					TipsHelper.ShowNormalTip("该镖师距离过远或不在队伍中，不能为你承担伤害")
				end
			end
		end)
	end

	local tbParentNode = UIHelper.GetParent(self._rootNode)
	local tbScript = UIHelper.GetBindScript(tbParentNode)
	UIHelper.BindFreeDrag(tbScript, self.BtnDrag)
end

function UIBiaoShiListPop:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIBiaoShiListPop:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBiaoShiListPop:UpdateInfo(tGuradList)
	self.tGuradList = tGuradList
	self:UpdateGurardList()
end

function UIBiaoShiListPop:UpdateGurardList()
	if not self.tGuradList then
		return
	end
	for i = 1, 4, 1 do
		local tInfo = self.tGuradList[i]
		local szName = ""
		if tInfo then
			szName = tInfo.szName

			if not szName or szName == "" then
				szName = g_tStrings.STR_JH_GUARD_FAR_TIP
				UIHelper.SetString(self.tbBiaoShiNameList[i], szName)
			else
				UIHelper.SetString(self.tbBiaoShiNameList[i], UIHelper.GBKToUTF8(szName))
			end
			UIHelper.SetVisible(self.tbContentUpList[i], true)
			UIHelper.SetVisible(self.tbContentList[i], false)

			UIHelper.SetSpriteFrame(self.tbInRangeImgList[i], tbImgList[2])	
			if tInfo.bHighLight then
				UIHelper.SetSpriteFrame(self.tbInRangeImgList[i], tbImgList[1])	
			end
		else
			UIHelper.SetVisible(self.tbContentUpList[i], false)
			UIHelper.SetVisible(self.tbContentList[i], true)
		end
	end
	UIHelper.LayoutDoLayout(self.LayoutBiaoShiList)
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBiaoShi)
end


function UIBiaoShiListPop:TwoConfirm(nIndex)
	local szMessage = nil
	if not self.tGuradList[nIndex].szName or self.tGuradList[nIndex].szName == "" then
		szMessage = string.format("你将失去该镖师的保护，确定要解除么？")
	else
		szMessage = string.format("你将失去%s的保护，确定要解除么？", UIHelper.GBKToUTF8(self.tGuradList[nIndex].szName))
	end
	local confirmDialog = UIHelper.ShowConfirm(szMessage, function ()
		RemoteCallToServer("On_Identity_CancelRelationship", self.tGuradList[nIndex].dwID, 2)
	end)
end

return UIBiaoShiListPop