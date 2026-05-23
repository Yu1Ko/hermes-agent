-- ---------------------------------------------------------------------------------
-- Author: KSG
-- Name: UILiveFBShowPlayerInfo
-- Date: 2026-03-23
-- Desc: 副本观战 - 选中玩家信息面板（挂载在 WidgetCurrentPlayerInfo 节点）
-- ---------------------------------------------------------------------------------

local UILiveFBShowPlayerInfo = class("UILiveFBShowPlayerInfo")

-- 低血量闪光阈值
local LOW_HEALTH_THRESHOLD = 0.3

function UILiveFBShowPlayerInfo:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwSelectPlayerID = nil
    self.nCachedLife = nil
    self.nCachedMaxLife = nil

    self:OnSelectPlayerChanged(nil)
end

function UILiveFBShowPlayerInfo:OnExit()
    self.bInit = false
    -- 清理动态创建的 WidgetHead Prefab，防止缓存复用时重复创建
    if self.WidgetRoomPlayerCell then
        UIHelper.RemoveAllChildren(self.WidgetRoomPlayerCell)
    end
    self.scriptHead = nil
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UILiveFBShowPlayerInfo:BindUIEvent()

end

function UILiveFBShowPlayerInfo:RegEvent()
    -- 选中玩家变化（来自 UILiveRaidTeamMember 的通知）
    Event.Reg(self, EventType.ON_OB_SELECT_PLAYER_CHANGED, function(dwPlayerID)
        self:OnSelectPlayerChanged(dwPlayerID)
    end)

    -- 团队信息变化 → 刷新选中玩家血量（监听 RoomVoiceData 转发的 Lua 内部事件）
    Event.Reg(self, EventType.ON_DUNGEON_OB_COMPETITOR_VARIABLE_INFO_UPDATE_UI, function()
        self:UpdateSelectPlayerHealth()
    end)
end

function UILiveFBShowPlayerInfo:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- 选中玩家切换与数据更新
-- ----------------------------------------------------------

-- 切换选中玩家
function UILiveFBShowPlayerInfo:OnSelectPlayerChanged(dwPlayerID)
    self.dwSelectPlayerID = dwPlayerID
    self.nCachedLife = nil
    self.nCachedMaxLife = nil
    self:UpdateInfo()
end

-- 全量刷新
function UILiveFBShowPlayerInfo:UpdateInfo()
    if not self.dwSelectPlayerID then
        UIHelper.SetString(self.LabelPlayerName, "自由视角")
        UIHelper.SetVisible(self._rootNode, false)
        return
    end

    local dwPlayerID, szName, llCurrentLife, llMaxLife, nTotalEquipScore, dwKungfuID, nMemberIndex
        = OBDungeonData.GetDungeonCompetitor(self.dwSelectPlayerID)
    if not dwPlayerID then
        return
    end

    -- 更新头像区域
    self:UpdatePlayerHead(dwPlayerID, szName, dwKungfuID)
    -- 更新血条
    self:UpdateBlood(llCurrentLife, llMaxLife)
    if self.LabelBlue then
        UIHelper.SetVisible(self.LabelBlue, false)
    end
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

-- 刷新血量（增量，避免无变化时重复更新）
function UILiveFBShowPlayerInfo:UpdateSelectPlayerHealth()
    if not self.dwSelectPlayerID then
        return
    end

    local dwPlayerID, szName, llCurrentLife, llMaxLife, nTotalEquipScore, dwKungfuID, nMemberIndex
        = OBDungeonData.GetDungeonCompetitor(self.dwSelectPlayerID)
    if not dwPlayerID then
        return
    end

    self:UpdateQiEnergy(dwKungfuID)

    local pPlayer = PlayerData.GetPlayer(dwPlayerID)
    if pPlayer.nMoveState == MOVE_STATE.ON_DEATH then
        llCurrentLife = 0
    end

    -- 缓存检查
    if self.nCachedLife == llCurrentLife and self.nCachedMaxLife == llMaxLife then
        return
    end

    self:UpdateBlood(llCurrentLife, llMaxLife)
end

-- 更新头像
function UILiveFBShowPlayerInfo:UpdatePlayerHead(dwPlayerID, szName, dwKungfuID)
    -- 设置被观战玩家名称
    if self.LabelPlayerName then
        UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(szName or ""), 10)
    end
    -- 加载/刷新 WidgetHead
    if not self.scriptHead then
        self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetRoomPlayerCell, dwPlayerID)
        if self.scriptHead then
            self.scriptHead:SetTouchEnabled(false)
        end
    else
        self.scriptHead.dwID = dwPlayerID
        self.scriptHead:UpdateInfo()
    end
    -- 设置心法图标
    if self.scriptHead and dwKungfuID then
        self.scriptHead:SetHeadWithMountKungfuID(dwKungfuID)
    end
end

-- 更新血条
function UILiveFBShowPlayerInfo:UpdateBlood(llCurrentLife, llMaxLife)
    self.nCachedLife = llCurrentLife
    self.nCachedMaxLife = llMaxLife

    local nPercent = 100
    if llMaxLife and llMaxLife > 0 then
        nPercent = 100 * llCurrentLife / llMaxLife
    end

    UIHelper.SetProgressBarPercent(self.SliderBlood, nPercent)
    UIHelper.SetString(self.LabelBlood, string.format("%d/%d", llCurrentLife or 0, llMaxLife or 0))

    -- 护盾血条暂时隐藏
    if self.SliderBloodDefense then
        UIHelper.SetVisible(self.SliderBloodDefense, false)
    end

    -- 低血量闪光特效
    if self.SFXBloodLight then
        local bLowHealth = nPercent / 100 <= LOW_HEALTH_THRESHOLD and llCurrentLife > 0
        UIHelper.SetVisible(self.SFXBloodLight, bLowHealth)
    end
end

function UILiveFBShowPlayerInfo:UpdateQiEnergy(dwKungfuID)
    for i = 1, #self.QiControlList do
        local hQiControl = self.QiControlList[i]
        UIHelper.SetActiveAndCache(self, hQiControl, false)
    end

    local bHDKungfu = TabHelper.IsHDKungfuID(dwKungfuID)
    if not bHDKungfu then
        return
    end

    local player = PlayerData.GetPlayer(self.dwSelectPlayerID)
    if not player then
        return
    end

    local nQiRedSP = player.nCurrentQiRedSP or 0
    local nSpecialQi = player.nCurrentQiSP or 0
    local nTotalQi = nQiRedSP + nSpecialQi
    for i = 1, #self.QiControlList do
        local hQiControl = self.QiControlList[i]
        UIHelper.SetActiveAndCache(self, hQiControl, i <= nTotalQi)
    end
end

return UILiveFBShowPlayerInfo
