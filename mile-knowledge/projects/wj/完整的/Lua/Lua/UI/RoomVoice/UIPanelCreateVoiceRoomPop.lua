-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelCreateVoiceRoomPop
-- Date: 2025-05-22 15:57:16
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelCreateVoiceRoomPop = class("UIPanelCreateVoiceRoomPop")

function UIPanelCreateVoiceRoomPop:OnEnter(tbInfo, szRoomID, szDefaultName)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bCreate = tbInfo == nil
    self.tbInfo = tbInfo
    self.szRoomID = szRoomID
    self:UpdateInfo()
    -- 创建模式下填入默认房间名
    if self.bCreate and szDefaultName and szDefaultName ~= "" then
        UIHelper.SetString(self.EditBoxRoomName, szDefaultName)
        UIHelper.SetString(self.LabelLimitName, UIHelper.GetUtf8Len(szDefaultName) .. "/10")
    end
end

function UIPanelCreateVoiceRoomPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelCreateVoiceRoomPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function()
        if self.bCreate then
            local szRoomName = UIHelper.UTF8ToGBK(UIHelper.GetString(self.EditBoxRoomName))
            local szPassword = UIHelper.GetString(self.EditBoxPassword)
            RoomVoiceData.CreateRoomVoice(szRoomName, szPassword, self.bPublic, self.nMicMope, self.nCampMask, self.nLevelLimit)
        else
            local szName = UIHelper.UTF8ToGBK(UIHelper.GetString(self.EditBoxRoomName))
            local bNameChanged = szName ~= self.tbInfo.szRoomName
            if bNameChanged then
                RoomVoiceData.ChangeRoomName(self.szRoomID, szName)
            end

            local szPassword = UIHelper.GetString(self.EditBoxPassword)
            RoomVoiceData.ChangeRoomPassword(self.szRoomID, szPassword)

            -- 因为服务器做了1s的CD，因此不能在发完改密码请求后立马发改信息请求
            -- 客户端这边也延时1s再发请求，但是为了保证交互完整性和用户体验，做了个触摸屏蔽
            -- 等发完再解开
            local nDelayTime = 1 -- 1秒
            UIHelper.ShowTouchMask(nDelayTime)
            Timer.DelTimer(self, self.nSenndDITimerID)
            self.nSenndDITimerID = Timer.Add(self, nDelayTime, function()
                self.nSenndDITimerID = nil
                RoomVoiceData.ChangeRoomDetailInfo(self.szRoomID, self.nMicMope, self.nCampMask, self.nLevelLimit, self.bPublic)
                UIMgr.Close(self)
            end)
        end
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogTypePublic, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:SetPublic(true)
        end
    end)

    UIHelper.BindUIEvent(self.TogTypeUnpublic, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:SetPublic(false)
        end
    end)

    UIHelper.BindUIEvent(self.TogTypeMicMode, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:SetMicMode(VOICE_ROOM_MIC_MODE.MASTER_MODE, VOICE_ROOM_MIC_MODE_LIST[VOICE_ROOM_MIC_MODE.MASTER_MODE])
        end
    end)

    UIHelper.BindUIEvent(self.TogTypeMicModeFree, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:SetMicMode(VOICE_ROOM_MIC_MODE.FREE_MODE, VOICE_ROOM_MIC_MODE_LIST[VOICE_ROOM_MIC_MODE.FREE_MODE])
        end
    end)

    UIHelper.BindUIEvent(self.TogTypeMicModePermission, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:SetMicMode(VOICE_ROOM_MIC_MODE.MANAGE_MODE, VOICE_ROOM_MIC_MODE_LIST[VOICE_ROOM_MIC_MODE.MANAGE_MODE])
        end
    end)

    UIHelper.BindUIEvent(self.TogTypeHaoQI, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:AddCamp(CAMP.GOOD)
        else
            self:DelCamp(CAMP.GOOD)
        end
    end)

    UIHelper.BindUIEvent(self.TogTypeERen, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:AddCamp(CAMP.EVIL)
        else
            self:DelCamp(CAMP.EVIL)
        end
    end)

    UIHelper.BindUIEvent(self.TogTypeZhongLi, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:AddCamp(CAMP.NEUTRAL)
        else
            self:DelCamp(CAMP.NEUTRAL)
        end
    end)

    UIHelper.BindUIEvent(self.TogTypeAgree, EventType.OnSelectChanged, function(_, bSelected)
        self:UpdateBtnAccept()
        RoomVoiceData.ChangeAgreenRule(bSelected)
    end)

    UIHelper.BindUIEvent(self.BtnVioceRoom, EventType.OnClick, function()
        RoomVoiceData.ShowAgreenText()
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxRoomName, function()
        local szText = UIHelper.GetText(self.EditBoxRoomName)
        local nLen = UIHelper.GetUtf8Len(szText)
        UIHelper.SetString(self.LabelLimitName, nLen .. "/10")
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxPassword, function()
        local szText = UIHelper.GetText(self.EditBoxPassword)
        local nLen = UIHelper.GetUtf8Len(szText)
        UIHelper.SetString(self.LabelPassLimit, nLen .. "/8")
    end)
end

function UIPanelCreateVoiceRoomPop:RegEvent()
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        UIHelper.SetSelected(self.TogType, false)
    end)

    Event.Reg(self, EventType.ON_JOIN_VOICE_ROOM, function(szRoomID, szSignature, bCreateRoom, bIsTeamRoom)
        if bCreateRoom then
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, EventType.ON_SYNC_VOICE_ROOM_INFO, function(szRoomID)
        if self.szRoomID == szRoomID and not self.nSenndDITimerID then
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, EventType.OnAgreenRuleChanged, function()
        UIHelper.SetSelected(self.TogTypeAgree, RoomVoiceData.IsAgreenRule(), false)
        self:UpdateBtnAccept()
    end)
end

function UIPanelCreateVoiceRoomPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelCreateVoiceRoomPop:UpdateInfo()
    UIHelper.SetToggleGroupIndex(self.TogTypePublic, ToggleGroupIndex.HurtStat)
    UIHelper.SetToggleGroupIndex(self.TogTypeUnpublic, ToggleGroupIndex.HurtStat)

    UIHelper.SetToggleGroupIndex(self.TogTypeMicMode, ToggleGroupIndex.HeatMapMode)
    UIHelper.SetToggleGroupIndex(self.TogTypeMicModeFree, ToggleGroupIndex.HeatMapMode)
    UIHelper.SetToggleGroupIndex(self.TogTypeMicModePermission, ToggleGroupIndex.HeatMapMode)

    UIHelper.LayoutDoLayout(self.LayoutTogRoomCamp)
    UIHelper.LayoutDoLayout(self.LayoutTogMicMode)

    local function Init()
        UIHelper.SetSelected(self.TogTypeAgree, (not self.bCreate) or (RoomVoiceData.IsAgreenRule()))
        UIHelper.SetVisible(self.BtnVioceRoom, self.bCreate)
        UIHelper.SetVisible(self.TogTypeAgree, self.bCreate)
        if not self.bCreate then
            local szText = UIHelper.GBKToUTF8(self.tbInfo.szRoomName)
            UIHelper.SetText(self.EditBoxRoomName, szText)
            local nLen = UIHelper.GetUtf8Len(szText)
            UIHelper.SetString(self.LabelLimitName, nLen .. "/10")
        end
        UIHelper.SetString(self.LabelTitle, self.bCreate and "创建语音聊天室" or "修改语音聊天室信息")
        UIHelper.SetString(self.LabelAccept, self.bCreate and "创建" or "修改")
    end

    local function DelayInit()
        --默认全选
        if self.bCreate then
            UIHelper.SetSelected(self.TogTypeHaoQI, true)
            UIHelper.SetSelected(self.TogTypeERen, true)
            UIHelper.SetSelected(self.TogTypeZhongLi, true)

            UIHelper.SetSelected(self.TogTypePublic, true)--默认公开

            UIHelper.SetSelected(self.TogTypeMicModePermission, true)--默认权限模式
        else
            UIHelper.SetSelected(self.TogTypeHaoQI, self:IsCampSelected(self.tbInfo, CAMP.GOOD))
            UIHelper.SetSelected(self.TogTypeERen, self:IsCampSelected(self.tbInfo, CAMP.EVIL))
            UIHelper.SetSelected(self.TogTypeZhongLi, self:IsCampSelected(self.tbInfo, CAMP.NEUTRAL))

            UIHelper.SetSelected(self.TogTypePublic, self.tbInfo.bPublic)--默认公开
            UIHelper.SetSelected(self.TogTypeUnpublic, not self.tbInfo.bPublic)

            UIHelper.SetSelected(self.TogTypeMicModePermission, self.tbInfo.nMicMode == VOICE_ROOM_MIC_MODE.MANAGE_MODE)--默认权限模式
            UIHelper.SetSelected(self.TogTypeMicModeFree, self.tbInfo.nMicMode == VOICE_ROOM_MIC_MODE.FREE_MODE)--默认权限模式
            UIHelper.SetSelected(self.TogTypeMicMode, self.tbInfo.nMicMode == VOICE_ROOM_MIC_MODE.MASTER_MODE)--默认权限模式
        end
    end

    if self.nInitTimer then
        Timer.DelTimer(self, self.nInitTimer)
    end
    self.nInitTimer = Timer.AddFrame(self, 1, DelayInit)--延一帧，不然ToggleGroupIndex的由于事件分发机制， 互斥会不生效
    Init()

    --默认130级
    self:SetLevelLimit(130)
end

function UIPanelCreateVoiceRoomPop:UpdateBtnAccept()
    local bSelected = UIHelper.GetSelected(self.TogTypeAgree)
    local nState = bSelected and BTN_STATE.Normal or BTN_STATE.Disable
    UIHelper.SetButtonState(self.BtnAccept, nState)
end

function UIPanelCreateVoiceRoomPop:SetMicMode(nMicMode, szMicMode)
    if self.nMicMope == nMicMode then return end
    self.nMicMope = nMicMode
    self.szMicMode = szMicMode
    UIHelper.SetString(self.LabelContentMicMode, self.szMicMode)
    UIHelper.SetString(self.LabelContentMicMode1, self.szMicMode)
end

function UIPanelCreateVoiceRoomPop:SetPublic(bPublic)
    self.bPublic = bPublic
end

function UIPanelCreateVoiceRoomPop:IsCampSelected(tbInfo, nCamp)
    if not tbInfo then return false end
    local nCampLimitMask = tbInfo.nCampLimitMask
    return GetNumberBit(nCampLimitMask, nCamp + 1)
end

function UIPanelCreateVoiceRoomPop:IsInCamp(nCamp)
    if not self.tbCamp then return nil end
    for nIndex, camp in ipairs(self.tbCamp) do
        if camp == nCamp then return nIndex end
    end
    return nil
end

function UIPanelCreateVoiceRoomPop:AddCamp(nCamp)
    if not self.tbCamp then
        self.tbCamp = {}
    end
    if self:IsInCamp(nCamp) then return end
    table.insert(self.tbCamp, nCamp)
    self:UpdateCampMask()
end

function UIPanelCreateVoiceRoomPop:DelCamp(nCamp)
    local nIndex = self:IsInCamp(nCamp)
    if nIndex then
        table.remove(self.tbCamp, nIndex)
        self:UpdateCampMask()
    end
end

function UIPanelCreateVoiceRoomPop:UpdateCampMask()
    self.nCampMask = 0
    for nIndex, nCamp in ipairs(self.tbCamp) do
        self.nCampMask = kmath.add_bit(self.nCampMask, nCamp + 1)
    end
end

function UIPanelCreateVoiceRoomPop:SetLevelLimit(nLevelLimit)
    self.nLevelLimit = nLevelLimit
end

return UIPanelCreateVoiceRoomPop