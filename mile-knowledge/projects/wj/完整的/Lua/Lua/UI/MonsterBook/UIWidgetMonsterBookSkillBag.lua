local UIWidgetMonsterBookSkillBag = class("UIWidgetMonsterBookSkillBag")

function UIWidgetMonsterBookSkillBag:OnEnter(dwSkillID, nLevel, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwSkillID = dwSkillID
    self.nLevel = nLevel
    self.fCallBack = fCallBack
    self:UpdateInfo()
end

function UIWidgetMonsterBookSkillBag:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookSkillBag:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBlock, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCloseLeft, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UIWidgetMonsterBookSkillBag:RegEvent()
    Event.Reg(self, "BAG_ITEM_UPDATE", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_UPDATE_SKILL_COLLECTION", function ()
        self:UpdateInfo()
    end)
end

function UIWidgetMonsterBookSkillBag:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookSkillBag:UpdateInfo()
    local tSkillCollected = g_pClientPlayer.GetAllSkillInCollection()
    self.nLevel = tSkillCollected[self.dwSkillID] or 0

    UIHelper.RemoveAllChildren(self.LayoutContentBag)
    UIHelper.RemoveAllChildren(self.WidgetCard)

    self.scriptItemTips = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetCard)
    UIHelper.SetVisible(self.WidgetCard, false)
    local tPackageIndex = {
		INVENTORY_INDEX.PACKAGE,
		INVENTORY_INDEX.PACKAGE1,
		INVENTORY_INDEX.PACKAGE2,
		INVENTORY_INDEX.PACKAGE3,
		INVENTORY_INDEX.PACKAGE4,
		INVENTORY_INDEX.PACKAGE_MIBAO,
	}
    local tIndex = tPackageIndex
    local player = g_pClientPlayer
    local bIsEmpty = true
	for _ , dwBox2 in pairs(tIndex) do
		local nSize = player.GetBoxSize(dwBox2) - 1
	       for dwX2 = 0, nSize, 1 do
			local item = ItemData.GetPlayerItem(player, dwBox2, dwX2)
			if item then
                local bCommon = item.dwIndex == 45845 and self.nLevel < 3 or 
                    item.dwIndex == 50769 and self.nLevel == 3 or
                    item.dwIndex == 66154 and self.nLevel == 4 or
                    (item.dwIndex == 75452 and self.nLevel < 8 and self.nLevel > 4)
                local bSpecial = MonsterBookData.CanUpgradeSkillByItem(self.dwSkillID, self.nLevel, item)
                if bCommon or bSpecial then
                    local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetBaiZhanSkillYaoJueCell, self.ScrollViewBag)
                    scriptItem:OnEnter(item, function () -- 点击按钮
                        self.fCallBack(item, dwBox2, dwX2)
                    end,function () -- 点击图标
                        UIHelper.SetVisible(self.WidgetCard, true)
                        self.scriptItemTips:OnInitWithTabID(item.dwTabType, item.dwIndex)
                    end)
                    bIsEmpty = false
                end
			end
		end
	end

    UIHelper.SetVisible(self.WidgetEmpty, bIsEmpty)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBag)
end

return UIWidgetMonsterBookSkillBag