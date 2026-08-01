-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGMTaskInformation
-- Date: 2022-12-05 17:21:49
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIGMTaskInformation = class("UIGMTaskInformation")

function UIGMTaskInformation:OnEnter(tbTask)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbTask = tbTask
    self:UpdateInfo()
end

function UIGMTaskInformation:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIGMTaskInformation:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCallStartNPC, EventType.OnClick, function(btn)
        local player = GetClientPlayer()
        if self.tbTask.StartNpcTemplateID ~="" then
			SendGMCommand("player.GetScene().CreateNpc(" .. self.tbTask.StartNpcTemplateID .. "," .. player.nX .. "," .. player.nY .. "," .. player.nZ .. ", 0, -1)")
			OutputMessage("MSG_ANNOUNCE_NORMAL", "NPC已创建到你的位置，请关注服务器信息\n")
			OutputMessage("MSG_SYS", "NPC已创建到你的位置，请关注服务器信息\n")
		end
    end)

    UIHelper.BindUIEvent(self.BtnCallEndNPC, EventType.OnClick, function(btn)
        local player = GetClientPlayer()
        if self.tbTask.EndNpcTemplateID ~="" then
			SendGMCommand("player.GetScene().CreateNpc(" .. self.tbTask.EndNpcTemplateID .. "," .. player.nX .. "," .. player.nY .. "," .. player.nZ .. ", 0, -1)")
			OutputMessage("MSG_ANNOUNCE_NORMAL", "NPC已创建到你的位置，请关注服务器信息\n")
			OutputMessage("MSG_SYS", "NPC已创建到你的位置，请关注服务器信息\n")
		end
    end)
end

function UIGMTaskInformation:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIGMTaskInformation:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGMTaskInformation:UpdateInfo()
    UIHelper.SetString(self.LabelTaskID, self.tbTask.ID)
    UIHelper.SetString(self.LabelTaskName, UIHelper.GBKToUTF8(self.tbTask.Name))
    UIHelper.SetString(self.LabelTaskObject, UIHelper.GBKToUTF8(self.tbTask.Object))
    local szNpcNameTemp = UIHelper.GBKToUTF8(g_tTable.NpcTemplate:Search(self.tbTask.StartNpcTemplateID).szName)
    local szLabel = "【" .. self.tbTask.StartNpcTemplateID .. "】 " .. szNpcNameTemp
    UIHelper.SetString(self.LabelStartNpc, szLabel)
    szNpcNameTemp = UIHelper.GBKToUTF8(g_tTable.NpcTemplate:Search(self.tbTask.EndNpcTemplateID).szName)
    szLabel = "【" .. self.tbTask.EndNpcTemplateID .. "】 " .. szNpcNameTemp
    UIHelper.SetString(self.LabelEndNPC, szLabel)
end


return UIGMTaskInformation