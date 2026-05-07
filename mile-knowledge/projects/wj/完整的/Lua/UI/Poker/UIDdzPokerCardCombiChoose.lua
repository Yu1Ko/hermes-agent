-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIDdzPokerCardCombiChoose
-- Date: 2023-08-22 16:59:48
-- Desc: 斗地主癞子卡牌多种选项选择
-- ---------------------------------------------------------------------------------

local UIDdzPokerCardCombiChoose = class("UIDdzPokerCardCombiChoose")
local MAX_CLASS_NUM = 1
local MAX_CLASS = 1
local function CanClass(tInfo) 
	local nCount = 0
	local bFlag = false
	for k, v in pairs(tInfo) do
		nCount = nCount + 1
		if #v > MAX_CLASS_NUM then
			bFlag = true
		end
	end
	if bFlag and nCount > MAX_CLASS then
		return true
	end
	return false
end
function UIDdzPokerCardCombiChoose:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIDdzPokerCardCombiChoose:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDdzPokerCardCombiChoose:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        self:SetVisible(false)
        DdzPokerData.bLockHandCard = false
    end)

    for k, v in ipairs(self.tbToggleTab) do
        UIHelper.BindUIEvent(v , EventType.OnClick , function ()
            self:InitCardChoosePageByIndex(k)
        end)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup , v)
    end
end

function UIDdzPokerCardCombiChoose:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDdzPokerCardCombiChoose:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIDdzPokerCardCombiChoose:SetVisible(bShow)
    UIHelper.SetVisible(self._rootNode , bShow)
end

function UIDdzPokerCardCombiChoose:UpdateTimer()
    UIHelper.SetString(self.LabelCCTimer , DdzPokerData.DataModel.nDiffTime)
end

function UIDdzPokerCardCombiChoose:InitCardChoose(tInfo)
    self.curSelectObj = nil
    local bCanClass = CanClass(tInfo)
    UIHelper.SetTabVisible(self.tbToggleTab , false)
    self.tbChooseInfo = tInfo
    if bCanClass then
		for k, v in pairs(tInfo) do
			UIHelper.SetVisible(self.tbToggleTab[k] , true)
            UIHelper.SetString(UIHelper.FindChildByName(self.tbToggleTab[k], "LabelCCTabTitle") , g_tStrings.STR_DDZ_CARD_TYPE[k]) 
            UIHelper.FindChildByName(self.tbToggleTab[k], "LabelCCTabTitleChosen" , g_tStrings.STR_DDZ_CARD_TYPE[k])
		end
        UIHelper.LayoutDoLayout(self.LayoutCCTabs)
		self:InitCardChoosePageByIndex(1)
	else
		self:InitCardChoosePageByData(tInfo)
	end
end

function UIDdzPokerCardCombiChoose:InitCardChoosePageByIndex(nIndex)
    local tInfo =  self.tbChooseInfo[nIndex]
    UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup , self.tbToggleTab[nIndex])
	local tInfoItem = tInfo[nIndex]
	UIHelper.RemoveAllChildren(self.ScrollViewCCPageTab)
	for i = 1, #tInfoItem do
        local ccscript = UIHelper.AddPrefab(PREFAB_ID.WidgetCCList , self.ScrollViewCCPageTab)
        ccscript:UpdateInfo(nIndex , tInfoItem)
        ccscript:SetSelectCallback(function (selectObj)
            if self.curSelectObj then
                self.curSelectObj:SetSelectState(false)
            end
            self.curSelectObj = selectObj
            self.curSelectObj:SetSelectState(true)
            Event.Dispatch(DdzPokerData.tbEventID.OnClickCombiChoose ,  self.curSelectObj.tInfoItem)
        end)
	end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCCPageTab)
end

function UIDdzPokerCardCombiChoose:InitCardChoosePageByData(tInfo)
    UIHelper.RemoveAllChildren(self.ScrollViewCCPageTab)
	for key, tInfoItem in pairs(tInfo) do
		for j = 1, #tInfoItem do
            local ccscript = UIHelper.AddPrefab(PREFAB_ID.WidgetCCList , self.ScrollViewCCPageTab)
            ccscript:UpdateInfo(key , tInfoItem[j])
            ccscript:SetSelectCallback(function (selectObj)
                if self.curSelectObj then
                    self.curSelectObj:SetSelectState(false)
                end
                self.curSelectObj = selectObj
                self.curSelectObj:SetSelectState(true)
                Event.Dispatch(DdzPokerData.tbEventID.OnClickCombiChoose ,  self.curSelectObj.tInfoItem)
            end)
		end
	end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCCPageTab)
end


return UIDdzPokerCardCombiChoose