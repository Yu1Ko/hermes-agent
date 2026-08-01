-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerDetailsSkillUpLeftPop
-- Date: 2023-04-04 15:34:50
-- Desc: 侠客-武学境界左侧栏
-- Prefab: WidgetPartnerDetailsSkillUpLeftPop
-- ---------------------------------------------------------------------------------

local UIPartnerDetailsSkillUpLeftPop = class("UIPartnerDetailsSkillUpLeftPop")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerDetailsSkillUpLeftPop:_LuaBindList()
    self.LabelTitle                       = self.LabelTitle --- 境界标题

    self.WidgetSkillItem                  = self.WidgetSkillItem --- 技能组件
    self.LabelSkillName                   = self.LabelSkillName --- 技能名称
    self.LabelSkillType                   = self.LabelSkillType --- 技能类型
    self.LabelSkillDescribe               = self.LabelSkillDescribe --- 技能描述

    self.WidgetItem                       = self.WidgetItem --- 领悟消耗的道具组件
    self.LabelNum                         = self.LabelNum --- 道具拥有数目/需要的数目
    self.WidgetConsumption                = self.WidgetConsumption --- 消耗道具区域的组件

    self.BtnBreak                         = self.BtnBreak --- 领悟按钮
    self.LabelActivated                   = self.LabelActivated --- 已激活时的提示
    self.LabelNeedActivateLowerStageFirst = self.LabelNeedActivateLowerStageFirst --- 需要先激活之前的境界的提示

    self.BtnMask                          = self.BtnMask --- 左侧栏的遮罩按钮，点击后隐藏
    self.BtnCloseLeft                     = self.BtnCloseLeft --- 关闭按钮，点击后隐藏侧边栏

    self.WidgetBreak                      = self.WidgetBreak --- 赠送领悟道具或需激活前面境界的上层组件
end

function UIPartnerDetailsSkillUpLeftPop:OnEnter(dwID, nStage, dwPlayerID)
    self.dwID       = dwID
    self.nStage     = nStage
    self.dwPlayerID = dwPlayerID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerDetailsSkillUpLeftPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerDetailsSkillUpLeftPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBreak, EventType.OnClick, function()
        self:HeroBreak()
    end)
end

function UIPartnerDetailsSkillUpLeftPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nResultCode, dwID)
        if dwID ~= self.dwID then
            return
        end

        if nResultCode == NPC_ASSISTED_RESULT_CODE.ASSISTED_STAGE_POINT_CHANGE then
            self:UpdateInfo()
        elseif nResultCode == NPC_ASSISTED_RESULT_CODE.ASSISTED_STAGE_CHANGE then
            self:UpdateInfo()
        end
    end)
end

function UIPartnerDetailsSkillUpLeftPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerDetailsSkillUpLeftPop:UpdateInfo()
    local dwID           = self.dwID

    local tStageInfoList = Table_GetPartnerStageInfo(dwID)
    local tStageInfo
    for _, tLine in ipairs(tStageInfoList) do
        if tLine.nStage == self.nStage then
            tStageInfo = tLine
            break
        end
    end

    if not tStageInfo then
        return
    end

    local nStage                 = tStageInfo.nStage
    local dwSkillID, nSkillLevel = tStageInfo.dwSkillID, tStageInfo.nLevel

    local tPartnerInfo           = Partner_GetPartnerInfo(dwID, self.dwPlayerID)
    local nPartnerStage          = 0
    if tPartnerInfo then
        nPartnerStage = tPartnerInfo.nStage
    end

    local szTitle       = g_tStrings.STR_PARTNER_STAGE_TITLE[nStage] .. "   " .. UIHelper.GBKToUTF8(tStageInfo.szTitle)

    local szSkillName   = Table_GetSkillName(dwSkillID, nSkillLevel)
    szSkillName         = UIHelper.GBKToUTF8(szSkillName)

    -- todo: 技能类型似乎固定是这个
    local szSkillType   = "被动招式"

    local szDescription = Table_GetSkillDesc(dwSkillID, nSkillLevel)
    szDescription       = UIHelper.GBKToUTF8(szDescription)

    UIHelper.SetString(self.LabelTitle, szTitle)
    UIHelper.SetString(self.LabelSkillName, szSkillName)
    UIHelper.SetString(self.LabelSkillType, szSkillType)
    UIHelper.SetString(self.LabelSkillDescribe, szDescription)

    UIHelper.RemoveAllChildren(self.WidgetSkillItem)
    local uiScript = UIMgr.AddPrefab(PREFAB_ID.WidgetSkillCell, self.WidgetSkillItem, dwSkillID, nSkillLevel)
    UIHelper.SetAnchorPoint(uiScript._rootNode, 0.5, 0.5)

    local bShowGiftItem = nStage == nPartnerStage + 1

    UIHelper.SetVisible(self.WidgetConsumption, bShowGiftItem)

    UIHelper.SetVisible(self.LabelActivated, nStage <= nPartnerStage)
    UIHelper.SetVisible(self.BtnBreak, nStage == nPartnerStage + 1)
    UIHelper.SetVisible(self.LabelNeedActivateLowerStageFirst, nStage > nPartnerStage + 1)

    if tPartnerInfo == nil then
        UIHelper.SetEnable(self.BtnBreak, false)
        UIHelper.SetNodeGray(self.BtnBreak, true, true)
    end

    if nStage <= nPartnerStage then
        -- 已解锁
    elseif nStage == nPartnerStage + 1 then
        -- 下一级
        local bHasEnoughItem = false

        local tGiftInfo      = Table_GetPartnerGiftInfo(dwID)
        for _, tLine in ipairs(tGiftInfo) do
            local nType                     = tLine.nType
            local dwIndex                   = tLine.dwIndex
            local nItemCount                = ItemData.GetItemAmountInPackage(nType, dwIndex)

            self.nGiftType, self.nGiftIndex = nType, dwIndex

            UIHelper.RemoveAllChildren(self.WidgetItem)
            local widgetItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
            widgetItem:OnInitWithTabID(nType, dwIndex)
            widgetItem:SetClickCallback(function(nItemType, nItemIndex)
                Timer.AddFrame(self, 1, function()
                    TipsHelper.ShowItemTips(widgetItem._rootNode, nType, dwIndex, false)
                end)
            end)

            local nNeed = 1
            UIHelper.SetString(self.LabelNum, string.format("%d/%d", nItemCount, nNeed))

            bHasEnoughItem = bHasEnoughItem or nItemCount >= nNeed
        end

        if not bHasEnoughItem then
            UIHelper.SetEnable(self.BtnBreak, false)
            UIHelper.SetNodeGray(self.BtnBreak, true, true)
        end
    else
        -- 更高未解锁的境界
        local nPreviousStage = nStage - 1
        for _, tLine in ipairs(tStageInfoList) do
            if tLine.nStage == nPreviousStage then
                local szPreviousTitle = g_tStrings.STR_PARTNER_STAGE_TITLE[nPreviousStage] .. "   " .. UIHelper.GBKToUTF8(tLine.szTitle)
                UIHelper.SetString(self.LabelNeedActivateLowerStageFirst,
                                   string.format(
                                           "需先激活%s·%s",
                                           g_tStrings.STR_PARTNER_STAGE_TITLE[nPreviousStage], UIHelper.GBKToUTF8(tLine.szTitle)
                                   )
                )
                break
            end
        end
    end

    self:InitOtherPlayerSettings()
end

function UIPartnerDetailsSkillUpLeftPop:HeroBreak()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.OPERATE_DIAMOND) then
        return
    end

    local dwID           = self.dwID
    local nType, dwIndex = self.nGiftType, self.nGiftIndex
    if not nType or not dwIndex then
        return
    end
    local tCostItemInfo = { nType, dwIndex, 1 }
    RemoteCallToServer("On_Hero_Break", dwID, tCostItemInfo)
end

function UIPartnerDetailsSkillUpLeftPop:InitOtherPlayerSettings()
    -- 如果是查看他人的侠客，则隐藏部分组件
    if Partner_IsSelfPlayer(self.dwPlayerID) then
        return
    end

    UIHelper.SetVisible(self.WidgetConsumption, false)
    UIHelper.SetVisible(self.WidgetBreak, false)

end

return UIPartnerDetailsSkillUpLeftPop