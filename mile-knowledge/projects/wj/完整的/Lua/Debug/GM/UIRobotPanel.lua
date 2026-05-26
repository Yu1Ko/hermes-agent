-- ---------------------------------------------------------------------------------
-- Author: zhang yin
-- Name: UIRobotPanel
-- Date: 2023-01-12 15:03:49
-- Desc: 机器人命名测试面板
-- ---------------------------------------------------------------------------------

local UIRobotPanel = class("UIRobotPanel")

function UIRobotPanel:OnEnter(tbFunction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.SetString(self.LabelDropList, SearchRobot.szControlMode)
    self.bTogBaseConfigSelected = true
    self.bTogPVPSelected = false
    self.WidgetChangeRobot:setVisible(false)
    self.tbFunction = tbFunction
    self:UpdateInfo()
end

function UIRobotPanel:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

-- 机器人控制选项
local tbRobotSelect = {
    { nKey = "Designated",  szText= "指定机器人", nChannel = PLAYER_TALK_CHANNEL.WHISPER},
    { nKey = "Vicinity",   szText ="附近机器人" , nChannel = PLAYER_TALK_CHANNEL.NEARBY},
    { nKey = "SameMap", szText = "同地图机器人" , nChannel = PLAYER_TALK_CHANNEL.SENCE},
    { nKey = "AllServer", szText = "全服机器人" , nChannel = PLAYER_TALK_CHANNEL.WORLD},
    { nKey = "SameTeam", szText = "同队机器人" , nChannel = PLAYER_TALK_CHANNEL.RAID}
}

function UIRobotPanel:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSetOK, EventType.OnClick, function (btn)
        local startRobotIndex = UIHelper.GetString(self.EditRobotIndex)
        local startRobotCount = UIHelper.GetString(self.EditRobotCount)
        local startRobotSuffixName = UIHelper.GetString(self.EditRobotName)
        if startRobotIndex ~="" and startRobotCount ~="" and startRobotSuffixName ~="" then
            -- 获取设置参数 初始化机器人列表
            UIRobotPanel:SetInitRobot(startRobotIndex, startRobotCount, startRobotSuffixName)
            local labelName = UIRobotPanel:ContatArgument()
            UIHelper.SetString(self.LabelRobotTip, labelName)
            -- Set SearchRobot的变量信息
            SearchRobot.szRobotIndex = startRobotIndex
            SearchRobot.szRobotCount = startRobotCount
            SearchRobot.szRobotSuffixName = startRobotSuffixName
            SearchRobot.szLabelTextTip = labelName
            -- UIRobotPanel:SetUnEnable(self.EditRobotIndex, self.EditRobotCount, self.EditRobotName)
        else
            UIHelper.SetString(self.LabelRobotTip,"未选择任何机器人")
        end
    end)

    UIHelper.BindUIEvent(self.BtnSetCancel, EventType.OnClick, function (btn)
        -- 清除tbRobot的值
        SearchRobot.tbRobot = {}
        SearchRobot.szRobotIndex = ""
        SearchRobot.szRobotCount = ""
        SearchRobot.szRobotSuffixName = ""
        SearchRobot.szLabelTextTip = "当前选中的机器人："
        UIHelper.SetString(self.EditRobotIndex, SearchRobot.szRobotIndex)
        UIHelper.SetString(self.EditRobotCount, SearchRobot.szRobotCount)
        UIHelper.SetString(self.EditRobotName, SearchRobot.szRobotSuffixName)
        UIHelper.SetString(self.LabelRobotTip, SearchRobot.szLabelTextTip)
        UIRobotPanel:SetEnable(self.EditRobotIndex, self.EditRobotCount, self.EditRobotName, self.BtnSetOK)
    end)

    UIHelper.BindUIEvent(self.TogDropList, EventType.OnSelectChanged, function (_, bSelected)
        self.WidgetChangeRobot:setVisible(false)
        self.ScrollViewDropList:setVisible(true)
    end)

    --机器人选项
    UIHelper.TableView_addCellAtIndexCallback(self.ScrollViewDropList, function(tableView, nIndex, script, node, cell)
        local tControlMode = tbRobotSelect[nIndex]
        script:OnEnter(tControlMode.nKey, tControlMode.szText, function (nKey, szText)
            UIHelper.SetSelected(self.TogDropList, false)
            UIHelper.SetString(self.LabelDropList, szText)
            SearchRobot.szControlMode = szText
            SearchRobot.nChannel = tControlMode.nChannel
            self:ToggleSelect(nKey)
        end)

        UIHelper.ToggleGroupAddToggle(self.ToggleGroupDropList, script.ToggleSelect)
    end)

    UIHelper.BindUIEvent(self.TogBaseConfig, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected and self.bTogBaseConfigSelected then
            OutputMessage("MSG_ANNOUNCE_RED", "机器人基础配置功能开发中！")
            -- if UIMgr.GetView(VIEW_ID.PanelRobotSecondary) then
            --     UIMgr.Close(VIEW_ID.PanelRobotSecondary)
            -- else
            --     UIMgr.Open(VIEW_ID.PanelRobotSecondary)
            -- end
        end
        self.bTogBaseConfigSelected = bSelected
        self.bTogPVPSelected = not bSelected
    end)

    UIHelper.BindUIEvent(self.TogPVP, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected and self.bTogPVPSelected then
            if UIMgr.GetView(VIEW_ID.PanelRobotSecondary) then
                UIMgr.Close(VIEW_ID.PanelRobotSecondary)
            else
                UIMgr.Open(VIEW_ID.PanelRobotSecondary, ServerRobotArena.szTitle, ServerRobotArena.tbArenaQueueSetting)
            end
        end
        self.bTogPVPSelected = bSelected
        self.bTogBaseConfigSelected  = not bSelected
    end)

    -- 旧按钮实现
    UIHelper.BindUIEvent(self.BtnCallRobot, EventType.OnClick, function (btn)
        UIRobotPanel:TeleportRobot()
    end)

    UIHelper.BindUIEvent(self.BtnStandAccord, EventType.OnClick, function (btn)
        UIRobotPanel:RnadomStandAccordToMe()
    end)

    UIHelper.BindUIEvent(self.BtnStartFollow, EventType.OnClick, function (btn)
        UIRobotPanel:StartFollow()
    end)

    UIHelper.BindUIEvent(self.BtnStopFollow, EventType.OnClick, function (btn)
        UIRobotPanel:StopFollow()
    end)

    UIHelper.BindUIEvent(self.BtnFightSetting, EventType.OnClick, function (btn)
        -- 战斗设置
        if UIMgr.GetView(VIEW_ID.PanelRobotSecondary) then
            UIMgr.Close(VIEW_ID.PanelRobotSecondary)
        else
            UIMgr.Open(VIEW_ID.PanelRobotSecondary, ServerRobotFightSettings.szTitle, ServerRobotFightSettings.tbFightSettingSetting)
        end
    end)

    UIHelper.BindUIEvent(self.BtnBuffSetting, EventType.OnClick, function (btn)
        -- 设置Buff
        if UIMgr.GetView(VIEW_ID.PanelRobotSecondary) then
            UIMgr.Close(VIEW_ID.PanelRobotSecondary)
        else
            UIMgr.Open(VIEW_ID.PanelRobotSecondary, ServerRobotBufff.szTitle, ServerRobotBufff.tbBuffSetting)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSetTeams, EventType.OnClick, function (btn)
        -- 设置队伍
        if UIMgr.GetView(VIEW_ID.PanelRobotSecondary) then
            UIMgr.Close(VIEW_ID.PanelRobotSecondary)
        else
            UIMgr.Open(VIEW_ID.PanelRobotSecondary, ServerRobotTeamManager.szTitle, ServerRobotTeamManager.tbTeamSetting)
        end
    end)


    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function (btn)
        -- send command
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAddFriend, EventType.OnClick, function (btn)
        -- send command
        self:AddFriend()
    end)

    UIHelper.BindUIEvent(self.BtnSetCampInfo, EventType.OnClick, function (btn)
        -- 设置阵营
        if UIMgr.GetView(VIEW_ID.PanelRobotSecondary) then
            UIMgr.Close(VIEW_ID.PanelRobotSecondary)
        else
            UIMgr.Open(VIEW_ID.PanelRobotSecondary, ServerRobotCampInfo.szTitle, ServerRobotCampInfo.tbCampSetting)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSetGang, EventType.OnClick, function (btn)
        -- 设置帮会
        if UIMgr.GetView(VIEW_ID.PanelRobotSecondary) then
            UIMgr.Close(VIEW_ID.PanelRobotSecondary)
        else
            UIMgr.Open(VIEW_ID.PanelRobotSecondary, ServerRobotGangManager.szTitle, ServerRobotGangManager.tbGangSetting)
        end
    end)

    UIHelper.BindUIEvent(self.BtnAIChat, EventType.OnClick, function (btn)
        -- AI Npc聊天
        if UIMgr.GetView(VIEW_ID.PanelRobotSecondary) then
            UIMgr.Close(VIEW_ID.PanelRobotSecondary)
        else
            UIMgr.Open(VIEW_ID.PanelRobotSecondary, ServerRobotAIChat.szTitle, ServerRobotAIChat.tbAIChatSetting)
        end
    end)

    UIHelper.BindUIEvent(self.BtnMovePanel, EventType.OnTouchBegan, function(btn, nX, nY)

    end)

    UIHelper.BindUIEvent(self.BtnMovePanel, EventType.OnTouchMoved, function(btn, nX, nY)
        if not self.nLastX then
            self.nLastX = nX
            self.nLastY = nY
            return
        end

        local parentNode = UIHelper.GetParent(self._rootNode)
        local parentNodeX, parentNodeY = UIHelper.GetPosition(parentNode)
        local screenSize = UIHelper.GetSafeAreaRect()

        local nUIScale = Storage.Debug.nUIScale or 1
        local nNodeWitdh = UIHelper.GetWidth(self._rootNode) * nUIScale / 2
        local nNodeHeight = UIHelper.GetHeight(self._rootNode) * nUIScale / 2
        local nNewX = nX - self.nLastX + UIHelper.GetPositionX(self._rootNode)
        local nNewY = nY - self.nLastY + UIHelper.GetPositionY(self._rootNode)

        if nNewX - nNodeWitdh < parentNodeX then
            nNewX = parentNodeX +  nNodeWitdh
        elseif (nNewX + nNodeWitdh) > (parentNodeX + screenSize.width) then
            nNewX = parentNodeX + screenSize.width - nNodeWitdh
        end

        if (nNewY - nNodeHeight) < parentNodeY then
            nNewY = parentNodeY + nNodeHeight
        elseif nNewY + nNodeHeight > parentNodeY + screenSize.height then
            nNewY = parentNodeY + screenSize.height - nNodeHeight
        end
        UIHelper.SetPosition(self._rootNode, nNewX, nNewY)

        self.nLastX = nX
        self.nLastY = nY
    end)

    UIHelper.BindUIEvent(self.BtnMovePanel, EventType.OnTouchEnded, function(btn, nX, nY)
        self.nLastX = nil
        self.nLastY = nil
    end)
end


-- 连接机器人显示信息
function UIRobotPanel:ContatArgument()
    if next(SearchRobot.tbRobot) then
        local showName = ""
        if #SearchRobot.tbRobot == 1 then
            showName = SearchRobot.tbRobot[1]
        else
            showName = SearchRobot.tbRobot[1] .."~"..SearchRobot.tbRobot[#SearchRobot.tbRobot]
        end
        return showName
    end
end

-- UNEnable
function UIRobotPanel:SetUnEnable(EditRobotIndex, EditRobotCount, EditRobotName)
    UIHelper.SetTouchEnabled(EditRobotIndex, false)
    UIHelper.SetTouchEnabled(EditRobotCount, false)
    UIHelper.SetTouchEnabled(EditRobotName, false)
    UIHelper.SetColor(EditRobotIndex, cc.c3b(127.5, 127.5, 127.5))
    UIHelper.SetColor(EditRobotCount, cc.c3b(127.5, 127.5, 127.5))
    UIHelper.SetColor(EditRobotName, cc.c3b(127.5, 127.5, 127.5))
end

function UIRobotPanel:SetEnable(EditRobotIndex, EditRobotCount, EditRobotName, BtnSetOK)
    UIHelper.SetTouchEnabled(EditRobotIndex, true)
    UIHelper.SetTouchEnabled(EditRobotCount, true)
    UIHelper.SetTouchEnabled(EditRobotName, true)
    UIHelper.SetColor(EditRobotIndex, cc.c3b(255, 255, 255))
    UIHelper.SetColor(EditRobotCount, cc.c3b(255, 255, 255))
    UIHelper.SetColor(EditRobotName, cc.c3b(255, 255, 255))
    -- -- 不可点击 置灰
    -- UIHelper.SetTouchEnabled(BtnSetOK, true)
    -- UIHelper.SetColor(BtnSetOK, cc.c3b(255, 255, 255))
end

-- 把阿拉伯数字转成中文数字 如: 123转成壹贰叁
function UIRobotPanel:J3tNumberToChar(n)
	local digits = {'零', '壹', '贰', '叁', '肆', '伍', '陆', '柒', '捌', '玖'}
	local map = {}
	for i = 1, #digits do
		map[tostring(i - 1)] = digits[i]
	end

	local s = tostring(n)
	local buf = {}

	for i = 1, #s do
		local ch = string.sub(s, i, i)	--取出s中第i个到第i个的字符；
		table.insert(buf, map[ch])
	end
	return table.concat(buf)
end


function UIRobotPanel:IsInTable(data)
    local isInTable = false
    if not SearchRobot.tbRobot then
        return isInTable
    end
    for _, value in ipairs(SearchRobot.tbRobot) do
        if value == data then
            isInTable = true
            break
        end
    end
    return isInTable
end

-- 初始化tbRobot 内容
-- startIndex: 100
-- startCount：3
-- startName: 全糖
-- 全糖壹零零 全糖壹零壹 全糖壹零贰
function UIRobotPanel:SetInitRobot(startIndex, startCount, startName)
    startIndex = tonumber(startIndex)
    startCount = tonumber(startCount)
    local i = 1
    while startCount and startCount ~= 0 do
        local stringIndex = UIRobotPanel:J3tNumberToChar(startIndex)
        local robotName = startName .. stringIndex
        startCount = startCount - 1
        startIndex = startIndex + 1
        if not UIRobotPanel:IsInTable(robotName) then
            table.insert(SearchRobot.tbRobot, i, robotName)
        end
        i = i + 1
    end

end


-- 召唤机器人
function UIRobotPanel:TeleportRobot()
    local player = GetClientPlayer()
    local dwMapID = player.GetScene().dwMapID
    local nCopyIndex = player.GetScene().nCopyIndex
    local szMsg = string.format("custom:LY_Teleport(%d, %d, %d, %d, %d)", dwMapID, nCopyIndex, player.nX, player.nY, player.nZ)
    SearchRobot:SendCustomMessage(szMsg, 2)
end


-- 范围内站立
function UIRobotPanel:RnadomStandAccordToMe()
    local player = GetClientPlayer()
    local tRankOffSetX = 100
    local tRankOffsetY = 200
    local szMsg = string.format("custom:LY_RandomStandAccordToMe(%d, %d, %d, %d, %d)", player.nX, player.nY, player.nZ, tRankOffSetX, tRankOffsetY)
    SearchRobot:SendCustomMessage(szMsg, 2)
end

-- 请跟随我
function UIRobotPanel:StartFollow()
    local player = GetClientPlayer()
    local szMsg = string.format("custom:StartFollow(%d,10)", player.dwID)
    SearchRobot:SendCustomMessage(szMsg, 2)
end

-- 停止跟随我
function UIRobotPanel:StopFollow()
    local szMsg = "custom:StopFollow()"
    SearchRobot:SendCustomMessage(szMsg, 2)
end


-- 添加好友
function UIRobotPanel:AddFriend()
    if SearchRobot.nChannel ~= PLAYER_TALK_CHANNEL.WHISPER then
        OutputMessage("MSG_ANNOUNCE_RED", "为防止误操作, 请选择指定机器人模式！")
        return
    end
    local nRobotCount = #SearchRobot.tbRobot
    local nIndex = 1
    local AddFellowship = function ()
        local szName = SearchRobot.tbRobot[nIndex]
        local name = UIHelper.UTF8ToGBK(szName)
        local tTargetRole = JX.GetPlayerByName(name)
        if tTargetRole and not FellowshipData.IsFriend(tTargetRole.dwID) then
            FellowshipData.AddFellowship(name)
        end
        nIndex = nIndex + 1
    end
    Timer.AddCountDown(self, nRobotCount, AddFellowship)
end


function UIRobotPanel:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRobotPanel:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



function UIRobotPanel:ToggleSelect(nKey)
    if nKey == "Designated" then
        self.WidgetChangeRobot:setVisible(true)
    end
    UIHelper.TableView_init(self.ScrollViewDropList, #tbRobotSelect, PREFAB_ID.WidgetSelectTog358X86)
    UIHelper.TableView_reloadData(self.ScrollViewDropList)
end


-- ----------------------------------------------------------
-- 更新设置全局保存的机器人参数
-- ----------------------------------------------------------

function UIRobotPanel:UpdateInfo()
    self:ToggleSelect()

    -- 设置全局参数
    UIHelper.SetString(self.EditRobotIndex, self.tbFunction.szRobotIndex)
    UIHelper.SetString(self.EditRobotCount, self.tbFunction.szRobotCount)
    UIHelper.SetString(self.EditRobotName, self.tbFunction.szRobotSuffixName)
    UIHelper.SetString(self.szLabelTextTip, self.tbFunction.szLabelTextTip)

    -- 指定机器人模式初始化tbRobot
    if SearchRobot.nChannel == PLAYER_TALK_CHANNEL.WHISPER then
        self.WidgetChangeRobot:setVisible(true)
        UIRobotPanel:SetInitRobot(self.tbFunction.szRobotIndex, self.tbFunction.szRobotCount, self.tbFunction.szRobotSuffixName)
    end
end

return UIRobotPanel