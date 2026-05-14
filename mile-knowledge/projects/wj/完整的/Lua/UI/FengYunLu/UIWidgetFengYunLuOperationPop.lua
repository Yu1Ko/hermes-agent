-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetTongMemberMenu
-- Date: 2023-01-06
-- Desc: 帮会成员菜单
-- ---------------------------------------------------------------------------------

local UIWidgetFengYunLuOperationPop = class("UIWidgetFengYunLuOperationPop")

local g2u = UIHelper.GBKToUTF8

function UIWidgetFengYunLuOperationPop:OnEnter(tData,fnClose)
    self.m = {}
    self.m.tData = tData
    self.fnClose = fnClose
    self:RegEvent()
    self:BindUIEvent()

    self:UpdateInfo()

    UIHelper.SetPosition(self._rootNode, 0, 0)
    UIHelper.SetAnchorPoint(self._rootNode, 0.5, 0.5)
end

function UIWidgetFengYunLuOperationPop:OnExit()
    self:UnRegEvent()
    self.m = nil

    print(self.fnClose)
    if self.fnClose then
        self.fnClose()
    end
end

function UIWidgetFengYunLuOperationPop:BindUIEvent()
    -- UIHelper.BindUIEvent(self.TogModifyEditBox, EventType.OnClick, function()
    -- 	UIHelper.SetVisible(self.BtnClose03, false)
    -- end)
end

function UIWidgetFengYunLuOperationPop:RegEvent()

end

function UIWidgetFengYunLuOperationPop:UnRegEvent()
    Event.UnRegAll(self)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetFengYunLuOperationPop:AddBtn(szTitle, fnCallback)
    local root, node
    root = UIHelper.AddPrefab(PREFAB_ID.WidgetMemberPlayerPopMoreBtn, self.LayoutMenuBtn)
    assert(root)
    node = UIHelper.FindChildByName(root, "Lable")
    assert(node)
    UIHelper.SetString(node, szTitle)
    node = UIHelper.FindChildByName(root, "Btn")
    assert(node)
    UIHelper.BindUIEvent(node, EventType.OnClick, fnCallback)
    UIHelper.SetTouchDownHideTips(node,false)
end

function UIWidgetFengYunLuOperationPop:UpdateInfo()
    local tData = self.m.tData
    assert(tData)

    --print("g_pClientPlayer.szName ~= tData.szName",g_pClientPlayer.szName ~= tData.szName)
    -- 自己
    if g_pClientPlayer.szName ~= tData.szName then


        if tData.bPerson then
            -- 名称
            UIHelper.SetString(self.LableName, g2u(tData.szName))

            -- 密聊
            self:AddBtn("密聊", function ()
                ChatHelper.WhisperTo( g2u(tData.szName), {})
                self:Close()
            end)
            -- 组队
            self:AddBtn(g_tStrings.STR_MAKE_PARTY, function()
                TeamData.InviteJoinTeam(tData.szName)
                self:Close()
            end)
            -- 加为好友
            self:AddBtn(g_tStrings.STR_MAKE_FRIEND, function()
                FellowshipData.AddFellowship(tData.szName)
                self:Close()
            end)

        else
            -- 名称
            UIHelper.SetString(self.LableName, g2u(tData.szTongName))
            self:AddBtn( g_tStrings.STR_GUILD_REQUEST_JOIN, function()
                if (GetClientPlayer().nLevel < CAN_APPLY_JOIN_LEVEL) then
                    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.TONG_REQUEST_TOO_LOW)
                    OutputMessage("MSG_SYS", g_tStrings.TONG_REQUEST_TOO_LOW .. "\n")
                    self:Close()
                    return
                end

                RemoteCallToServer("On_Tong_ApplyJoinRequest", tData.szTongName)
                self:Close()
            end)
        end
    end

    -- 适配大小
    local szRootName = self._rootNode:getName()
    node = self.LayoutMenuBtn
    repeat
        UIHelper.LayoutDoLayout(node)
        if node:getName() == szRootName then
            break
        end
        node = node:getParent()
    until not node

    -- 点击关闭界面
    UIHelper.SetPosAndSizeByRefNode(self.BtnBlock, self._rootNode)
    --UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
    --    self:Close()
    --end)
end

function UIWidgetFengYunLuOperationPop:Close()
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetFengYunLuOperationPop)
end

return UIWidgetFengYunLuOperationPop