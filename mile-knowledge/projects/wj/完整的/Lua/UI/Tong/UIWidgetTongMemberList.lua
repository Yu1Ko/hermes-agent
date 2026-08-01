-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetTongMemberList
-- Date: 2023-01-06
-- Desc: 帮会成员列表
-- Prefab: WidgetFactionManagementMember
-- ---------------------------------------------------------------------------------

-- 按钮序号和排序类型的对应关系，需要确保 tTitleBtnList 中的按钮顺序与这里定义的一致
local tBtnIndexToSortType    = {
    --- 名字
    [1] = TongData.tbSortType.Name,
    --- 等级
    [2] = TongData.tbSortType.Level,
    ----- 门派
    --[3] = TongData.tbSortType.School,
    ----- 头衔
    --[4] = TongData.tbSortType.Group,

    --- 装备分数
    [5] = TongData.tbSortType.Score,
    --- 战阶积分
    [6] = TongData.tbSortType.TitlePoint,
    --- 所在地
    [7] = TongData.tbSortType.Map,

    --- 上次在线
    [8] = TongData.tbSortType.LastOfflineTime,
    --- 入帮时间
    [9] = TongData.tbSortType.JoinTime,
    --- 备注
    [10] = TongData.tbSortType.Remark,
}

-- 按钮序号和筛选类型的对应关系，需要确保 tTitleBtnList 中的按钮顺序与这里定义的一致
local tBtnIndexToFilterType  = {
    --- 门派
    [3] = TongData.tMemberFilterType.School,
    --- 头衔
    [4] = TongData.tMemberFilterType.Group,
}

local UIWidgetTongMemberList = class("UIWidgetTongMemberList")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIWidgetTongMemberList:_LuaBindList()
    self.LabelFactionPrepare                    = self.LabelFactionPrepare --- 帮会筹备期的提示

    self.tTitleBtnList                          = self.tTitleBtnList --- 标题按钮列表
    self.BtnScreen                              = self.BtnScreen --- 筛选按钮

    self.ImgTitleSortBg                         = self.ImgTitleSortBg --- 排序图标
    self.tTitleLabelList                        = self.tTitleLabelList --- 标题label列表

    self.WidgetFilterSchool                     = self.WidgetFilterSchool --- 门派 - 筛选组件
    self.ScrollviewFilterSchool                 = self.ScrollviewFilterSchool --- 门派 - 筛选 scroll view
    self.WidgetFilterGroup                      = self.WidgetFilterGroup --- 头衔 - 筛选组件
    self.ScrollviewFilterGroup                  = self.ScrollviewFilterGroup --- 头衔 - 筛选 scroll view

    self.BtnCloseFilterSchool                   = self.BtnCloseFilterSchool --- 门派 - 关闭筛选组件
    self.BtnCloseFilterGroup                    = self.BtnCloseFilterGroup --- 头衔 - 关闭筛选组件

    self.ScrollViewMemberInformation            = self.ScrollViewMemberInformation --- 已废弃
    self.TableViewMemberInfo                    = self.TableViewMemberInfo --- 成员信息列表的table view
    self.TableViewMask                          = self.TableViewMask --- 成员信息列表的table view mask
    self.WidgetFactionManagementMemberPlayerPop = self.WidgetFactionManagementMemberPlayerPop --- 成员弹窗挂载点

    self.BtnSwitched                            = self.BtnSwitched --- 切换右侧3列的按钮
    self.WidgetSwitchedTitle01                  = self.WidgetSwitchedTitle01 --- 切换列1
    self.WidgetSwitchedTitle02                  = self.WidgetSwitchedTitle02 --- 切换列2
end

local g2u = UIHelper.GBKToUTF8
local u2g = UIHelper.UTF8ToGBK

function UIWidgetTongMemberList:Init()
    self.m                = {}
    self.m.szSortType     = TongData.tbSortType.Group
    self.m.bSortRiseOrder = false
    self.m.nGroupFilter   = -1
    self.m.nSchoolFilter  = -1
    self.m.nPorpertyMode  = 0

    --- 为了避免性能压力，这里与dx保持一致，默认不显示离线成员
    self.m.bShowOfflineMember = false

    self:RegEvent()
    self:BindUIEvent()

    self:InitUI()
end

function UIWidgetTongMemberList:UnInit()
    self:UnRegEvent()
    UIHelper.RemoveFromParent(self._rootNode, true)
    self.m = nil
end

function UIWidgetTongMemberList:OnShow()
    --- 初始化右侧部分为默认值
    self.m.nPorpertyMode = 0

    self:InitUI()
    TongData.ApplyTongRoster()
end

function UIWidgetTongMemberList:BindUIEvent()
    UIHelper.BindUIEvent(self.TogHelp, EventType.OnClick, function()
        UIHelper.SetTouchLikeTips(self.WidgetHelpTips, self._rootNode, function()
            UIHelper.SetSelected(self.TogHelp, false)
        end)
    end)
    UIHelper.BindUIEvent(self.TogDisplay, EventType.OnClick, function()
        self.m.bShowOfflineMember = not self.m.bShowOfflineMember
        UIHelper.SetSelected(self.TogDisplay, self.m.bShowOfflineMember)
        self:UpdateList()
    end)
    UIHelper.BindUIEvent(self.BtnSwitched, EventType.OnClick, function()
        self.m.nPorpertyMode = self.m.nPorpertyMode == 0 and 1 or 0

        UIHelper.SetVisible(self.WidgetSwitchedTitle01, self.m.nPorpertyMode == 0)
        UIHelper.SetVisible(self.WidgetSwitchedTitle02, self.m.nPorpertyMode == 1)

        self:UpdateList()
    end)

    UIHelper.BindUIEvent(self.BtnQuitFaction, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "Tong") then
            return
        end

        -- 若是帮主
        local dwMyID = g_pClientPlayer.dwID
        local tong   = GetTongClient()
        if dwMyID == tong.dwMaster then
            local tTips = g_tStrings.STR_GUILD_ERROR[TONG_EVENT_CODE.QUIT_IS_MASTER_ERROR]
            TipsHelper.OutputMessage(tTips[2], tTips[1])
            return

        elseif dwMyID == tong.dwNextMaster then
            TipsHelper.OutputMessage("MSG_ANNOUNCE_NORMAL", "你正在被转交成为新帮主，无法退出帮会。")
            return

        end

        UIHelper.ShowConfirm("确定退出帮会吗?", function()
            TongData.Quit()
        end)
    end)

    for idx, tBtn in ipairs(self.tTitleBtnList) do
        local tLabel     = self.tTitleLabelList[idx]

        local szSortType = tBtnIndexToSortType[idx]
        if szSortType ~= nil then
            -- 排序
            self:SetBtnSortImgOpacity(tBtn, 70, 70)

            UIHelper.BindUIEvent(tBtn, EventType.OnClick, function()
                local szOldSortType = self.m.szSortType

                self.m.szSortType   = szSortType

                if szSortType == szOldSortType then
                    self.m.bSortRiseOrder = not self.m.bSortRiseOrder
                end

                self:UpdateSortIconState(tBtn, tLabel, idx)

                -- 点击排序时隐藏可能存在的筛选框
                self:UpdateWidgetFilter(idx)

                self:UpdateList()
            end)
        end

        local nFilterType = tBtnIndexToFilterType[idx]
        if nFilterType ~= nil then
            self:InitFilter(tBtn, idx)
        end
    end

    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelFactionManagementFilterScreen, TongData.tFilterScreenType.Member, nil, nil, function(nSchoolFilter, nGroupFilter)
            self.m.nSchoolFilter = nSchoolFilter
            self.m.nGroupFilter  = nGroupFilter

            self:UpdateList()
        end)
    end)

    UIHelper.BindUIEvent(self.BtnCloseFilterSchool, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetFilterSchool, false)
    end)

    UIHelper.BindUIEvent(self.BtnCloseFilterGroup, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetFilterGroup, false)
    end)

    UIHelper.TableView_addCellAtIndexCallback(self.TableViewMemberInfo, function(tableView, nIndex, script, node, cell)
        local nID = self.tShowMemberList[nIndex]
        local tData = TongData.GetMemberInfo(nID)
        assert(tData, "fail to GetMemberInfo: " .. nID)

        self:UpdateCell(nIndex, node, tData)
    end)
end

function UIWidgetTongMemberList:RegEvent()
    Event.Reg(self, "UPDATE_TONG_ROSTER_FINISH", function()
        self:InitUI()
    end)
    Event.Reg(self, "TONG_MEMBER_JOIN", function()
        TongData.RequestBaseData()
    end)
    Event.Reg(self, "TONG_EVENT_NOTIFY", function()
        if arg0 == TONG_EVENT_CODE.INVITE_SUCCESS
                or arg0 == TONG_EVENT_CODE.KICK_OUT_SUCCESS
                or arg0 == TONG_EVENT_CODE.CHANGE_MEMBER_REMARK_SUCCESS
                or arg0 == TONG_EVENT_CODE.CHANGE_MEMBER_GROUP_SUCCESS
        then
            TongData.RequestBaseData()
        end
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        self:UpdateList()
    end)
end

function UIWidgetTongMemberList:UnRegEvent()
    Event.UnRegAll(self)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTongMemberList:InitUI()
    local tong = GetTongClient()

    UIHelper.SetSelected(self.TogDisplay, self.m.bShowOfflineMember)
    local nTotal, nOnline = TongData.GetMemberCount()
    UIHelper.SetRichText(self.LabelMemderNum, string.format("%d/%d", nOnline, nTotal))
    UIHelper.SetRichText(self.LabelProbationaryMemderNum, string.format("%d/%d", 0, 0)) -- ????

    local dwMyID = g_pClientPlayer.dwID
    UIHelper.SetNodeGray(self.BtnQuitFaction, dwMyID == tong.dwMaster or dwMyID == tong.dwNextMaster, true)

    UIHelper.SetVisible(self.LabelFactionTransfer, tong.dwNextMaster ~= 0)
    if tong.dwNextMaster ~= 0 then
        local tInfo = TongData.GetMemberInfo(tong.dwNextMaster)
        assert(tInfo, "fail to get member info: " .. tong.dwNextMaster)
        UIHelper.SetString(self.LabelFactionTransfer,
                           string.format("帮主转交中，将于%s后正式转交给帮会成员[%s]",
                                         TongData.GetMasterChangeLeaveTime(),
                                         g2u(tInfo.szName))
        )
    end

    UIHelper.SetVisible(self.LabelFactionPrepare, tong.nState ~= TONG_STATE.NORMAL)
    if tong.nState ~= TONG_STATE.NORMAL then
        local szTime = ""
        local nDelta = tong.GetStateTimer() - GetCurrentTime()
        if nDelta < 0 then
            nDelta = 0
        end
        local nD = math.floor(nDelta / (3600 * 24))
        if nD > 0 then
            local nL = math.floor((nDelta % (3600 * 24)) / 3600)
            szTime   = FormatString(g_tStrings.STR_GUILD_TIME_DAY_LATER, nD, nL)
        else
            local nH = math.floor(nDelta / 3600)
            if nH > 0 then
                szTime = FormatString(g_tStrings.STR_GUILD_TIME_HOUR_LATER, nH)
            else
                szTime = g_tStrings.STR_GUILD_TIME_IN_ONE_HOUR
            end
        end

        local szState = ""
        if tong.nState == TONG_STATE.TRIAL then
            szState = g_tStrings.STR_GUILD_STATE_CREATE
        elseif tong.nState == TONG_STATE.DISBAND or tong.nState == TONG_STATE.INVALID then
            szState = g_tStrings.STR_GUILD_STATE_DESTORY
        end

        local szTip = FormatString(g_tStrings.STR_GUILD_DISBAND_WARING, szState, szTime)
        UIHelper.SetString(self.LabelFactionPrepare, szTip)
    end

    -- 帮会升级
    --UIHelper.SetVisible(self.BtnFactionUpgrade, TongData.GetLevel() < TongData.GetMaxLevel())

    self:UpdateList()
end

function UIWidgetTongMemberList:UpdateList()
    self.tShowMemberList = TongData.GetMemberList(
            self.m.bShowOfflineMember,
            self.m.szSortType,
            self.m.bSortRiseOrder,
            self.m.nGroupFilter,
            self.m.nSchoolFilter)

    FellowshipData.ApplyFellowshipCard(self.tShowMemberList)

    UIHelper.TableView_init(self.TableViewMemberInfo, #self.tShowMemberList, PREFAB_ID.WidgetMemberInformation)
    UIHelper.TableView_reloadData(self.TableViewMemberInfo)
end

local _tCellFieldNameArr = {
    "BtnMemberInformation",
    "ImgPlayerIcon",
    "AnimatePlayerIcon",
    "SFXPlayerIcon",
    "WidgetText",
    "LabelMemberName",
    "LabelGrade",
    "LabelSchool",
    "LabelTitle",
    "WidgetSwitched01",
    "WidgetSwitched02",
    "BtnModifyRemark",
    "LabelEquipment",
    "LabelIntegral",
    "LabelLocation",
    "LabelLastTIme",
    "LabelJoinTime",
    "LabelRemark",
    "LabelMaster",
    "LabelTime",
    "WidgetFactionManagementMemberPlayerPop",
}
function UIWidgetTongMemberList:UpdateCell(idx, cell, tData)
    assert(cell)
    local tong  = GetTongClient()
    local tCell = {}
    UIHelper.FindNodeByNameArr(cell, tCell, _tCellFieldNameArr)

    UIHelper.SetVisible(tCell.WidgetText, false)
    -- 帮主
    if tData.dwID == tong.dwMaster then
        UIHelper.SetVisible(tCell.WidgetText, true)
        UIHelper.SetVisible(tCell.LabelMaster, true)
        UIHelper.SetVisible(tCell.LabelTime, false)
        UIHelper.SetString(tCell.LabelMaster, tong.dwNextMaster == 0 and "帮主" or "帮主转交中")
    else
        -- 预备天数
        local nTime = GetCurrentTime() - tData.nJoinTime
        nTime       = math.floor(nTime / (60 * 60 * 24))
        if nTime < 7 then
            UIHelper.SetVisible(tCell.WidgetText, true)
            UIHelper.SetVisible(tCell.LabelMaster, false)
            UIHelper.SetVisible(tCell.LabelTime, true)
            UIHelper.SetString(tCell.LabelTime, "预备期")
            UIHelper.SetTextColor(tCell.LabelTime, cc.c3b(255, 150, 150))
        end
    end

    UIHelper.SetString(tCell.LabelMemberName, UIHelper.TruncateStringReturnOnlyResult(g2u(tData.szName), 8))

    UIHelper.SetString(tCell.LabelGrade, tostring(tData.nLevel))

    UIHelper.SetString(tCell.LabelSchool, Table_GetForceName(tData.nForceID))
    local tGroup = TongData.GetGroupInfoByID(tData.nGroupID)
    UIHelper.SetString(tCell.LabelTitle, UIHelper.LimitUtf8Len(g2u(tGroup.szName), 5))

    UIHelper.SetVisible(tCell.WidgetSwitched01, self.m.nPorpertyMode == 0)
    if UIHelper.GetVisible(tCell.WidgetSwitched01) then
        UIHelper.SetString(tCell.LabelEquipment, tostring(tData.nEquipScore))
        UIHelper.SetString(tCell.LabelIntegral, tostring(tData.nTitlePoint))
        local sz = tData.bIsOnline and g2u(Table_GetMapName(tData.dwMapID)) or g_tStrings.STR_GUILD_OFFLINE
        UIHelper.SetString(tCell.LabelLocation, sz)
    end

    UIHelper.SetVisible(tCell.WidgetSwitched02, self.m.nPorpertyMode == 1)
    if UIHelper.GetVisible(tCell.WidgetSwitched02) then
        UIHelper.SetString(tCell.LabelLastTIme, TongData.GetLastOnLineTimeText(tData.nLastOfflineTime))
        UIHelper.SetString(tCell.LabelJoinTime, TongData.GetJoinTimeString(tData.nJoinTime))
        UIHelper.SetString(tCell.LabelRemark, UIHelper.LimitUtf8Len(g2u(tData.szRemark), 7))
    end

    -- 头像
    do
        local szPlayerGlobalID

        local fnUpdateAvatar = function(bUpdateIfNotExists)
            local dwMiniAvatarID = 0
            local nRoleType      = nil
            local dwForceID      = tData.nForceID

            UIHelper.RoleChange_UpdateAvatar(tCell.ImgPlayerIcon, dwMiniAvatarID, tCell.SFXPlayerIcon, tCell.AnimatePlayerIcon, nRoleType, dwForceID, true)
            UIHelper.SetNodeGray(tCell.ImgPlayerIcon, not tData.bIsOnline)
        end

        fnUpdateAvatar(true)
    end

    UIHelper.BindUIEvent(tCell.BtnMemberInformation, EventType.OnClick, function()
        ---@type UIWidgetTongMemberMenu
        local tScript = UIHelper.AddPrefab(PREFAB_ID.WidgetFactionManagementMemberPlayerPop, self.WidgetFactionManagementMemberPlayerPop)
        assert(tScript)
        tScript:Init(tData)

        -- 当弹窗在区域内时，锚点y取1；若部分在区域下方，则取0
        local nAnchorPointY                  = 1

        local nCellBottomY                   = UIHelper.GetWorldPositionY(cell)
        local nPopBottomY                    = UIHelper.GetWorldPositionY(tScript._rootNode) - UIHelper.GetHeight(tScript._rootNode)
        local nScrollViewBottomY             = UIHelper.GetWorldPositionY(self.ScrollViewMemberInformation) - UIHelper.GetHeight(self.ScrollViewMemberInformation)

        local nCellHeight                    = UIHelper.GetHeight(cell)

        local nCellTopY                      = UIHelper.GetWorldPositionY(cell) + nCellHeight
        local nScrollViewTopY                = UIHelper.GetWorldPositionY(self.ScrollViewMemberInformation)

        local nScrollViewMaxVisibleItemCount = math.floor(UIHelper.GetHeight(self.ScrollViewMemberInformation) / nCellHeight)

        local nPopTopYWhenAnchor0            = UIHelper.GetWorldPositionY(tScript._rootNode) + UIHelper.GetHeight(tScript._rootNode)

        if nPopBottomY < nScrollViewBottomY then
            -- 弹窗会在区域下方，调整锚点位置
            nAnchorPointY = 0

            if nPopTopYWhenAnchor0 > nScrollViewTopY then
                -- 如果朝上也会溢出范围，这种情况下，锚点改为0.5
                nAnchorPointY = 0.5
            end
        end

        if nCellBottomY < nScrollViewBottomY then
            -- 当点击的帮会成员信息组件部分在scroll view下方时，移动scroll view，使当前组件恰好完全在scroll view下面最后一个
            local nIndexMakeCurrentToBottom = idx + 1 - (nScrollViewMaxVisibleItemCount - 1)
            UIHelper.TableView_scrollToCell(self.TableViewMemberInfo, #self.tShowMemberList, nIndexMakeCurrentToBottom, 0)
        elseif nCellTopY > nScrollViewTopY then
            -- 当点击的帮会成员信息组件部分在scroll view上方时，移动scroll view，使当前组件恰好完全在scroll view上面第一个
            local nIndexMakeCurrentToTop = idx + 1
            UIHelper.TableView_scrollToCell(self.TableViewMemberInfo, #self.tShowMemberList, nIndexMakeCurrentToTop, 0)
        end

        UIHelper.SetAnchorPoint(tScript._rootNode, 0.5, nAnchorPointY)
    end)

    UIHelper.BindUIEvent(tCell.BtnModifyRemark, EventType.OnClick, function()
        self:OnModifyRemark(tData)
    end)

end

function UIWidgetTongMemberList:OnModifyRemark(tData)
    local tong    = GetTongClient()

    -- 条件
    local tMyInfo = TongData.GetMemberInfo(g_pClientPlayer.dwID)
    assert(tMyInfo, "fail to get member info: " .. g_pClientPlayer.dwID)
    local bOK = tMyInfo.dwID == tData.dwID or tong.CanAdvanceOperate(tMyInfo.nGroupID, tData.nGroupID, TONG_OPERATION_INDEX.MODIFY_MEMBER_REMARK)
    if not bOK then
        TipsHelper.ShowNormalTip("你无权修改该成员的备注", false)
        return
    end

    UIHelper.ShowModifyNamePanel(
            "修改备注",
            g2u(tData.szRemark) or "",
            function(sz)
                if sz then
                    tong.ChangeMemberRemark(tData.dwID, u2g(sz))
                end
            end,
            7
    )
end

--- 基于 UIPVPFieldSettleDataView:UpdateSortIconState
function UIWidgetTongMemberList:UpdateSortIconState(btn, label, nIndex)
    local nTxtPosX           = UIHelper.GetPosition(label)
    local nTxtSizeX, _       = UIHelper.GetContentSize(label)
    local nAnchX, _          = UIHelper.GetAnchorPoint(label)
    local nPosX              = nTxtPosX + nTxtSizeX * (1 - nAnchX)
    local nOffsetX, nOffsetY = 20, -2 --显示偏移
    local rotate             = 0
    if self.m.bSortRiseOrder then
        nOffsetY = -nOffsetY
        rotate   = 180
    end

    for idx, tBtn in ipairs(self.tTitleBtnList) do
        local nOpacityUp   = 70
        local nOpacityDown = 70

        if idx == nIndex then
            if self.m.bSortRiseOrder then
                nOpacityUp = 255
            else
                nOpacityDown = 255
            end
        end

        self:SetBtnSortImgOpacity(tBtn, nOpacityUp, nOpacityDown)
    end
end

function UIWidgetTongMemberList:SetBtnSortImgOpacity(tBtn, nOpacityUp, nOpacityDown)
    local tChild = {}
    UIHelper.FindNodeByNameArr(tBtn, tChild, { "ImgUp", "ImgDown" })

    UIHelper.SetOpacity(tChild.ImgUp, nOpacityUp)
    UIHelper.SetOpacity(tChild.ImgDown, nOpacityDown)
end

function UIWidgetTongMemberList:SetBtnFilterImg(tBtn, nFilter)
    local tChild = {}
    UIHelper.FindNodeByNameArr(tBtn, tChild, { "ImgScreened" })

    UIHelper.SetVisible(tChild.ImgScreened, nFilter ~= -1)
end

function UIWidgetTongMemberList:UpdateBtnFilterImgs()
    for idx, nFilterType in pairs(tBtnIndexToFilterType) do
        local tBtn = self.tTitleBtnList[idx]

        local nFilter
        if nFilterType == TongData.tMemberFilterType.School then
            nFilter = self.m.nSchoolFilter
        elseif nFilterType == TongData.tMemberFilterType.Group then
            nFilter = self.m.nGroupFilter
        end

        self:SetBtnFilterImg(tBtn, nFilter)
    end
end

--- 更新筛选框，显示当前序号对应的筛选框，并隐藏其他筛选框（ps：当点击排序按钮时，则所有筛选框因为序号不匹配，则都会被隐藏）
function UIWidgetTongMemberList:UpdateWidgetFilter(nBtnIndex)
    for idx, nOtherFilterType in pairs(tBtnIndexToFilterType) do
        local _, _, tOtherWidgetFilter = self:GetFilterParams(idx)
        UIHelper.SetVisible(tOtherWidgetFilter, idx == nBtnIndex)
    end
end

function UIWidgetTongMemberList:GetFilterList(nMemberFilterType)
    local tFilterList = {}

    local guild       = GetTongClient()
    if nMemberFilterType == TongData.tMemberFilterType.School then
        -- 门派
        local tList = Table_GetAllForceUI()
        for nForceType, v in pairs(tList) do
            table.insert(tFilterList, { szName = v.szName, nGroupIndex = nForceType })
        end
        table.sort(tFilterList, function(a, b) return a.nGroupIndex < b.nGroupIndex end)
        table.insert(tFilterList, 1, { szName = g_tStrings.STR_GUILD_ALL, nGroupIndex = TongData.nMemberFilterSchoolAll })
    else
        -- 头衔
        for i = 0, TongData.TOTAL_GROUP_CNT - 1, 1 do
            local groupInfo = guild.GetGroupInfo(i)
            if groupInfo.bEnable then
                table.insert(tFilterList, { szName = UIHelper.GBKToUTF8(groupInfo.szName), nGroupIndex = i })
            end
        end
        table.insert(tFilterList, 1, { szName = g_tStrings.STR_GUILD_ALL, nGroupIndex = TongData.nMemberFilterGroupAll })
    end

    return tFilterList
end

function UIWidgetTongMemberList:GetFilterParams(nBtnIndex)
    local nMemberFilterType = tBtnIndexToFilterType[nBtnIndex]

    local nFilter
    local tWidgetFilter
    local tScrollViewFilter
    if nMemberFilterType == TongData.tMemberFilterType.School then
        nFilter           = self.m.nSchoolFilter
        tWidgetFilter     = self.WidgetFilterSchool
        tScrollViewFilter = self.ScrollviewFilterSchool
    elseif nMemberFilterType == TongData.tMemberFilterType.Group then
        nFilter           = self.m.nGroupFilter
        tWidgetFilter     = self.WidgetFilterGroup
        tScrollViewFilter = self.ScrollviewFilterGroup
    end

    return nMemberFilterType, nFilter, tWidgetFilter, tScrollViewFilter
end

function UIWidgetTongMemberList:InitFilter(tBtn, nBtnIndex)
    local nMemberFilterType, nFilter, tWidgetFilter, tScrollViewFilter = self:GetFilterParams(nBtnIndex)

    -- 初始化筛选标记图片
    self:SetBtnFilterImg(tBtn, nFilter)

    UIHelper.BindUIEvent(tBtn, EventType.OnClick, function()
        self:UpdateWidgetFilter(nBtnIndex)

        UIHelper.RemoveAllChildren(tScrollViewFilter)

        local tFilterList = self:GetFilterList(nMemberFilterType)
        for idxFilter, tFilter in ipairs(tFilterList) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTogSchoolFilterCell, tScrollViewFilter, tFilter)
            UIHelper.SetSelected(script.Toggle, idxFilter == 1)

            UIHelper.BindUIEvent(script.Toggle, EventType.OnClick, function()
                -- note: c++接口中俩参数不能同时生效，此时先均重置
                self.m.nGroupFilter   = -1
                self.m.nSchoolFilter  = -1

                local nSelectedFilter = script:GetGroupIndex()
                if nMemberFilterType == TongData.tMemberFilterType.School then
                    self.m.nSchoolFilter = nSelectedFilter
                elseif nMemberFilterType == TongData.tMemberFilterType.Group then
                    self.m.nGroupFilter = nSelectedFilter
                end

                UIHelper.SetVisible(tWidgetFilter, false)

                self:UpdateBtnFilterImgs()
                self:UpdateList()
            end)
        end

        UIHelper.ScrollViewDoLayoutAndToTop(tScrollViewFilter)
    end)
end

return UIWidgetTongMemberList