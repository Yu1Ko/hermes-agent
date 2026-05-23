-- ---------------------------------------------------------------------------------
-- Author: KSG
-- Name: UIWidgetAudienceItem
-- Date: 2026-03-24
-- Desc: 副本观战观众列表单元（PREFAB_ID.WidgetAudienceItem）
-- ---------------------------------------------------------------------------------

local UIWidgetAudienceItem = class("UIWidgetAudienceItem")

function UIWidgetAudienceItem:OnEnter(szGlobalID, szName, bShowKick)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    -- ScrollList 模式下由 fnUpdateCell 设置数据
    if szGlobalID then
        self.szGlobalID = szGlobalID
        self.fnKickCallback = nil
        self:UpdateInfo(szName, bShowKick)
    end
end

function UIWidgetAudienceItem:OnExit()
    self.bInit = false
end

function UIWidgetAudienceItem:RegEvent()
end

function UIWidgetAudienceItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnFilterItem, EventType.OnClick, function()
        if self.fnKickCallback then
            self.fnKickCallback()
        end
    end)
end

function UIWidgetAudienceItem:UpdateInfo(szName, bShowKick)
    -- 拼接服务器名：玩家名·服务器名
    local szDisplayName = UIHelper.GBKToUTF8(szName) or ""
    if self.szGlobalID then
        local tSocialInfo = RoomVoiceData.GetVoiceRoomMemberSocialInfo(self.szGlobalID)
        if tSocialInfo then
            -- 服务器名
            if tSocialInfo.dwCenterID and tSocialInfo.dwCenterID > 0 then
                local szCenterName = GetCenterNameByCenterID(tSocialInfo.dwCenterID)
                if szCenterName and szCenterName ~= "" then
                    szDisplayName = szDisplayName .. "·" .. UIHelper.GBKToUTF8(szCenterName)
                end
            end
            -- 门派图标
            if self.ImgMenPai and tSocialInfo.nForceID then
                local szImgName = PlayerForceID2SchoolImg2[tSocialInfo.nForceID]
                if szImgName then
                    UIHelper.SetSpriteFrame(self.ImgMenPai, szImgName)
                end
            end
        end
    end

    UIHelper.SetString(self.LabelFilterItem, szDisplayName)
    UIHelper.SetVisible(self.ImgChecked, false)
    UIHelper.SetVisible(self.ImgNext, false)
    -- BtnFilterItem 作为踢出按钮，仅队长可见
    UIHelper.SetVisible(self.BtnFilterItem, bShowKick == true)
end

return UIWidgetAudienceItem
