-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerConfirmationView
-- Date: 2024-02-18 17:24:17
-- Desc: 添加侠客外观确认界面
-- Prefab: PanelPartnerConfirmation
-- ---------------------------------------------------------------------------------

---@class UIPartnerConfirmationView
local UIPartnerConfirmationView = class("UIPartnerConfirmationView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerConfirmationView:_LuaBindList()
    self.WidgetItem    = self.WidgetItem --- 道具组件
    self.LabelItemName = self.LabelItemName --- 名称
    self.LabelItemHint = self.LabelItemHint --- 来源信息
    self.RichTextHint  = self.RichTextHint --- 添加提示

    self.BtnCancel     = self.BtnCancel --- 取消
    self.BtnOk         = self.BtnOk --- 确认
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerConfirmationView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

---@param tSettlementList table<number, PreviewNpcExteriorInfo>
---@param tEquippedList table<number, PreviewNpcExteriorInfo>
function UIPartnerConfirmationView:OnEnter(dwPartnerID, tSettlementList, tEquippedList)
    self.dwPartnerID     = dwPartnerID
    self.tSettlementList = tSettlementList
    self.tEquippedList   = tEquippedList

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerConfirmationView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerConfirmationView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function()
        self:AddExteriorToPartner()
        Event.Dispatch("ADD_PARTNER_EXTERIOR_CLOSED")

        UIMgr.Close(self)
    end)
end

function UIPartnerConfirmationView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPartnerConfirmationView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerConfirmationView:UpdateInfo()
    local dwPartnerID     = self.dwPartnerID
    local tSettlementList = self.tSettlementList

    local tPartnerInfo    = Table_GetPartnerNpcInfo(dwPartnerID)
    local szPartnerName   = UIHelper.GBKToUTF8(tPartnerInfo.szName)

    local szTip           = string.format(
            "你确定要将以上外观添加到%s的衣橱吗？\n<color=#FF7676>（添加后，可取回到我的外观，不可再回到我的背包中。）</color>",
            szPartnerName
    )

    -- 由于手游版中切页时会重置，这里必定最多只有一个变动的
    local szItemName      = ""
    local szItemHint      = ""
    for nType, tInfo in pairs(tSettlementList) do
        local nSource = tInfo.nSource
        if nSource ~= NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE then
            szItemName, szItemHint = self:GetNameAndHint(nType, tInfo)

            UIHelper.SetString(self.LabelItemName, szItemName)
            UIHelper.SetString(self.LabelItemHint, szItemHint)

            self:UpdateIcon(tInfo)
        end
    end

    UIHelper.SetRichText(self.RichTextHint, szTip)
end

---@param tInfo PreviewNpcExteriorInfo
function UIPartnerConfirmationView:GetNameAndHint(nType, tInfo)
    local tData = tInfo.tData
    if not tData then
        return "", ""
    end

    local szItemName = ""
    local szItemHint = ""

    local nSource    = tInfo.nSource
    local szName     = tData.szName

    -- 名称
    local szNameTip  = szName
    if nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_ITEM then
        local dwID  = tData.dwID
        local pItem = GetItem(dwID)

        if pItem then
            local szBindType
            if pItem.bBind then
                szBindType = g_tStrings.STR_PARTNER_EXTERIOR_BIND
            else
                szBindType = g_tStrings.STR_PARTNER_EXTERIOR_NOT_BIND
            end

            szNameTip = szNameTip .. string.format("(%s)", szBindType)
        end
    end
    szItemName        = szNameTip

    -- 来源
    local szSourceTip = g_tStrings.STR_PARTNER_EXTERIOR_SOURCE[nSource]
    szItemHint        = szSourceTip

    -- 备注
    local szRemarkTip
    if nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_ITEM then
        local dwID  = tData.dwID
        local pItem = GetItem(dwID)

        if pItem then
            if not pItem.bBind then
                szRemarkTip = "未绑定道具，请谨慎操作"
            end
        end
    end
    if szRemarkTip then
        szItemHint = szItemHint .. "（" .. szRemarkTip .. "）"
    end

    return szItemName, szItemHint
end

function UIPartnerConfirmationView:AddExteriorToPartner()
    local tSettlement = self.tSettlementList

    -- 直接保存的（侠客衣橱）
    local tSaveList   = {}
    for nType, tInfo in pairs(tSettlement) do
        if tInfo.nSource == NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE then
            local v         = tInfo.tData
            local bEquipped = v.dwID == self.tEquippedList[nType].tData.dwID
            if not bEquipped then
                local tData     = tInfo.tData
                local tSaveInfo = { eType = nType, dwID = tData.dwID }
                table.insert(tSaveList, tSaveInfo)
            end
        end
    end

    -- 需要购买（转换）的（从 我的外观 我的背包 转换到 侠客衣橱）
    local tBuyList = {}
    for nType, tInfo in pairs(tSettlement) do
        local nSource = tInfo.nSource
        if nSource ~= NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE then
            local tData = tInfo.tData

            local tBuyInfo
            if nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_GOODS then
                if nType == NPC_EXTERIOR_TYPE.HAIR then
                    tBuyInfo = { dwSource = nSource, dwType = tData.dwType, dwID = tData.dwID }
                elseif nType == NPC_EXTERIOR_TYPE.CHEST then
                    tBuyInfo = { dwSource = nSource, dwType = tData.dwType, dwID = tData.tSub[1] }
                end
            elseif nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_ITEM then
                local dwID  = tData.dwID
                local pItem = GetItem(dwID)
                if pItem then
                    tBuyInfo = { dwSource = nSource, dwType = pItem.dwTabType, dwID = pItem.dwIndex }
                else
                    local szMsg = g_tStrings.STR_PARTNER_EXTERIOR_CHANGE_TIP[NPC_EXTERIOR_ERROR_CODE.FAILED]
                    OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
                    return
                end
            end
            if tBuyInfo then
                table.insert(tBuyList, tBuyInfo)
            end
        end
    end

    -- 实际进行转换
    self:BuyNpcExterior(tSaveList, tBuyList)
end

function UIPartnerConfirmationView:BuyNpcExterior(tSave, tBuy)
    local hNpcExteriorMgr = GetNpcExteriorManager()
    if not hNpcExteriorMgr then
        return
    end

    local dwPartnerID    = self.dwPartnerID
    local nRetCode

    local fnCheckRetCode = function()
        if nRetCode and nRetCode ~= NPC_EXTERIOR_ERROR_CODE.SUCCESS then
            local szMsg = Partner_GetChangeExteriorFailTip(nRetCode, dwPartnerID)
            OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        end
    end

    if #tSave > 0 then
        nRetCode = hNpcExteriorMgr.Save(tSave, dwPartnerID)
        fnCheckRetCode()
    end
    if #tBuy > 0 then
        nRetCode = hNpcExteriorMgr.Buy(tBuy, dwPartnerID, true)
        fnCheckRetCode()
    end
end

---@param tInfo PreviewNpcExteriorInfo
function UIPartnerConfirmationView:UpdateIcon(tInfo)
    local nSource = tInfo.nSource
    local tData   = tInfo.tData

    if nSource == NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE then
        -- 仅处理右边两个来源
        return
    end

    ---@type UIItemIcon
    local widgetItem = UIHelper.GetBindScript(self.WidgetItem)

    widgetItem:OnInitWithTabID(5, 3)
    UIHelper.SetTexture(widgetItem.ImgIcon, "")

    local dwExteriorID
    local bUseDefaultHairIcon = false

    if nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_GOODS then
        -- 我的外观
        if tData.dwType == COIN_SHOP_GOODS_TYPE.HAIR then
            bUseDefaultHairIcon = true
        elseif tData.dwType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
            if not table_is_empty(tData.tSub) then
                --- 这里假设tSub只有一个元素，看 ExteriorBox.txt 配置表中的配置，应该是符合假设的
                dwExteriorID = tData.tSub[1]
            end
        end
    elseif nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_ITEM then
        -- 我的背包
        local dwID  = tData.dwID
        local pItem = GetItem(dwID)
        widgetItem:OnInitWithTabID(pItem.dwTabType, pItem.dwIndex)
    end

    widgetItem:SetClickNotSelected(true)

    if dwExteriorID then
        UIHelper.SetVisible(widgetItem.ImgIcon, true)

        local tExteriorInfo = GetExterior().GetExteriorInfo(dwExteriorID)
        UIHelper.SetItemIconByIconID(widgetItem.ImgIcon, tExteriorInfo.nIconID)
    elseif bUseDefaultHairIcon then
        UIHelper.SetVisible(widgetItem.ImgIcon, true)
        UIHelper.SetTexture(widgetItem.ImgIcon, "Resource/icon/armor/Hairstyle/item_19_7_15_7.png")
    end
end

return UIPartnerConfirmationView