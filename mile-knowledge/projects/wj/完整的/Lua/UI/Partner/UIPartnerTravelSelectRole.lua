-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerTravelSelectRole
-- Date: 2025-02-13 16:32:54
-- Desc: 侠客出行设置 选择侠客侧面板
-- Prefab: WidgetPartnerTravelSelectRole
-- ---------------------------------------------------------------------------------

---@class UIPartnerTravelSelectRole
local UIPartnerTravelSelectRole = class("UIPartnerTravelSelectRole")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerTravelSelectRole:_LuaBindList()
    self.BtnCloseLeft       = self.BtnCloseLeft --- 关闭侧面板按钮
    self.LabelTitle         = self.LabelTitle --- 标题
    self.ScrollViewLeftCard = self.ScrollViewLeftCard --- 侠客列表的scroll view
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerTravelSelectRole:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIPartnerTravelSelectRole:OnEnter(nQuestID, tSelectedPartnerIDList, bNeedSelectFirstNPartner)
    self.nQuestID               = nQuestID
    self.tSelectedPartnerIDList = tSelectedPartnerIDList
    self.bNeedSelectFirstNPartner = bNeedSelectFirstNPartner

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        
        FilterDef.TravelPartner.Reset()
        
        self.bInit = true
    end
    
    self:UpdateInfo()
end

function UIPartnerTravelSelectRole:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerTravelSelectRole:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseLeft, EventType.OnClick, function()
        UIHelper.RemoveFromParent(self._rootNode, true)
    end)
end

function UIPartnerTravelSelectRole:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if szKey ~= FilterDef.TravelPartner.Key then
            return
        end
        
        local tShowPartnerList = self:GetFilteredPartnerIDList(tbInfo)

        self:UpdatePartnerListInfo(tShowPartnerList)

        Event.Dispatch("PartnerTravelSetting_UpdateSelectedPartnerIDList", self:GetSelectedPartnerIDList())
    end)
end

function UIPartnerTravelSelectRole:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerTravelSelectRole:UpdateInfo()
    local tList = Partner_GetAllPartnerList()
    self:UpdatePartnerListInfo(tList)
    
    self:UpdateTitle()
end

---@param tList PartnerNpcInfo[]
function UIPartnerTravelSelectRole:UpdatePartnerListInfo(tList)
    UIHelper.RemoveAllChildren(self.ScrollViewLeftCard)

    ---@type table<number, UIRoleItem>
    self.tPartnerIdToRoleScript = {}

    local tQuest                = Table_GetPartnerTravelTask(self.nQuestID)
    local tPartnerQualityList   = StringParse_IDList(tQuest.szPartnerQuality)
    
    self:SortPartnerList(tList)
    
    local nSelectFirstN = 0
    if self.bNeedSelectFirstNPartner then
        nSelectFirstN = tQuest.nNeedPartnerNum
    end

    for idx, tInfo in ipairs(tList) do
        if not tInfo.bTryOut and table.contain_value(tPartnerQualityList, tInfo.nQuality) then
            ---@type UIRoleItem
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetRoleItem, self.ScrollViewLeftCard)
            script:OnEnter(tInfo)

            self.tPartnerIdToRoleScript[tInfo.dwID] = script

            --- 调整一些元素
            UIHelper.SetVisible(script.ImgMark, false)
            UIHelper.SetVisible(script.LayoutInfo, false)
            UIHelper.SetVisible(script.LabelCostTime, tInfo.bHave)
            UIHelper.SetVisible(script.WidgetNewItem, false)

            local fOrigDiscount = GDAPI_HeroTravelTimeDisCount(tInfo.dwID, self.nQuestID, tInfo.nQuality)
            local szTime        = self:FormatHourTime(math.ceil(tQuest.nTime * (1 - fOrigDiscount)) * 60 / 3600)

            UIHelper.SetString(script.LabelCostTime, string.format("时长减%s", szTime))

            local bInTravel = PartnerData.IsPartnerInTravel(tInfo.dwID)
            local nPartnerTravelStatus = PartnerData.GetPartnerTravelStatus(tInfo.dwID)
            UIHelper.SetVisible(script.ImgInArranged, tInfo.bHave and nPartnerTravelStatus == PARTNER_TRAVEL_TYPE.ARRANGED)
            UIHelper.SetVisible(script.ImgInTravel, tInfo.bHave and nPartnerTravelStatus == PARTNER_TRAVEL_TYPE.INTRAVEL)

            local bEnable = tInfo.bHave and not bInTravel
            UIHelper.SetEnable(script.ToggleCurrentSelect, bEnable)

            if tQuest.nNeedPartnerNum == 1 then
                --- 如果只需要一个侠客，则设置为单选模式
                UIHelper.SetToggleGroupIndex(script.ToggleCurrentSelect, ToggleGroupIndex.PartnerTravelPartner)
            end

            UIHelper.BindUIEvent(script.ToggleCurrentSelect, EventType.OnClick, function()
                self:OnClickPartner(tInfo.dwID)
            end)

            if bEnable then
                local bDefaultSelect = false
                if table.get_len(self.tSelectedPartnerIDList) > 0 then
                    bDefaultSelect = table.contain_value(self.tSelectedPartnerIDList, tInfo.dwID)
                else
                    if nSelectFirstN > 0 then
                        bDefaultSelect = true
                        nSelectFirstN = nSelectFirstN - 1
                    end
                end

                if bDefaultSelect then
                    UIHelper.SetSelected(script.ToggleCurrentSelect, true)
                    self:OnClickPartner(tInfo.dwID)
                end
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLeftCard)
end

---@param tPartnerList PartnerNpcInfo[]
function UIPartnerTravelSelectRole:SortPartnerList(tPartnerList)
    -- 排序顺序: 是否已拥有>未出行空闲>未出行已安排>已出行>等级(仅已拥有时有)>稀有度>id

    local nPriorityInTravel  = 1
    local nPriorityArranged  = 2
    local nPriorityFree      = 3

    local function fnInTravelPriority(dwID)
        local nStatus = PartnerData.GetPartnerTravelStatus(dwID)

        if nStatus == PARTNER_TRAVEL_TYPE.INTRAVEL then
            return nPriorityInTravel
        elseif nStatus == PARTNER_TRAVEL_TYPE.ARRANGED then
            return nPriorityArranged
        else
            return nPriorityFree
        end
    end

    ---@param tNpcInfo1 PartnerNpcInfo
    ---@param tNpcInfo2 PartnerNpcInfo
    local function fnSort(tNpcInfo1, tNpcInfo2)
        if tNpcInfo1.bHave ~= tNpcInfo2.bHave then
            return tNpcInfo1.bHave
        end

        local nPriority1 = fnInTravelPriority(tNpcInfo1.dwID)
        local nPriority2 = fnInTravelPriority(tNpcInfo2.dwID)
        if nPriority1 ~= nPriority2 then
            return nPriority1 > nPriority2
        end

        if tNpcInfo1.bHave then
            if tNpcInfo1.nLevel ~= tNpcInfo2.nLevel then
                return tNpcInfo1.nLevel > tNpcInfo2.nLevel
            end
        end

        local nQuality1 = tNpcInfo1.nQuality or 0
        local nQuality2 = tNpcInfo2.nQuality or 0
        if nQuality1 ~= nQuality2 then
            return nQuality1 > nQuality2
        end

        return tNpcInfo1.dwID < tNpcInfo2.dwID
    end

    table.sort(tPartnerList, fnSort)
end

function UIPartnerTravelSelectRole:FormatHourTime(fTime)
    local szTime = string.format("%.1f小时", fTime)
    if fTime == math.floor(fTime) then
        szTime = string.format("%.0f小时", fTime)
    end

    return szTime
end

function UIPartnerTravelSelectRole:OnClickPartner(dwPartnerID)
    local script    = self.tPartnerIdToRoleScript[dwPartnerID]

    local bSelected = UIHelper.GetSelected(script.ToggleCurrentSelect)
    if bSelected then
        local nSelectedCount = #self:GetSelectedPartnerIDList()
        local tQuest         = Table_GetPartnerTravelTask(self.nQuestID)

        if nSelectedCount > tQuest.nNeedPartnerNum then
            TipsHelper.ShowNormalTip(string.format("最多可选择%d位侠客", tQuest.nNeedPartnerNum))
            UIHelper.SetSelected(script.ToggleCurrentSelect, false)
        end
    end
    
    self:UpdateTitle()

    Event.Dispatch("PartnerTravelSetting_UpdateSelectedPartnerIDList", self:GetSelectedPartnerIDList())
end

---@return number[]
function UIPartnerTravelSelectRole:GetSelectedPartnerIDList()
    local tIDList = {}

    for _, child in ipairs(UIHelper.GetChildren(self.ScrollViewLeftCard)) do
        ---@type UIRoleItem
        local script = UIHelper.GetBindScript(child)

        if UIHelper.GetSelected(script.ToggleCurrentSelect) then
            table.insert(tIDList, script.tInfo.dwID)
        end
    end

    return tIDList
end

function UIPartnerTravelSelectRole:UpdateTitle()
    local tHeroList = self:GetSelectedPartnerIDList()
    local tQuest                = Table_GetPartnerTravelTask(self.nQuestID)
    
    UIHelper.SetString(self.LabelTitle, string.format("选择需要派遣的侠客（%d/%d）", table.get_len(tHeroList), tQuest.nNeedPartnerNum))
end

--- 筛选项 - 获取途径
--- nID => PartnerNpcInfo.txt nFilterWay
local tFilterWay = {
    { nID = 1, szName = "家园", },
    { nID = 2, szName = "喝茶结交", },
    { nID = 3, szName = "活动", },
    { nID = 4, szName = "名望", },
}

function UIPartnerTravelSelectRole:GetFilteredPartnerIDList(tbInfo)
    local tSelectedWayInfoList = {}

    for _, nIndex in ipairs(tbInfo[1]) do
        local tInfo = tFilterWay[nIndex]
        table.insert(tSelectedWayInfoList, tInfo)
    end

    local bHasFilter       = #tSelectedWayInfoList ~= 0

    local tShowPartnerList = {}

    local tAllPartnerList  = Partner_GetAllPartnerList()
    if tAllPartnerList then
        for _, tInfo in ipairs(tAllPartnerList) do
            local bShow = true
            if bHasFilter then
                bShow = false

                --- 获取途径
                for _, tFilterInfo in ipairs(tSelectedWayInfoList) do
                    if tInfo.nFilterWay == tFilterInfo.nID then
                        bShow = true
                        break
                    end
                end
            end

            if bShow then
                table.insert(tShowPartnerList, tInfo)
            end
        end
    end

    return tShowPartnerList
end

return UIPartnerTravelSelectRole