-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIOutMapView
-- Date: 2024-04-22 11:41:03
-- Desc: 低活跃度投票 PanelAnswerMapPop
-- ---------------------------------------------------------------------------------

local UIOutMapView = class("UIOutMapView")

local APPLY_TONG_NAME_NUM = 4
local CLOSE_TIME = 15 * 1000

function UIOutMapView:OnEnter(dwPlayerID, szPlayerName, nLevel, nRoleType, nForce, nTongID, nGainTitlePoint, nPosX, nPosY, nPosZ, nTitleLevel, nScores)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        Timer.AddFrameCycle(self, 1, function()
            self:OnUpdate()
        end)
    end

    self.dwPlayerID     = dwPlayerID
    self.nTime          = GetTickCount()
    self.nTongID        = nTongID
    self.nPosX          = nPosX
    self.nPosY          = nPosY
    self.nPosZ          = nPosZ
    self.szPlayerName   = szPlayerName
    self.szTongName     = nil

    self:UpdateInfo(szPlayerName, nLevel, nForce, nGainTitlePoint, nPosX, nPosY, nPosZ, nTitleLevel, nScores, nRoleType)
end

function UIOutMapView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    FireUIEvent("DEL_MAP_MARK", self.nPosX, self.nPosY, self.nPosZ, 5, self.szPlayerName, true)
end

function UIOutMapView:OnUpdate()
    local nNowTime = GetTickCount()
    if nNowTime - self.nTime >= CLOSE_TIME then
        LOG.INFO("[OutMap] VoteCastleFightActivityLow false")
        VoteCastleFightActivityLow(self.dwPlayerID, false)
        UIMgr.Close(self)
    else
        -- local fPercentage = (nNowTime - self.nTime) / CLOSE_TIME
        -- UIHelper.SetProgressBarPercent(self.ProgressBar, 1 - fPercentage)
        local szTime = math.floor((CLOSE_TIME - (nNowTime - self.nTime)) / 1000)
        UIHelper.SetString(self.LabelNum, szTime)
    end
end

function UIOutMapView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnEsc, EventType.OnClick, function()
        LOG.INFO("[OutMap] VoteCastleFightActivityLow false")
        VoteCastleFightActivityLow(self.dwPlayerID, false)
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function()
        LOG.INFO("[OutMap] VoteCastleFightActivityLow true")
        VoteCastleFightActivityLow(self.dwPlayerID, true)
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnCheck, EventType.OnClick, function()
        local player = GetClientPlayer()
        if not player then
            return
        end

        local dwMapID = player.GetMapID()
        local dwIndex = player.GetScene().dwIndex
        FireUIEvent("UPDATE_MAP_MARK", self.nPosX, self.nPosY, self.nPosZ, 5, self.szPlayerName, true)
        UIMgr.Open(VIEW_ID.PanelMiddleMap, dwMapID, dwIndex)

        UIMgr.HideView(VIEW_ID.PanelAnswerMapPop)
    end)
end

function UIOutMapView:RegEvent()
    Event.Reg(self, "ON_GET_TONG_NAME_NOTIFY", function(nUIType, dwTongID, szTongName)
        if nUIType == APPLY_TONG_NAME_NUM and dwTongID == self.nTongID then
            self:UpdateTong()
        end
    end)
    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if not UIMgr.IsViewOpened(VIEW_ID.PanelMiddleMap) and not UIMgr.IsViewOpened(VIEW_ID.PanelWorldMap) then
            UIMgr.ShowView(VIEW_ID.PanelAnswerMapPop)
        end
    end)
end

function UIOutMapView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOutMapView:UpdateInfo(szPlayerName, nLevel, nForce, nGainTitlePoint, nPosX, nPosY, nPosZ, nTitleLevel, nScores, nRoleType)
    self:UpdateTong()

    UIHelper.SetString(self.LabelName, UIHelper.TruncateStringReturnOnlyResult(UIHelper.GBKToUTF8(szPlayerName), 13))
    UIHelper.SetString(self.LabelLevel, nLevel)
    UIHelper.SetSpriteFrame(self.ImgSchool, PlayerForceID2SchoolImg2[nForce])
    UIHelper.SetString(self.LabelZhanJie, "战阶等级：" .. nTitleLevel)
    UIHelper.SetString(self.LabelGongXian, "个人贡献：" .. nGainTitlePoint)
    UIHelper.SetString(self.LabelZhuangFen, "装备分数：" .. nScores)

    local dwMapID = MapHelper.GetMapID()
    local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID)) or ""
    UIHelper.SetString(self.LabelWeiZhi, "所在位置：" .. szMapName)

    --头像
    local tLine = Table_GetMiniAvatarID(nForce)
    local scriptHead = UIHelper.GetBindScript(self.WidgetHead_108)
    scriptHead:SetHeadInfo(nil, tLine.dwMiniAvatarID, nRoleType, nForce)
end

function UIOutMapView:UpdateTong()
    if self.szTongName then
        return
    end

    local szTongText
    if self.nTongID and self.nTongID then
        local szTongName = GetTongClient().ApplyGetTongName(self.nTongID, APPLY_TONG_NAME_NUM)
        if szTongName then
            self.szTongName = szTongName
            szTongText = UIHelper.GBKToUTF8(szTongName)
        else
            szTongText = g_tStrings.STR_GUILD_LAST_ONLINE_TIME_UNKNOWN
        end
    else
        szTongText = g_tStrings.STR_NO_TONG
    end
    UIHelper.SetString(self.LabelParty, "所在帮会：" .. szTongText)
end


return UIOutMapView