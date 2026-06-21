-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UICityBelongPopView
-- Date: 2023-07-28 10:52:31
-- Desc: 小攻防据点归属界面 PanelCityBelongPop
-- ---------------------------------------------------------------------------------

local UICityBelongPopView = class("UICityBelongPopView")

local LIMIT_TIME = 30

function UICityBelongPopView:OnEnter(dwCastleID)
    self.dwCastleID = dwCastleID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        Timer.AddFrameCycle(self, 1, function()
            self:OnUpdate()
        end)
    end

    self.tRankList = {}
    self.tRetCastleInfo = {}
    self.nLastCheckTime = 0

    self:InitCastleInfo()
    self:UpdateRankList()

    LoadMilitaryRankData()
    RemoteCallToServer("On_Castle_GetCtriRankList")
end

function UICityBelongPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICityBelongPopView:OnUpdate()
    if GetCurrentTime() - self.nLastCheckTime > LIMIT_TIME then
        self:ApplyCastleFightRankList()
    end
end

function UICityBelongPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UICityBelongPopView:RegEvent()
    Event.Reg(self, "ON_CASTLE_GET_FIGHT_RANK_REQUEST", function(tRankList, tRetCastleInfo)
        print("[Camp CityBelong] ON_CASTLE_GET_FIGHT_RANK_REQUEST")
        -- print_table("[Camp CityBelong] tRankList", tRankList)
        -- print_table("[Camp CityBelong] tRetCastleInfo", tRetCastleInfo)

        if CampData.dwEndCastleID and CampData.dwEndCastleID ~= 0 then
            local tEndCastle = self.tRankList[CampData.dwEndCastleID]
            if tEndCastle and tEndCastle.nState == 2 then
                local nType = 1
                local nFightCamp = tEndCastle.nFightCamp
                --InstanceInfo.Open(nType, nFightCamp, CampData.dwEndCastleID) --TODO 这是啥？
            end
            CampData.dwEndCastleID = nil
        end

        self.tRankList = tRankList
        self.tRetCastleInfo = tRetCastleInfo

        local tCastle = self.tRankList[self.dwCastleID]
        if not tCastle then
            return
        end
        self.dwType       = tCastle.nType
        self.dwSceneID    = tCastle.nParam2

        self:UpdateInfo()
        self:ApplyCastleFightRankList()
    end)
    Event.Reg(self, "CASTLE_FIGHT_RANK_UPDATE", function(nType, dwSceneID, nTotalNum)
        print("[Camp CityBelong] CASTLE_FIGHT_RANK_UPDATE", nType, dwSceneID, nTotalNum)
        if nType == self.dwType and dwSceneID == self.dwSceneID then
            self:UpdateRankList()
        end
    end)
end

function UICityBelongPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICityBelongPopView:InitCastleInfo()
    local tLine = Table_GetCastleInfo(self.dwCastleID)
    if not tLine then
        return
    end

    self.szCastleName = tLine.szCastleName

    local szCastleName = UIHelper.GBKToUTF8(tLine.szCastleName)
    UIHelper.SetString(self.LabelTitle, szCastleName .. "据点归属")
end

function UICityBelongPopView:UpdateInfo()
    local tCastle = self.tRankList[self.dwCastleID]
    if not tCastle then
        return
    end

    local nState, dwType, dwSceneID = tCastle.nState, tCastle.nType, tCastle.nParam2

    if nState == 1 then --活动正在进行
        UIHelper.SetVisible(self.LabelCityBelong1, true)
        UIHelper.SetVisible(self.LabelCityBelong2, false)
    elseif nState == 2 then --活动结束
        local tOwner, dwOwnerTongID
        for dwTongID, szCastleName in pairs(self.tRetCastleInfo) do
            if szCastleName == self.szCastleName then
                dwOwnerTongID = dwTongID
                break
            end
        end
        if dwOwnerTongID then
            local tCastle = GetMilitaryRankListClient().GetCastleFightRankList(dwType, dwSceneID).GetRankList()
            if tCastle then
                for nRankID, tRecord in ipairs(tCastle) do
                    if tRecord.dwTongID == dwOwnerTongID then
                        tOwner = tRecord
                        break
                    end
                end
            end
        end

        if tOwner then
            local szTongName = UIHelper.GBKToUTF8(tOwner.szTongName)
            local szMasterName = UIHelper.GBKToUTF8(tOwner.szMasterName)

            --TODO 帮主头像？local szPath, nFrame = Castle_GetAvatarImage(tOwner.nForceID, tOwner.nRoleType)

            UIHelper.SetVisible(self.LabelCityBelong1, false)
            UIHelper.SetVisible(self.LabelCityBelong2, true)
            UIHelper.SetString(self.LabelCityBelong2, "此据点归属帮会" .. szTongName .. "！")
        else
            UIHelper.SetVisible(self.LabelCityBelong1, true)
            UIHelper.SetVisible(self.LabelCityBelong2, false)

            -- --头像框颜色
            -- if tCastle.nFightCamp == CAMP.GOOD then

            -- elseif tCastle.nFightCamp == CAMP.EVIL then

            -- end
        end
    end
end

function UICityBelongPopView:UpdateRankList()
    local dwType, dwSceneID = self.dwType, self.dwSceneID
    if not dwType or not dwSceneID then
        UIHelper.SetVisible(self.WidgetLabelCityContributeSelf, false)
        return
    end

    local tSelfTong

    UIHelper.RemoveAllChildren(self.ScrollViewCityContribute)

    local player = GetClientPlayer()
    local dwTongID = player and player.dwTongID
    local tCastle = GetMilitaryRankListClient().GetCastleFightRankList(dwType, dwSceneID).GetRankList()
    for nRankID, tRecord in ipairs(tCastle) do
        if dwTongID and dwTongID == tRecord.dwTongID then
            tSelfTong = tRecord
            tSelfTong.nRankID = nRankID
        end

        local szCastleName = self.tRetCastleInfo[tRecord.dwTongID]
        local bCurCastle = szCastleName == self.szCastleName
        UIMgr.AddPrefab(PREFAB_ID.WidgetLabelCityContribute, self.ScrollViewCityContribute, nRankID, szCastleName, bCurCastle, tRecord, tCastle)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCityContribute)
    UIHelper.SetVisible(self.WidgetLabelCityContributeSelf, tSelfTong ~= nil)

    if tSelfTong then
        local tCastle = self.tRankList[self.dwCastleID]
        local nRankID = tSelfTong.nRankID
        local szCastleName = self.tRetCastleInfo[tSelfTong.dwTongID]
        local bCurCastle = szCastleName == self.szCastleName

        local scriptView = UIHelper.GetBindScript(self.WidgetLabelCityContributeSelf)
        scriptView:OnEnter(nRankID, szCastleName, bCurCastle, tSelfTong, tCastle)

    elseif not dwTongID or dwTongID == 0 then
        --显示自身无帮会
    end

    self:UpdateInfo()
end

function UICityBelongPopView:ApplyCastleFightRankList()
    if not self.dwType or not self.dwSceneID then
        return
    end

    self.nLastCheckTime = GetCurrentTime()
    GetMilitaryRankListClient().ApplyCastleFightRankList(self.dwType, self.dwSceneID)
end

return UICityBelongPopView