-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerAccessoryItem
-- Date: 2023-11-20 20:27:42
-- Desc: 侠客-外观条目
-- Prefab: WidgetPartnerAccessoryItem
-- ---------------------------------------------------------------------------------

---@class UIPartnerAccessoryItem
local UIPartnerAccessoryItem = class("UIPartnerAccessoryItem")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerAccessoryItem:_LuaBindList()
    -- 公共
    self.LabelItemName = self.LabelItemName --- 外观的名称
    self.ImgSelect     = self.ImgSelect --- 当前预览的外观高亮框图片（包含未点击预览时的初始已装备外观的情况）
    self.ImgEquipped   = self.ImgEquipped --- 当前侠客已装备的外观打个勾

    -- 仅成衣
    self.WidgetItem    = self.WidgetItem --- 道具预制挂载点

    -- 仅发型
    self.TogHair       = self.TogHair --- 头发的toggle
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerAccessoryItem:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html
    ---@class COIN_SHOP_GOODS_TYPE 商城商品类型
    ---@field HAIR number 头发
    ---@field EXTERIOR number 外装

    ---@class PreviewNpcExteriorInfo 预览外观信息
    ---@field nSource number 外观来源，枚举参考 NPC_EXTERIOR_SOURCE_TYPE
    ---@field tData PreviewNpcExteriorDataNpcHave | PreviewNpcExteriorDataPlayerGoodsHair | PreviewNpcExteriorDataPlayerGoodsChest | PreviewNpcExteriorDataPlayerItem 外观数据，不同来源和类型的数据格式可能不同

    ---@class PreviewNpcExteriorDataNpcHave 外观数据-侠客衣橱
    ---@field dwType number 外观类型，枚举参考 NPC_EXTERIOR_TYPE
    ---@field dwID number 头发ID 或 外观ID
    ---@field szName string 名称

    ---@class PreviewNpcExteriorDataPlayerGoodsHair 外观数据-我的外观-头发
    ---@field dwType number | "COIN_SHOP_GOODS_TYPE.HAIR" 外观类型，固定为头发
    ---@field dwID number 头发ID
    ---@field szName string 名称

    ---@class PreviewNpcExteriorDataPlayerGoodsChest 外观数据-我的外观-成衣
    ---@field dwType number | "COIN_SHOP_GOODS_TYPE.EXTERIOR" 外观类型，固定为成衣
    ---@field tSub number[] 成衣包含的外观ID列表
    ---@field szName string 名称

    ---@class PreviewNpcExteriorDataPlayerItem 外观数据-我的背包
    ---@field dwType number 道具的 TabType
    ---@field dwID number 道具的实例ID
    ---@field szName string 名称
end

---@param nIndex number 在列表中的序号
---@param tExteriorInfo NpcExteriorInfo 外观信息
---@param tUIPartnerAccessoryView UIPartnerAccessoryView 侠客外观界面
function UIPartnerAccessoryItem:OnEnter(nIndex, tExteriorInfo, tUIPartnerAccessoryView)
    self.nIndex                  = nIndex
    self.tExteriorInfo           = tExteriorInfo
    self.tUIPartnerAccessoryView = tUIPartnerAccessoryView

    --- 是否是当前装备的外观
    self.bEquipped               = self:IsCurrentExteriorInEquippedList()

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
    self:UpdateDownloadEquipRes()
end

function UIPartnerAccessoryItem:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end
end

function UIPartnerAccessoryItem:BindUIEvent()

end

function UIPartnerAccessoryItem:RegEvent()
    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        self:UpdateDownloadEquipRes()
        -- local dwPartnerID = self.tUIPartnerAccessoryView.dwID
        -- local tSettlementList = self.tUIPartnerAccessoryView.tSettlementList
        -- self.tUIPartnerAccessoryView:UpdatePartnerExterior(dwPartnerID, tSettlementList)
    end)
end

function UIPartnerAccessoryItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerAccessoryItem:UpdateInfo()
    local nSource  = self.tExteriorInfo.nSource
    local tData    = self.tExteriorInfo.tData

    local bIsChest = tData.nType == NPC_EXTERIOR_TYPE.CHEST

    -- 名称
    local szName   = ""
    ---@type UIItemIcon 道具组件
    local widgetItem
    -- 外观ID，若非nil，则用于替换道具上面的图标
    local dwExteriorID

    if bIsChest then
        UIHelper.RemoveAllChildren(self.WidgetItem)
        widgetItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)

        -- 由于侠客衣橱和我的外观并不是真的道具，这里先填个假道具来占位，并移除其图片
        widgetItem:OnInitWithTabID(5, 3)
        UIHelper.SetTexture(widgetItem.ImgIcon, "")
    end

    if nSource == NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE then
        -- 侠客衣橱
        szName = tData.szName

        if tData.nType == NPC_EXTERIOR_TYPE.HAIR then
            -- todo: 确认下头发的图片怎么显示
        elseif tData.nType == NPC_EXTERIOR_TYPE.CHEST then
            dwExteriorID = tData.dwID
        end
    elseif nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_GOODS then
        -- 我的外观
        szName = tData.szName

        if tData.nType == NPC_EXTERIOR_TYPE.HAIR then
            -- todo: 确认下头发的图片怎么显示
        elseif tData.nType == NPC_EXTERIOR_TYPE.CHEST then
            if not table_is_empty(tData.tSub) then
                --- 这里假设tSub只有一个元素，看 ExteriorBox.txt 配置表中的配置，应该是符合假设的
                dwExteriorID = tData.tSub[1]
            end
        end
    elseif nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_ITEM then
        -- 我的背包
        szName = UIHelper.GBKToUTF8(tData.pItem.szName)

        if bIsChest then
            local pItem = tData.pItem
            widgetItem:OnInitWithTabID(pItem.dwTabType, pItem.dwIndex)
        end
    end

    -- 更新名称
    if bIsChest then
        szName = UIHelper.TruncateStringReturnOnlyResult(szName, 4)
    end
    UIHelper.SetString(self.LabelItemName, szName)

    -- 设置装备和选中状态
    UIHelper.SetVisible(self.ImgEquipped, self.bEquipped)
    UIHelper.SetVisible(self.ImgSelect, self:IsCurrentExteriorInPreviewList())

    if bIsChest then
        -- 成衣
        widgetItem:SetClickNotSelected(true)

        UIHelper.SetToggleGroupIndex(widgetItem.ToggleSelect, ToggleGroupIndex.PartnerExteriorItem)
        widgetItem:SetClickCallback(function(nItemType, nItemIndex)
            self:OnClickCurrentItem()
        end)

        if dwExteriorID then
            UIHelper.SetVisible(widgetItem.ImgIcon, true)

            local tInfo = GetExterior().GetExteriorInfo(dwExteriorID)
            UIHelper.SetItemIconByIconID(widgetItem.ImgIcon, tInfo.nIconID)
        end
    else
        -- 发型
        UIHelper.SetToggleGroupIndex(self.TogHair, ToggleGroupIndex.PartnerExteriorItem)
        UIHelper.BindUIEvent(self.TogHair, EventType.OnClick, function()
            self:OnClickCurrentItem()
        end)
    end
end

function UIPartnerAccessoryItem:OnClickCurrentItem()
    -- 当点击时高亮当前选择的，并隐藏其他的
    for _, uiExteriorItem in ipairs(UIHelper.GetChildren(self.tUIPartnerAccessoryView.ScrollViewExteriorList)) do
        local uiExteriorItemScript = UIHelper.GetBindScript(uiExteriorItem) ---@type UIPartnerAccessoryItem

        local bSelected
        if uiExteriorItemScript.nIndex == self.nIndex then
            -- 当前的反转状态
            bSelected = not UIHelper.GetVisible(uiExteriorItemScript.ImgSelect)
        else
            -- 其他的设为未选中
            bSelected = false
        end
        UIHelper.SetVisible(uiExteriorItemScript.ImgSelect, bSelected)
    end

    if UIHelper.GetVisible(self.ImgSelect) then
        -- 预览对应外观
        self:PreviewCurrentExterior()
    else
        self:RevertPreviewExteriorToEquipped()
    end

    -- 更新下下面的按钮的状态
    self.tUIPartnerAccessoryView:UpdateBtnList()
end

function UIPartnerAccessoryItem:PreviewCurrentExterior()
    local nSource       = self.tExteriorInfo.nSource
    local tExteriorData = self.tExteriorInfo.tData

    local nType         = tExteriorData.nType

    local tData         = {}

    if nSource == NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE or nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_GOODS then
        if nSource == NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE then
            tData = {
                dwType = nType,
                dwID = tExteriorData.dwID,
            }
        elseif nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_GOODS then
            if nType == NPC_EXTERIOR_TYPE.HAIR then
                tData = {
                    dwType = COIN_SHOP_GOODS_TYPE.HAIR,
                    dwID = tExteriorData.nHairID,
                }
            elseif nType == NPC_EXTERIOR_TYPE.CHEST then
                tData = {
                    dwType = COIN_SHOP_GOODS_TYPE.EXTERIOR,
                    tSub = tExteriorData.tSub,
                }
            end
        end

        tData.szName = tExteriorData.szName
    elseif nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_ITEM then
        local pItem = tExteriorData.pItem
        tData       = {
            dwType = pItem.dwTabType,
            dwID = pItem.dwID,
            szName = UIHelper.GBKToUTF8(pItem.szName),
        }
    end

    ---@type PreviewNpcExteriorInfo
    local tInfo = {
        nSource = nSource,
        tData = tData,
    }

    self.tUIPartnerAccessoryView:SetSettlementExterior(nType, tInfo)
end

function UIPartnerAccessoryItem:RevertPreviewExteriorToEquipped()
    self.tUIPartnerAccessoryView:RevertPreviewExteriorToEquipped()

    -- 特殊处理下侠客衣橱，如果回滚后是身上穿着的，则把对应条目给点亮
    if self.tExteriorInfo.nSource == NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE then
        local tNewPreviewInfo = self.tUIPartnerAccessoryView.tSettlementList[self.tExteriorInfo.tData.nType]
        local nNewExteriorId  = tNewPreviewInfo.tData.dwID

        for _, uiExteriorItem in ipairs(UIHelper.GetChildren(self.tUIPartnerAccessoryView.ScrollViewExteriorList)) do
            local uiExteriorItemScript = UIHelper.GetBindScript(uiExteriorItem) ---@type UIPartnerAccessoryItem
            local nExteriorId          = uiExteriorItemScript.tExteriorInfo.tData.dwID

            if nExteriorId == nNewExteriorId then
                UIHelper.SetVisible(uiExteriorItemScript.ImgSelect, true)
            end
        end
    end
end

function UIPartnerAccessoryItem:IsCurrentExteriorInEquippedList()
    return self:_IsCurrentExteriorIn(self.tUIPartnerAccessoryView.tEquippedList)
end

function UIPartnerAccessoryItem:IsCurrentExteriorInPreviewList()
    return self:_IsCurrentExteriorIn(self.tUIPartnerAccessoryView.tSettlementList)
end

function UIPartnerAccessoryItem:_IsCurrentExteriorIn(tTargetExteriorMap)
    if not tTargetExteriorMap then
        return false
    end

    local nSource              = self.tExteriorInfo.nSource
    local nType                = self.tExteriorInfo.tData.nType

    local tCurrentExteriorInfo = self.tExteriorInfo.tData

    local tSettlement          = tTargetExteriorMap[nType]
    if not tSettlement then
        return false
    end
    if tSettlement.nSource == nSource then
        local tPreviewData = tSettlement.tData
        if nSource == NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE then
            return tCurrentExteriorInfo.dwID == tPreviewData.dwID
        elseif nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_GOODS then
            if nType == NPC_EXTERIOR_TYPE.HAIR then
                return tCurrentExteriorInfo.nHairID == tPreviewData.dwID
            elseif nType == NPC_EXTERIOR_TYPE.CHEST then
                return IsTableEqual(tCurrentExteriorInfo.tSub, tPreviewData.tSub)
            end
        elseif nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_ITEM then
            local pItem = tCurrentExteriorInfo.pItem
            return pItem.dwTabType == tPreviewData.dwType and pItem.dwID == tPreviewData.dwID
        end
    end
    return false
end

function UIPartnerAccessoryItem:UpdateDownloadEquipRes()
    if not PakDownloadMgr.IsEnabled() then
        return
    end

    local nSource       = self.tExteriorInfo.nSource
    local tExteriorData = self.tExteriorInfo.tData

    local nType         = tExteriorData.nType

    local tData         = {}

    if nSource == NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE then
        tData = {
            dwType = nType,
            dwID = tExteriorData.dwID,
        }
    elseif nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_GOODS then
        if nType == NPC_EXTERIOR_TYPE.HAIR then
            tData = {
                dwType = COIN_SHOP_GOODS_TYPE.HAIR,
                dwID = tExteriorData.nHairID,
            }
        elseif nType == NPC_EXTERIOR_TYPE.CHEST then
            tData = {
                dwType = COIN_SHOP_GOODS_TYPE.EXTERIOR,
                tSub = tExteriorData.tSub,
            }
        end
    elseif nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_ITEM then
        local pItem = tExteriorData.pItem
        tData       = {
            dwType = pItem.dwTabType,
            dwID = pItem.dwID,
        }
    end

    local tInfo        = {
        nSource = nSource,
        tData = tData,
    }

    local tRepresentID = {}
    for i = 0, EQUIPMENT_REPRESENT.TOTAL - 1 do
        tRepresentID[i] = 0
    end
    local dwPartnerID = self.tUIPartnerAccessoryView.dwID
    local tNpcModel   = Partner_GetNpcModelInfo(dwPartnerID)
    local nRoleType   = tNpcModel.nRoleType

    PartnerExterior.UpdateRepresentID(tRepresentID, nType, tInfo)
    local tEquipList, tEquipSfxList          = PakEquipResData.GetRepresentPakResource(nRoleType, 0, tRepresentID)
    local tConfig                            = {}
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    local scriptMask                         = UIHelper.GetBindScript(self.WidgetDownloadShell)
    scriptMask:SetShowCondition(function()
        return UIHelper.GetVisible(self.ImgSelect)
    end)
    scriptMask:SetInfo(self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

return UIPartnerAccessoryItem