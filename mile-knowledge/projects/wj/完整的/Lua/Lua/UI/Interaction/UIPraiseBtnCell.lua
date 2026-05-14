-- ---------------------------------------------------------------------------------
-- Name: UIPraiseBtnCell
-- Prefab: WidgetBtnIcon
-- ---------------------------------------------------------------------------------

local UIPraiseBtnCell = class("UIPraiseBtnCell")

function UIPraiseBtnCell:_LuaBindList()
    self.ImgIcon1          = self.ImgIcon1 --- 图标
    self.LableNum1         = self.LableNum1 --- 等级
end

function UIPraiseBtnCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.SetSwallowTouches(self.BtnIcon, false)
end

function UIPraiseBtnCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPraiseBtnCell:BindUIEvent()
    -- UIHelper.BindUIEvent(self.BtnIcon, EventType.OnClick, function ()
    --     if self.func then
    --         self.func()
    --     end
    -- end)
end

function UIPraiseBtnCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPraiseBtnCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local Type2Img = {
	[PRAISE_TYPE.TEAM_LEADER]   = "UIAtlas2_Interaction_FriendList_icon_01", -- 好团长
	[PRAISE_TYPE.MASTER]        = "UIAtlas2_Interaction_FriendList_icon_02", -- 好师父
	[PRAISE_TYPE.BIAO_SHI]      = "UIAtlas2_Interaction_FriendList_icon_03", -- 镖师
	[PRAISE_TYPE.GREAT_LEADER]  = "UIAtlas2_Interaction_FriendList_icon_04", -- 当前版本的副本团长点赞
	[PRAISE_TYPE.WAR_LEADER]    = "UIAtlas2_Interaction_FriendList_icon_05", -- 好指挥
	[PRAISE_TYPE.ARENA]         = "UIAtlas2_Interaction_FriendList_icon_06", -- 竞技场
	[PRAISE_TYPE.BATTLE_FIELD]  = "UIAtlas2_Interaction_FriendList_icon_07", -- 战场
	[PRAISE_TYPE.HELPER]        = "UIAtlas2_Interaction_FriendList_icon_08", -- 友爱之人
	[PRAISE_TYPE.PERSONAL_CARD] = "UIAtlas2_Interaction_FriendList_icon_09", -- 名片
}

function UIPraiseBtnCell:UpdateInfo(tInfo)
    local id = tInfo.id
    local nLevel = tInfo.nLevel

    UIHelper.SetSpriteFrame(self.ImgIcon1, Type2Img[id])

    UIHelper.SetString(self.LableNum1, nLevel)
end

function UIPraiseBtnCell:SetClickCallBack(func)
    self.func = func
end

return UIPraiseBtnCell