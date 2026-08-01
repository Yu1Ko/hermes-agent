-- ---------------------------------------------------------------------------------
-- Name: UIPraiseStatusCell
-- Prefab: WidgetStatus
-- ---------------------------------------------------------------------------------

local UIPraiseStatusCell = class("UIPraiseStatusCell")

function UIPraiseStatusCell:_LuaBindList()
    self.ImgStatus01       = self.ImgStatus01 --- 图标
    self.LableStatus01     = self.LableStatus01 --- 名称
    self.LableLevel        = self.LableLevel --- 等级
    self.ProgressBar01     = self.ProgressBar01 --- 进度条
    self.LableNum01        = self.LableNum01 -- 数量
    self.LableComment      = self.LableComment --- 详情
end

function UIPraiseStatusCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIPraiseStatusCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPraiseStatusCell:BindUIEvent()

end

function UIPraiseStatusCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPraiseStatusCell:UnRegEvent()
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

function UIPraiseStatusCell:UpdateInfo(tInfo)
    local info = tInfo.info
    local id = tInfo.id
    local nCount = tInfo.nCount
    local nLevel = tInfo.nLevel
    UIHelper.SetString(self.LableStatus01, UIHelper.GBKToUTF8(string.format(info.title)) )


    local input = UIHelper.GBKToUTF8(info.desc)
    local _, _, desc = string.find(input, 'text="(.-)"')
    UIHelper.SetString(self.LableComment, desc)

    UIHelper.SetSpriteFrame(self.ImgStatus01, Type2Img[id])

    UIHelper.SetString(self.LableLevel, string.format(g_tStrings.STR_LEVEL_FARMAT, nLevel))

    local nLevelTotalCapacity = PersonLabel_GetLevelCount(nLevel, id)
    if nLevelTotalCapacity == 1 and nLevel == 1 then
        nLevelTotalCapacity = 0
    end

    local nNextLevelTotalCapacity = PersonLabel_GetLevelCount(nLevel + 1, id)
    local nNextLevelCapacity = nNextLevelTotalCapacity - nLevelTotalCapacity
    if nNextLevelCapacity == 0 then
        nNextLevelCapacity = 1
    end

    local nExp = nCount - nLevelTotalCapacity

    local szNum = string.format("%d/%d", nExp, nNextLevelCapacity)
    UIHelper.SetString(self.LableNum01, szNum)

    UIHelper.SetProgressBarPercent(self.ProgressBar01, nExp * 100.0/ nNextLevelCapacity)
end

return UIPraiseStatusCell