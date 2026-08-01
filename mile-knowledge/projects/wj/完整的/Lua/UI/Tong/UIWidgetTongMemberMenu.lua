-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetTongMemberMenu
-- Date: 2023-01-06
-- Desc: 帮会成员菜单
-- Prefab: WidgetFactionManagementMemberPlayerPop
-- ---------------------------------------------------------------------------------

---@class UIWidgetTongMemberMenu
local UIWidgetTongMemberMenu = class("UIWidgetTongMemberMenu")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIWidgetTongMemberMenu:_LuaBindList()
    self.AnimatePlayerIcon = self.AnimatePlayerIcon --- 关闭界面
    self.SFXPlayerIcon     = self.SFXPlayerIcon --- 关闭界面
end

local g2u = UIHelper.GBKToUTF8

function UIWidgetTongMemberMenu:Init(tData)
    self.m       = {}
    self.m.tData = tData
    self:RegEvent()
    self:BindUIEvent()

    self:UpdateInfo()

    UIHelper.SetPosition(self._rootNode, 0, 0)
    UIHelper.SetAnchorPoint(self._rootNode, 0.5, 0.5)
end

function UIWidgetTongMemberMenu:UnInit()
    self:UnRegEvent()
    self.m = nil
end

function UIWidgetTongMemberMenu:BindUIEvent()
    -- UIHelper.BindUIEvent(self.TogModifyEditBox, EventType.OnClick, function()
    -- 	UIHelper.SetVisible(self.BtnClose03, false)
    -- end)

end

function UIWidgetTongMemberMenu:RegEvent()

end

function UIWidgetTongMemberMenu:UnRegEvent()
    Event.UnRegAll(self)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTongMemberMenu:AddBtn(szTitle, fnCallback)
    local root, node
    root = UIHelper.AddPrefab(PREFAB_ID.WidgetMemberPlayerPopMoreBtn, self.LayoutMenuBtn)
    assert(root)
    node = UIHelper.FindChildByName(root, "Lable")
    assert(node)
    UIHelper.SetString(node, szTitle)
    node = UIHelper.FindChildByName(root, "Btn")
    assert(node)
    UIHelper.BindUIEvent(node, EventType.OnClick, fnCallback)

end

function UIWidgetTongMemberMenu:UpdateInfo()
    local tong = GetTongClient()
    assert(tong)
    local tData = self.m.tData
    assert(tData)

    -- 名称
    UIHelper.SetString(self.LableName, g2u(tData.szName))
    -- 等级
    UIHelper.SetString(self.LableLevel, tostring(tData.nLevel) .. "级")
    -- 门派
    if tData.nForceID then
        local dwMiniAvatarID = 0
        local nRoleType      = nil
        local dwForceID      = tData.nForceID
        UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon, dwMiniAvatarID, self.SFXPlayerIcon, self.AnimatePlayerIcon, nRoleType, dwForceID, true)
        UIHelper.SetNodeGray(self.ImgPlayerIcon, not tData.bIsOnline)
    end
    -- 所在地
    local sz = tData.bIsOnline and g2u(Table_GetMapName(tData.dwMapID)) or g_tStrings.STR_GUILD_OFFLINE
    sz       = UIHelper.TruncateStringReturnOnlyResult(sz, 8)
    UIHelper.SetString(self.LablePos, sz)

    -- 自己
    if g_pClientPlayer.dwID == tData.dwID then
        -- 若是帮主
        if g_pClientPlayer.dwID == tong.dwMaster then
            -- 转交中
            if tong.dwNextMaster and tong.dwNextMaster ~= 0 then
                self:AddBtn("取消转交", function()
                    UIHelper.ShowConfirm(g_tStrings.STR_GUILD_CANCLE_CHANGE_MASTER_SURE, function()
                        GetTongClient().CancelChangeMaster()
                    end)
                    self:Close()
                end)
            end
        end
    else
        -- 他人
        local tMyMemberInfo = tong.GetMemberInfo(g_pClientPlayer.dwID)

        -- 密聊
        do
            self:AddBtn("密聊", function()
                local szName         = g2u(tData.szName)
                local dwTalkerID     = tData.dwID
                local dwForceID      = tData.nForceID
                local dwMiniAvatarID = tData.dwMiniAvatarID or 0
                local nRoleType      = tData.nRoleType
                local nLevel         = tData.nLevel
                local szGlobalID     = tData.szGlobalID
                local tbData         = { szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel, szGlobalID = szGlobalID }
                ChatHelper.WhisperTo(szName, tbData)
                self:Close()
            end)
        end

        -- 组队
        do
            self:AddBtn("组队", function()
                TeamData.InviteJoinTeam(tData.szName)
                self:Close()
            end)
        end

        -- 加为好友
        do
            self:AddBtn("加为好友", function()
                FellowshipData.AddFellowship(tData.szName)
                self:Close()
            end)
        end

        -- 查看装备
        do
            self:AddBtn("查看装备", function()
                UIMgr.Open(VIEW_ID.PanelOtherPlayer, tData.dwID, nil, tData.szGlobalID)
                self:Close()
            end)
        end

        -- 移除帮众
        if tong.CheckAdvanceOperationGroup(tMyMemberInfo.nGroupID, tData.nGroupID, 0)
                and tData.dwID ~= tong.dwNextMaster
        then
            self:AddBtn("移除帮众", function()
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "Tong") then
                    return
                end

                UIHelper.ShowConfirm(FormatString(g_tStrings.STR_GUILD_KICK_SURE, "[" .. g2u(tData.szName) .. "]"), function()
                    GetTongClient().ApplyKickOutMember(tData.dwID)
                end)
                self:Close()
            end)
        end

        -- 移交帮主
        if g_pClientPlayer.dwID == tong.dwMaster then
            -- 未转交
            if tong.dwNextMaster == 0 then
                self:AddBtn("移交帮主", function()
                    UIMgr.Open(VIEW_ID.PanelFactionTransferPop, tData)
                    self:Close()
                end)

            else
                -- 若是帮主
                if tData.dwID == tong.dwNextMaster then
                    self:AddBtn("取消转交", function()
                        UIHelper.ShowConfirm(g_tStrings.STR_GUILD_CANCLE_CHANGE_MASTER_SURE, function()
                            GetTongClient().CancelChangeMaster()
                        end)
                        self:Close()
                    end)
                end

            end
        end

        -- 移动至其他权限组
        if tong.CheckAdvanceOperationGroup(tMyMemberInfo.nGroupID, tData.nGroupID, 0)
                and tData.dwID ~= tong.dwNextMaster
        then
            self:AddBtn("移动至", function()
                UIMgr.Open(VIEW_ID.PanelFactionManagementFilterScreen, TongData.tFilterScreenType.Permissions, { tData.dwID }, tData.nGroupID, nil)
            end)
        end
    end



    -- 适配大小
    local szRootName = self._rootNode:getName()
    node             = self.LayoutMenuBtn
    repeat
        UIHelper.LayoutDoLayout(node)
        if node:getName() == szRootName then break end
        node = node:getParent()
    until not node

    -- 点击关闭界面
    UIHelper.SetPosAndSizeByRefNode(self.BtnBlock, self._rootNode)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        self:Close()
    end)

end

function UIWidgetTongMemberMenu:Close()
    self:UnInit()
    UIHelper.RemoveFromParent(self._rootNode)
end

function UIWidgetTongMemberMenu:InitForTongWar(dwPlayerID, szName, nForceID, szGlobalID, nPlayerIdentity)
    -- 名称
    UIHelper.SetString(self.LableName, szName)
    -- 等级
    --UIHelper.SetString(self.LableLevel, tostring(tData.nLevel) .. "级")
    UIHelper.SetVisible(self.LableLevel, false)
    -- 门派
    if nForceID then
        local dwMiniAvatarID = 0
        local nRoleType      = nil
        local dwForceID      = nForceID
        UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon, dwMiniAvatarID, self.SFXPlayerIcon, self.AnimatePlayerIcon, nRoleType, dwForceID, true)
        --UIHelper.SetNodeGray(self.ImgPlayerIcon, not tData.bIsOnline)
    end
    -- 所在地
    --local sz = tData.bIsOnline and g2u(Table_GetMapName(tData.dwMapID)) or g_tStrings.STR_GUILD_OFFLINE
    --sz = UIHelper.TruncateStringReturnOnlyResult(sz, 8)
    --UIHelper.SetString(self.LablePos, sz)
    UIHelper.SetVisible(self.LablePos, false)
    UIHelper.SetVisible(self.LablePosTitle, false)

    -- 按钮
    self:AddBtn("组队", function()
        TeamData.InviteJoinTeam(UIHelper.UTF8ToGBK(szName))
    end)
    self:AddBtn("查看装备", function()
        UIMgr.Open(VIEW_ID.PanelOtherPlayer, dwPlayerID, nil, szGlobalID)
    end)

    self:AddBtn("密聊", function()
        local tbData = { szName = szName, dwTalkerID = dwPlayerID, dwForceID = nForceID }
        ChatHelper.WhisperTo(szName, tbData)
    end)

    local tTongWarInfo          = BattleFieldData.GetTongFight2024Info()
    local nClientPlayerIdentity = tTongWarInfo.nVipLevel

    --- 当前客户端玩家不是普通成员，且权限高于选中的玩家，则显示踢人按钮
    if nClientPlayerIdentity ~= TONG_LEAGUE_KEYPERSONNEL_TYPE.ORDINARY and nClientPlayerIdentity > nPlayerIdentity then
        self:AddBtn("踢出战场", function()
            UIHelper.RemoteCallToServer("On_Zhanchang_TongWarKick", dwPlayerID)
        end)
    end

    -- 适配大小
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

return UIWidgetTongMemberMenu