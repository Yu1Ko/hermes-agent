-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelCollectionDungeon
-- Date: 2024-02-22 15:22:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelCollectionDungeon = class("UIPanelCollectionDungeon")

function UIPanelCollectionDungeon:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    CollectionBossData.Init()
    self:ToggleGroupAddToggle()
    self:SetCamp(CAMP.GOOD)
end

function UIPanelCollectionDungeon:OnExit()
    self.bInit = false

    if self.hModelView then
        self.hModelView:release()
        self.hModelView = nil
    end

    UITouchHelper.UnBindModel()
    self:UnRegEvent()
end

function UIPanelCollectionDungeon:BindUIEvent()
    UIHelper.BindUIEvent(self.TogNavigation01, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self:SetCamp(CAMP.GOOD)
        end
    end)

    UIHelper.BindUIEvent(self.TogNavigation02, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self:SetCamp(CAMP.EVIL)
        end
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

end

function UIPanelCollectionDungeon:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelCollectionDungeon:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelCollectionDungeon:ToggleGroupAddToggle()
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation, self.TogNavigation01)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation, self.TogNavigation02)
end

function UIPanelCollectionDungeon:UpdateInfo()

    -- UIHelper.RemoveAllChildren(self.WidgetTopContainer)
    -- UIHelper.RemoveAllChildren(self.ScrollViewContent)

    local func = function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelTitle, tArgs.szName)
        UIHelper.SetString(scriptContainer.LabelSelect, tArgs.szName)
        -- UIHelper.SetVisible(scriptContainer.BtnForToggle, false)
        -- UIHelper.SetVisible(scriptContainer.WidgetSelecctImgTree, tArgs.nChildCount ~= 0)
        -- UIHelper.SetVisible(scriptContainer.ImgNormalIconTree, tArgs.nChildCount ~= 0)
        -- UIHelper.SetVisible(scriptContainer.WidgetSelecctImg, tArgs.nChildCount == 0)
        -- UIHelper.SetVisible(scriptContainer.ImgNormalIcon, tArgs.nChildCount == 0)
    end

    local scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetVertical_Navigation)
    scriptScrollViewTree:ClearContainer()
    UIHelper.SetupScrollViewTree(scriptScrollViewTree, PREFAB_ID.WidgetFengYunLuTitle, PREFAB_ID.WidgetFengYunLuChildNavigation, func, self.tbBossList)
end

function UIPanelCollectionDungeon:UpdateBossInfo()
    local tbBossInfo = self.tbBossInfo
    UIHelper.SetString(self.LabelBossName, UIHelper.GBKToUTF8(tbBossInfo.szName))

    local szText = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tbBossInfo.szDesc), true)
    UIHelper.SetString(self.LabeStoryCentre, szText)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewStory)
    self:UpdateNPCModel()
end

function UIPanelCollectionDungeon:UpdateNPCModel()
	local tNpcInfo = CollectionBossData.GetBossByID(self.tbBossInfo.dwID)

	if not self.hModelView then
		self.hModelView = NpcModelView.CreateInstance(NpcModelView)
		self.hModelView:ctor()
		self.hModelView:init(nil, false, true, Const.COMMON_SCENE, "DungeonDetail")
		self.hModelView:SetCamera(Const.MiniScene.CollectionDungeonView.CameraConfig)
		self.MiniScene:SetScene(self.hModelView.m_scene)
	end

	self.hModelView:LoadNpcRes(tNpcInfo.dwModelID, false)
	self.hModelView:UnloadModel()
	self.hModelView:LoadModel()
	self.hModelView:PlayAnimation("Idle", "loop")
	self.hModelView:SetTranslation(table.unpack(Const.MiniScene.CollectionDungeonView.ModelPos))
	self.hModelView:SetYaw(Const.MiniScene.CollectionDungeonView.fYaw)
	self.hModelView:SetScaling(tNpcInfo.fModelScaleMB)

	UITouchHelper.BindModel(self.TouchBackground, self.hModelView)
end

function UIPanelCollectionDungeon:SetCamp(nCamp)
    if self.nCamp == nCamp then return end
    self.nCamp = nCamp
    self.tbBossList = self:GetScrollViewTreeInfo()
    self:UpdateInfo()
end

function UIPanelCollectionDungeon:SetBossInfo(tbBossInfo)
    self.tbBossInfo = tbBossInfo
    self:UpdateBossInfo()
end

function UIPanelCollectionDungeon:GetScrollViewTreeInfo()
    if self.tbScrollViewTreeInfo and self.tbScrollViewTreeInfo[self.nCamp] then
        return self.tbScrollViewTreeInfo[self.nCamp]
    end
    if not self.tbScrollViewTreeInfo then self.tbScrollViewTreeInfo = {} end

    local tbBossList = CollectionBossData.GetBossListByCamp(self.nCamp)
    local tbData = {}
    for nClass, tbList in ipairs(tbBossList) do
        local Info = {}
        Info.tArgs = {szName = CollectionBossData.GetBossTypeName(nClass), nChildCount = #tbList}
        if #tbList > 0 then
            Info.tItemList = {}
        end
        for nIndex, tbData in ipairs(tbList) do
            table.insert(Info.tItemList, {tArgs = {szTitle = UIHelper.GBKToUTF8(tbData.szName),
                                                    szContent = "",
                                                    toggleGroup = self.ToggleGroupChildNavigation,
                                                    onSelectChangeFunc = function(_, bSelect)
                                                        if bSelect then self:SetBossInfo(tbData) end
                                                    end}})
        end

        Info.fnSelectedCallback = function(bSelect, scriptContainer)
            if bSelect then
                local tbScripts = scriptContainer:GetItemScript()
                tbScripts[1]:SetSelected(true)
            end
        end
        table.insert(tbData, Info)
    end
    self.tbScrollViewTreeInfo[self.nCamp] = tbData
    return self.tbScrollViewTreeInfo[self.nCamp]
end

return UIPanelCollectionDungeon