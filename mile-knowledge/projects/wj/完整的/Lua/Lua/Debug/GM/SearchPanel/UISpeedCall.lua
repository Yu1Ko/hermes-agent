local UISpeedCall = class("UISpeedCall")

function UISpeedCall:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.EditPaginate:setTouchEnabled(false)
    self.EditNPCInfo:setTouchEnabled(false)
end

function UISpeedCall:OnExit()
    self.bInit = false
    self:UnRegEvent()
    if self.tAllNPC then
        local tCurrentNPC = (self.tAllNPC[self.nNpcIndex])
        local szGMCMDCallNPC = "player.GetScene().DestroyNpcByNickName('" ..tCurrentNPC.szNickName.."')"
        SendGMCommand(szGMCMDCallNPC)
    end
end

function UISpeedCall:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        local tCurrentNPC = (self.tAllNPC[self.nNpcIndex])
        local szGMCMDCallNPC = "player.GetScene().DestroyNpcByNickName('" ..tCurrentNPC.szNickName.."')"
        SendGMCommand(szGMCMDCallNPC)
        UIMgr.Close(VIEW_ID.PanelSearchPanel)
    end)

    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function(btn)
        local tCurrentNPC = (self.tAllNPC[self.nNpcIndex])
        local szGMCMDCallNPC = "player.GetScene().DestroyNpcByNickName('" ..tCurrentNPC.szNickName.."')"
        SendGMCommand(szGMCMDCallNPC)
        UIMgr.Close(VIEW_ID.PanelSearchPanel)
        UIMgr.Open(VIEW_ID.PanelSearchPanel)
    end)

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function(btn)
            if self.nNpcIndex > 1 then
                local tCurrentNPC = (self.tAllNPC[self.nNpcIndex])
                local szGMCMDCallNPC = "player.GetScene().DestroyNpcByNickName('" ..tCurrentNPC.szNickName.."')"
                SendGMCommand(szGMCMDCallNPC)
                self.nNpcIndex = self.nNpcIndex - 1
                local tCurrentNPC = (self.tAllNPC[self.nNpcIndex])
                UIHelper.SetString(self.EditPaginate, UIHelper.GBKToUTF8(tCurrentNPC.szName))
                local szText = "NPC名字:" .. UIHelper.GBKToUTF8(tCurrentNPC.szName)
                        .. "\nNPC别名:" .. tCurrentNPC.szNickName
                        .. "\nNPC模板ID:" .. tCurrentNPC.nTempleteID
                        .. "\nNPC坐标:" .. "\n(" .. tCurrentNPC.nX .. "," .. tCurrentNPC.nY .. "," .. tCurrentNPC.nZ .. ")"
                    UIHelper.SetString(self.EditNPCInfo, szText)

                local szGMCMDCallNPC = "player.GetScene().CreateNpc(" .. tCurrentNPC.nTempleteID .. ", player.nX+100, player.nY+100, player.nZ, 0, -1, '"..tCurrentNPC.szNickName.."')"
                SendGMCommand(szGMCMDCallNPC)
            end
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function(btn)
        if self.nNpcIndex < self.nNpcNum then
            local tCurrentNPC = (self.tAllNPC[self.nNpcIndex])
            local szGMCMDCallNPC = "player.GetScene().DestroyNpcByNickName('" ..tCurrentNPC.szNickName.."')"
            SendGMCommand(szGMCMDCallNPC)
            self.nNpcIndex = self.nNpcIndex + 1
            tCurrentNPC = (self.tAllNPC[self.nNpcIndex])
            UIHelper.SetString(self.EditPaginate, UIHelper.GBKToUTF8(tCurrentNPC.szName))
            local szText = "NPC名字:" .. UIHelper.GBKToUTF8(tCurrentNPC.szName)
                    .. "\nNPC别名:" .. tCurrentNPC.szNickName
                    .. "\nNPC模板ID:" .. tCurrentNPC.nTempleteID
                    .. "\nNPC坐标:" .. "\n(" .. tCurrentNPC.nX .. "," .. tCurrentNPC.nY .. "," .. tCurrentNPC.nZ .. ")"
                UIHelper.SetString(self.EditNPCInfo, szText)
            szGMCMDCallNPC = "player.GetScene().CreateNpc(" .. tCurrentNPC.nTempleteID .. ", player.nX+100, player.nY+100, player.nZ, 0, -1, '"..tCurrentNPC.szNickName.."')"
            SendGMCommand(szGMCMDCallNPC)
        end
    end)
end

function UISpeedCall:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISpeedCall:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISpeedCall:UpdateInfo(parentNode)
    -- self.LabelMapName = UIHelper.SetString(MapName)
    UIHelper.SetString(self.LabelMapName, UIHelper.GetString(parentNode.LabelDropList))
    self.tAllNPC = SearchPanel.GetAllNPCInfo(UIHelper.GetString(parentNode.LabelDropList))
    if next(self.tAllNPC) then
        self.nNpcIndex = 1
        self.nNpcNum = #self.tAllNPC
    end
    local tCurrentNPC = self.tAllNPC[self.nNpcIndex]
    UIHelper.SetString(self.EditPaginate, UIHelper.GBKToUTF8(tCurrentNPC.szName))
    local szText = "NPC名字:" .. UIHelper.GBKToUTF8(tCurrentNPC.szName)
        .. "\nNPC别名:" .. tCurrentNPC.szNickName
        .. "\nNPC模板ID:" .. tCurrentNPC.nTempleteID
        .. "\nNPC坐标:" .. "\n(" .. tCurrentNPC.nX .. "," .. tCurrentNPC.nY .. "," .. tCurrentNPC.nZ .. ")"
    UIHelper.SetString(self.EditNPCInfo, szText)
    local szGMCMDCallNPC = "player.GetScene().CreateNpc(" .. tCurrentNPC.nTempleteID .. ", player.nX+100, player.nY+100, player.nZ, 0, -1, '"..tCurrentNPC.szNickName.."')"
    SendGMCommand(szGMCMDCallNPC)
end


return UISpeedCall