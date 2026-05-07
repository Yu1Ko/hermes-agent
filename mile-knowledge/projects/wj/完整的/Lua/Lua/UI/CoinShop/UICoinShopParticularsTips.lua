-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopParticularsTips
-- Date: 2023-04-07 09:47:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

local tCollectTips = {
    {sz="如何收集外观?", b=true},
    {sz="方法1：穿上对应外观名的装备1次，即可完成收集。"},
    {sz="方法2：消耗一定数量的【兵甲图谱】，即可完成收集。"},
    {sz="如何永久拥有收集的外观？", b=true},
    {sz="收集后的外观，通过通宝购买后即可永久拥有。"},
    {sz="收集道具【兵甲图谱】获得的途径？", b=true},
    {sz="途径1：活动【美人图·潜行】"},
    {sz="途径2：活动【美人图·画像】"},
    {sz="途径3：活动【游历江湖采仙草】"},
    {sz="途径4：活动【寻龙勘脉窥天机】"},
    {sz="途径5：生活技艺【挖宝】"},
    {sz="途径6：秘境首领掉落"},
    {sz="途径7：主城侠义值商店购买"},
    {sz="途径8：特定活动外观商城购买"},
}



local UICoinShopParticularsTips = class("UICoinShopParticularsTips")

function UICoinShopParticularsTips:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICoinShopParticularsTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopParticularsTips:BindUIEvent()
    
end

function UICoinShopParticularsTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopParticularsTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopParticularsTips:OnInitCollectTips(tips1, tips2)
    UIHelper.SetVisible(self.WidgetContent01, true)
    UIHelper.SetVisible(self.WidgetContent02, false)
    UIHelper.SetString(self.LabelSuit01, tips1)
    UIHelper.SetString(self.LabelPiece01, tips2)
    if not self.bInitCollect then
        UIHelper.RemoveAllChildren(self.ScrollViewContent01)
        for _, szTips in ipairs(tCollectTips) do
            if szTips.b then
                UIHelper.AddPrefab(PREFAB_ID.WidgetContentTitle, self.ScrollViewContent01, szTips.sz)
            else
                UIHelper.AddPrefab(PREFAB_ID.WidgetContent, self.ScrollViewContent01, szTips.sz)
            end
        end
        UIHelper.ScrollViewDoLayout(self.ScrollViewContent01)
        UIHelper.SetTouchDownHideTips(self.ScrollViewContent01, false)
        self.bInitCollect = true
    end
    UIHelper.ScrollToTop(self.ScrollViewContent01, 0)
end

function UICoinShopParticularsTips:OnInitSmallTips(tips1, tips2)
    UIHelper.SetVisible(self.WidgetContent01, false)
    UIHelper.SetVisible(self.WidgetContent02, true)
    UIHelper.SetString(self.LabelSuit02, tips1)
    UIHelper.SetString(self.LabelPiece02, tips2)
    UIHelper.LayoutDoLayout(self.WidgetSuit02)
end

function UICoinShopParticularsTips:UpdateInfo()

end


return UICoinShopParticularsTips