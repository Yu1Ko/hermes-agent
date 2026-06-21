-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIFengYuTongZhou
-- Date: 2024-03-29 17:20:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIFengYuTongZhou = class("UIFengYuTongZhou")

local TongMemberAward =
{
    [1] = {{5,11794,1},{5,24447,6},{5,40608,1000},{5,48800,1}}, --1
    [2] = {{5,24447,5},{5,40608,600},{5,48800,1}}, --2
    [3] = {{5,24447,4},{5,40608,500},{5,48800,1}}, --3
    [4] = {{5,24447,3},{5,40608,400},{5,48800,1}}, --4~6
    [5] = {{5,24447,3},{5,40608,300},{5,48800,1}}, --7~10
    [6] = {{5,24447,2},{5,40608,300},{5,48807,1}}, --11~50
}

local TongBossAward =
{
    [1] = {{5,69676,8},}, --1
    [2] = {{5,69676,7},}, --2
    [3] = {{5,69676,6},}, --3
    [4] = {{5,69676,5},}, --4~6
    [5] = {{5,69676,3},}, --7~10
    [6] = {}, --11~50
}

local TongAwardNumber = {
    [1] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_ranking01.png",
    [2] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_ranking02.png",
    [3] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_ranking03.png",
    [4] = "4-6",
    [5] = "7-10",
    [6] = "11-50",
}

local szTongMemberAward = "UIAtlas2_HuaELou_FengYuTongZhou_ImgChest"
local szTongBossAward = {
    [1] = "UIAtlas2_HuaELou_FengYuTongZhou_ImgTongBao06", --1
    [2] = "UIAtlas2_HuaELou_FengYuTongZhou_ImgTongBao05", --2
    [3] = "UIAtlas2_HuaELou_FengYuTongZhou_ImgTongBao04", --3
    [4] = "UIAtlas2_HuaELou_FengYuTongZhou_ImgTongBao03", --4~6
    [5] = "UIAtlas2_HuaELou_FengYuTongZhou_ImgTongBao02", --7~10
    [6] = "UIAtlas2_HuaELou_FengYuTongZhou_ImgTongBao01", --11~50
}

local szOnClickTipsMember= "宝堆奖励\n神兵宝甲榜前三名帮会中符合领取条件的帮众奖励。"
local szOnClickTips = {
    [1] = "10万通宝\n神兵宝甲榜第一名帮会的帮主个人奖励。", --1
    [2] = "5万通宝\n神兵宝甲榜第二名帮会的帮主个人奖励。", --2
    [3] = "4万通宝\n神兵宝甲榜第三名帮会的帮主个人奖励。", --3
    [4] = "3万通宝\n神兵宝甲榜第四至六名帮会的帮主个人奖励。", --4~6
    [5] = "2万通宝\n神兵宝甲榜第七至十名帮会的帮主个人奖励。", --7~10
    [6] = "1万通宝\n神兵宝甲榜第十一至五十名帮会的帮主个人奖励。", --11~50
}

function UIFengYuTongZhou:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIFengYuTongZhou:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFengYuTongZhou:BindUIEvent()

end

function UIFengYuTongZhou:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIFengYuTongZhou:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

--端游拼死的ini，我们加载上去
function UIFengYuTongZhou:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewReward)

    for i = 1, 6, 1 do
        if i <= 3 then
            self:UpdateRewardCell(PREFAB_ID.WidgetFengYuTongZhouRewardCellBig, i <= 3, i)
        else
            self:UpdateRewardCell(PREFAB_ID.WidgetFengYuTongZhouRewardCellSmall, i <= 3, i)
        end

    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewReward)
end

function UIFengYuTongZhou:UpdateRewardCell(nPrefabID, bBig, nIndex)
    local scriptReward = UIHelper.AddPrefab(nPrefabID, self.ScrollViewReward)
    if scriptReward then
        if bBig then
            UIHelper.SetSpriteFrame(scriptReward.ImgIconRank, TongAwardNumber[nIndex])
        else
            UIHelper.SetString(scriptReward.LabelTime, TongAwardNumber[nIndex])
        end

        if bBig then
            self:UpdateTongMemberRewardImg(scriptReward)
        end
        self:UpdateReward(nIndex, TongMemberAward, scriptReward.LayoutRewardBangZhong)
        self:UpdateReward(nIndex, TongBossAward, scriptReward.LayoutRewardBangZhu)
        self:UpdateTongBossRewardImg(scriptReward, nIndex)
    end
end

function UIFengYuTongZhou:UpdateReward(nIndex, tAward, LayoutReward)
    for k, itemInfo in ipairs(tAward[nIndex]) do
        local itemIconScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHuaELouReward, LayoutReward, itemInfo[1], itemInfo[2], itemInfo[3])
        if itemIconScript then
            itemIconScript:SetClickCallback(function ()
                TipsHelper.ShowItemTips(nil, itemInfo[1], itemInfo[2])
            end)
            UIHelper.SetVisible(itemIconScript.ImgNotReady, false)
        end
    end
    UIHelper.LayoutDoLayout(LayoutReward)
end

function UIFengYuTongZhou:UpdateTongMemberRewardImg(scriptReward)
    local itemIconScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHuaELouReward, scriptReward.LayoutRewardBangZhong,nil,nil,nil,nil,szTongMemberAward)
    if itemIconScript then
        itemIconScript:SetClickCallback(function ()
            TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, itemIconScript._rootNode, szOnClickTipsMember)
        end)
        UIHelper.SetVisible(itemIconScript.ImgNotReady, false)
    end
end

function UIFengYuTongZhou:UpdateTongBossRewardImg(scriptReward, nIndex)
    local itemIconScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHuaELouReward, scriptReward.LayoutRewardBangZhu,nil,nil,nil,nil,szTongBossAward[nIndex])
    if itemIconScript then
        itemIconScript:SetClickCallback(function ()
            TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, itemIconScript._rootNode, szOnClickTips[nIndex])
        end)
        UIHelper.SetVisible(itemIconScript.ImgNotReady, false)
    end
end

return UIFengYuTongZhou