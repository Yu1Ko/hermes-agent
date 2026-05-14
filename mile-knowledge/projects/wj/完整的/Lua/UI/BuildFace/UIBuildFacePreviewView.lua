-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIBuildFacePreviewView
-- Date: 2024-04-10 19:47:12
-- Desc: 创角捏脸预览界面
-- ---------------------------------------------------------------------------------

local UIBuildFacePreviewView = class("UIBuildFacePreviewView")
local PageType = 
{
    Cloths      = 1,    
    Widget      = 2,    
    Animation   = 3,    
    Weather     = 4,    
}
local PageTypeName = 
{
    [PageType.Cloths]   = "试穿",
    [PageType.Widget]   = "佩饰",
    [PageType.Animation]= "动作",
    [PageType.Weather]  = "天气",
}
function UIBuildFacePreviewView:OnEnter(nRoleType , nKungfuID)
    self.nRoleType = nRoleType 
    self.nKungfuID = nKungfuID
    self.scriptCommonInteraction = UIHelper.GetBindScript(self.widgetCommonScript)
    self.scriptCommonInteraction:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIBuildFacePreviewView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self.scriptCommonInteraction:OnExit()
    self.scriptCommonInteraction = nil
end

function UIBuildFacePreviewView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        UIMgr.Close(self)
        UIMgr.ShowView(VIEW_ID.PanelBuildFace_Step2)
    end)

    UIHelper.BindUIEvent(self.BtnNext , EventType.OnClick , function ()
        UIMgr.HideView(VIEW_ID.PanelBuildFace_Preview)
        UIMgr.Open(VIEW_ID.PanelModelVideo, self.nRoleType, self.nKungfuID)
    end)
end

function UIBuildFacePreviewView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBuildFacePreviewView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBuildFacePreviewView:UpdateInfo()
    self.moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_SCENE).GetModel(LoginModel.FORCE_ROLE)
    self.tPresetDataList = BuildPresetData.GetPresetData(self.nRoleType, self.nKungfuID)
    self:UpdatePageType()
end

-- 左侧标签页选择
function UIBuildFacePreviewView:UpdatePageType()
    UIHelper.HideAllChildren(self.LayoutLeftType)

    self.tbLoadPrefabIDByPage = {
        [PageType.Cloths] = PREFAB_ID.WidgetBulidFacePreview_Item,
        [PageType.Widget] = PREFAB_ID.WidgetBulidFacePreview_Item,
        [PageType.Animation] = PREFAB_ID.WidgetBulidFacePreview_Item,
        [PageType.Weather] = PREFAB_ID.WidgetBulidFacePreview_Item,
    }

    self.tbPageDefaultCells =
    {
        [PageType.Cloths] = nil,
        [PageType.Widget] = nil,
        [PageType.Animation] = nil,
        [PageType.Weather] = nil,
    } 

    -- 清空ScrollView 内容
    for k, v in pairs(self.tbScrollViewList) do
        UIHelper.HideAllChildren(v)
        UIHelper.SetVisible(v , false)
    end

    local tbPageCell = {}
    for i, szName in ipairs(PageTypeName) do
        if not tbPageCell[i] then
            tbPageCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetDefaultLeftType, self.LayoutLeftType)
            UIHelper.ToggleGroupAddToggle(self.TogGroupTabType, tbPageCell[i].TogAll)
        end
        UIHelper.SetVisible(tbPageCell[i]._rootNode, true)
        tbPageCell[i]:OnEnter(i, szName , function (nPageType)
            self:OnSelectPageHandler(nPageType)
        end)
        UIHelper.LayoutDoLayout(self.LayoutLeftType)
    end

    self.curSelectScrollView = self.tbScrollViewList[PageType.Cloths]
    UIHelper.SetToggleGroupSelectedToggle(self.TogGroupTabType , tbPageCell[1].TogAll)
    tbPageCell[1]:OnInvokeSelect()
end
-- 选中标签页回调处理
function UIBuildFacePreviewView:OnSelectPageHandler(nPageType)
    if self.curSelectScrollView then
        UIHelper.SetVisible(self.curSelectScrollView , false)
    end
    self.curSelectScrollView = self.tbScrollViewList[nPageType]
    UIHelper.SetVisible(self.curSelectScrollView , true)
    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupDefaultList)
    if not self.tbPageDefaultCells[nPageType] then
        local nLoadPrefabID = self.tbLoadPrefabIDByPage[nPageType]
        local tbDefalutDataList = self:_getPageDataList(nPageType)
        local tbDefaultCell = {}
        local onSelectCallback = function(nType , nIndex)
            if nType == PageType.Cloths then
                self:_selectClothsHandler(nIndex)
            elseif nType == PageType.Widget then
            
            elseif nType == PageType.Animation then
                self:_selectAnimationHandler(nIndex)
            elseif nType == PageType.Weather then
                self:_selectWeatherHandler(nIndex)
            end
        end
    
        for i, tbData in ipairs(tbDefalutDataList) do
            if not tbDefaultCell[i] then
                tbDefaultCell[i] = UIHelper.AddPrefab(nLoadPrefabID, self.curSelectScrollView)
            end
    
            UIHelper.SetVisible(tbDefaultCell[i]._rootNode, true)
            tbDefaultCell[i]:OnEnter(i, tbData , onSelectCallback)
        end
        self.tbPageDefaultCells[nPageType] = tbDefaultCell
    end

    for k, v in pairs(self.tbPageDefaultCells[nPageType]) do
        UIHelper.ToggleGroupAddToggle(self.TogGroupDefaultList, v.ToggleSelect)
    end
    
    if table.get_len(self.tbPageDefaultCells[nPageType]) > 0 then
        local nChooseIndex = self:_getPageChildChooseIndex(nPageType)
        UIHelper.SetToggleGroupSelectedToggle(self.TogGroupDefaultList , self.tbPageDefaultCells[nPageType][nChooseIndex].ToggleSelect)
        self.tbPageDefaultCells[nPageType][nChooseIndex]:OnInvokeSelect()
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.curSelectScrollView)
end

function UIBuildFacePreviewView:_getPageChildChooseIndex(nPageType)
    if nPageType == PageType.Cloths then
        return self.nSelectClothsIndex or 1
    elseif nPageType == PageType.Widget then
    
    elseif nPageType == PageType.Animation then
        return self.nSelectAnimationIndex or 1
    elseif nPageType == PageType.Weather then
        local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
        return moduleScene.GetChooseScene()
    end
    return 1
end

function UIBuildFacePreviewView:_getPageDataList(nPageType)
    local tbDefalutList = {}
    if nPageType == PageType.Cloths then
        tbDefalutList = self:_getClothsList()
    elseif nPageType == PageType.Widget then
        tbDefalutList = self:_getWidgetList()
    elseif nPageType == PageType.Animation then
        tbDefalutList = self:_getAnimationList()
    elseif nPageType == PageType.Weather then
        tbDefalutList = self:_getWeatherList()
    end
    return tbDefalutList
end

function UIBuildFacePreviewView:_getClothsList()
    if not self.tPresetCloths then
        local tbDataList = {}
        for k, tbData in ipairs(BuildBodyData.tBodyCloth) do
            table.insert(tbDataList , 
            {
                nType = PageType.Cloths,
                szIcon = tbData.dwIconID,
                szRepresent = tbData.szRepresent
            })
        end
        self.tPresetCloths = tbDataList
    end
    return self.tPresetCloths
end

function UIBuildFacePreviewView:_getWidgetList()
    local tbDataList = {}
    -- {
    --     nType = PageType.Weather,
    -- }
    return tbDataList
end

function UIBuildFacePreviewView:_getWeatherList()
    if not self.tPresetWeather then
        local tbDataList = {}
        for k, v in pairs(BuildFaceWeatherImg) do
            table.insert(tbDataList , 
            {
                nType = PageType.Weather,
                szIcon = v
            })
        end
        self.tPresetWeather = tbDataList
    end
    return self.tPresetWeather
end

function UIBuildFacePreviewView:_getAnimationList()
    if not self.tPresetAnimation then
        local tbDataList = {}
        for k, v in pairs(self.tPresetDataList) do
            table.insert(tbDataList , {
                nType = PageType.Animation,
                szAnimation = v.szOnceAnimation,
                bLoop = false,
            })
            table.insert(tbDataList , {
                nType = PageType.Animation,
                bLoop = true,
                szAnimation = v.szStandbyAnimation
            })
        end
        self.tPresetAnimation = tbDataList
    end
   
    return self.tPresetAnimation
end

function UIBuildFacePreviewView:_selectWeatherHandler(nIndex)
    if self.nSelectWeatherIndex == nIndex then
        return
    end
    self.nSelectWeatherIndex = nIndex
    local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
    local tInfo = Table_GetLoginSceneInfo(nIndex)
    moduleScene.SceneChange(tInfo)

    if nIndex == 4 then
        UIHelper.ShowFullScreenSFX("UI_LOGIN_CREATEROLE_RAIN")
    elseif nIndex == 5 then
        UIHelper.ShowFullScreenSFX("UI_LOGIN_CREATEROLE_SNOW")
    else
        UIHelper.HideFullScreenSFX()
    end
end

function UIBuildFacePreviewView:_selectAnimationHandler(nIndex , bUpdate)
    if self.nSelectAnimationIndex == nIndex and not bUpdate then
        return
    end
   
    if self.tPresetAnimation then
        self.nSelectAnimationIndex = nIndex
        local bLoop = self.tPresetAnimation[nIndex].bLoop
        local szAniPath = self.tPresetAnimation[nIndex].szAnimation
        self.moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_SCENE).GetModel(LoginModel.FORCE_ROLE)
        self.moduleRole:PlayRoleAnimation(bLoop and "loop" or "once", szAniPath , function (_,id)
           
        end)
    end
end

function UIBuildFacePreviewView:_selectClothsHandler(nIndex)
    if self.nSelectClothsIndex == nIndex then
        return
    end
    if self.tPresetCloths then
        if nIndex == 1 and BuildPresetData.tSelectOriginalRepresent then
            LoginMgr.GetModule(LoginModule.LOGIN_SCENE).GetModel(LoginModel.FORCE_ROLE):UpdateRepresentID(BuildPresetData.tSelectOriginalRepresent, self.nRoleType, self.nKungfuID)
        else
            BuildBodyData.UpdateCloth(self.tPresetCloths[nIndex].szRepresent)
            local moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
            moduleRole.UpdateRoleModel()
        end
        if self.nSelectAnimationIndex then
            self:_selectAnimationHandler(self.nSelectAnimationIndex , true)
        end
    end

end


return UIBuildFacePreviewView