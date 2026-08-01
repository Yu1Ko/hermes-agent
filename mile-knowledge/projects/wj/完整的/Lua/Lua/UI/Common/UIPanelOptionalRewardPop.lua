-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelOptionalRewardPop
-- Date: 2023-11-06 14:27:07
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelOptionalRewardPop = class("UIPanelOptionalRewardPop")

function UIPanelOptionalRewardPop:OnEnter(szContent, tbItemList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szContent = szContent
    self.tbItemList = tbItemList
    self:UpdateInfo()
end

function UIPanelOptionalRewardPop:OnExit()
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelOptionalRewardPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    -- UIHelper.BindUIEvent(self.BtnReceive, EventType.OnClick, function()
    --     RemoteCallToServer("On_Mobile_ChooseItem", self.nCurIndex)
    --     UIMgr.Close(self)
    -- end)
end

function UIPanelOptionalRewardPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelOptionalRewardPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelOptionalRewardPop:UpdateInfo()

    local tbItemList = self.tbItemList
    self.tbScript = {}
    for nIndex, tbItemInfo in ipairs(tbItemList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.ScrollViewReward)
        script:OnInitWithTabID(tbItemInfo[1], tbItemInfo[2])
        script:SetToggleGroupIndex(ToggleGroupIndex.BagItem)
        script:SetSelectChangeCallback(function(nItemID, bSelected, nTabType, nTabID)
            if bSelected then 
                -- self.nCurIndex = nIndex
                local tip, scriptTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, script._rootNode, TipsLayoutDir.AUTO)
                local tbFunctions = {
                    {
                        szName = g_tStrings.EXTERIOR_GET_FROM_ITEM_BTN,
                        OnClick = function()
                            RemoteCallToServer("On_Mobile_ChooseItem", nIndex)
                            UIMgr.Close(self)
                        end
                    }
                }
                scriptTip:SetFunctionButtons(tbFunctions)
                scriptTip:OnInitWithTabID(nTabType, nTabID)
            end
        end)
        table.insert(self.tbScript, script)
    end
    -- self.tbScript[1]:SetSelected(true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewReward)

    local szContent = UIHelper.GBKToUTF8(self.szContent)
    UIHelper.SetString(self.LabelPart1, szContent)

    local nContent = UIHelper.GetUtf8Len(szContent)
    UIHelper.SetHorizontalAlignment(self.LabelPart1, nContent > 25 and 0 or 1)
end


return UIPanelOptionalRewardPop