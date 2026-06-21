-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIItemChooseAwardTypeView
-- Date: 2023-10-31 10:34:27
-- Desc: 道具奖励选择
-- ---------------------------------------------------------------------------------

local UIItemChooseAwardTypeView = class("UIItemChooseAwardTypeView")

local tbTogType = 
{
    --{szName = "秘籍" , szIconPath = "UIAtlas2_Bag_BagTreasureBox_icon_MiJi", nSelectIndex = 0},  --秘籍屏蔽
    {szName = "书籍" , szIconPath = "UIAtlas2_Bag_BagTreasureBox_icon_ShuJi", nSelectIndex = 1},
    {szName = "材料" , szIconPath = "UIAtlas2_Bag_BagTreasureBox_icon_CaiLiao", nSelectIndex = 2},
    {szName = "五行石" , szIconPath = "UIAtlas2_Bag_BagTreasureBox_icon_WuXingShi", nSelectIndex = 3},
}

function UIItemChooseAwardTypeView:OnEnter(dwBoxBox , dwBoxX)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwBoxBox = dwBoxBox
    self.dwBoxX = dwBoxX
    self:UpdateInfo()
    UIHelper.SetVisible(self._rootNode , true)
end

function UIItemChooseAwardTypeView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIItemChooseAwardTypeView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnUse , EventType.OnClick , function ()
        OpenBox(self.dwBoxBox, self.dwBoxX, self.nSelectIndex)
    end)

    UIHelper.BindUIEvent(self.BtnCancel , EventType.OnClick , function ()
        UIHelper.SetVisible(self._rootNode , false)
    end)
end

function UIItemChooseAwardTypeView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetVisible(self._rootNode , false)
    end)
end

function UIItemChooseAwardTypeView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIItemChooseAwardTypeView:UpdateInfo()
    self.nSelectIndex = tbTogType[1].nSelectIndex

    if not self.bInitCell then
        for i, v in ipairs(tbTogType) do
            local singleLua =  UIHelper.AddPrefab(PREFAB_ID.WidgetTogTypeSingle_WithIcon , self.LayoutCell)

            UIHelper.SetString(singleLua.LabelTogName , v.szName)
    
            UIHelper.SetSpriteFrame(singleLua.ImgType, v.szIconPath)
    
            UIHelper.ToggleGroupAddToggle(self.ToggleGroup , singleLua.TogType)
    
            UIHelper.BindUIEvent(singleLua.TogType , EventType.OnSelectChanged , function ()
                self.nSelectIndex = v.nSelectIndex
            end)
        end
        self.bInitCell = true
        UIHelper.SetTouchEnabled(self.LayoutCell, true)
        UIHelper.SetTouchDownHideTips(self.LayoutCell, false)
        UIHelper.SetTouchDownHideTips(self.TouchButton, false)
    end
    UIHelper.SetToggleGroupSelected(self.ToggleGroup , 0)
end


return UIItemChooseAwardTypeView