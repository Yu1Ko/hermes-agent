
SceneHelper = SceneHelper or {className = "SceneHelper"}
local self = SceneHelper

self.tbEventHandler = {}
self.tbSceneState = self.tbSceneState or setmetatable({}, {__mode = "k"})
self.nExSceneRefCount = self.nExSceneRefCount or 0
self.nLoadingSceneCount = self.nLoadingSceneCount or 0

local function GetSceneState(scene)
    if not scene then
        return nil
    end

    self.tbSceneState = self.tbSceneState or setmetatable({}, {__mode = "k"})
    local tSceneState = self.tbSceneState[scene]
    if not tSceneState then
        tSceneState = {}
        self.tbSceneState[scene] = tSceneState
    end

    return tSceneState
end

local function UpdateLoadingState(nDelta)
    self.nLoadingSceneCount = math.max((self.nLoadingSceneCount or 0) + nDelta, 0)
    self.bIsLoading = self.nLoadingSceneCount > 0
end

local function ClearSceneLoadState(scene)
    local tSceneState = self.tbSceneState and self.tbSceneState[scene]
    if not tSceneState then
        return
    end

    if tSceneState.nSceneLoadTimerID and tSceneState.tbProgressHandler then
        Timer.DelTimer(tSceneState.tbProgressHandler, tSceneState.nSceneLoadTimerID)
    end
    if tSceneState.tbProgressHandler then
        Event.UnRegAll(tSceneState.tbProgressHandler)
    end

    tSceneState.nSceneLoadTimerID = nil
    tSceneState.tbProgressHandler = nil

    if tSceneState.bDispatchProgress then
        tSceneState.bDispatchProgress = nil
        UpdateLoadingState(-1)
    end
end

function SceneHelper.Init()
    SceneHelper.tbMiniScene = {}
    SceneHelper.ModelsMiniScene = nil
    SceneHelper.hModelsMiniScene = nil
    self.tbSceneState = setmetatable({}, {__mode = "k"})
    self.nExSceneRefCount = 0
    self.nLoadingSceneCount = 0
    self.bIsLoading = false

    Event.Reg(self.tbEventHandler, EventType.OnAccountLogout, function()
        SceneHelper.PauseEngineGrainAndCA()
    end)

    Event.Reg(self.tbEventHandler, EventType.UILoadingFinish, function(nMapID)
        if nMapID == nil then return end
        SceneHelper.ResumeEngineGrainAndCA()
    end)
end

function SceneHelper.UnInit()
    if SceneHelper.ModelsMiniScene then
        SceneHelper.ModelsMiniScene:release()
        SceneHelper.ModelsMiniScene = nil
    end

    local hModelsMiniScene = SceneHelper.hModelsMiniScene
    if hModelsMiniScene then
        SceneHelper.Delete(hModelsMiniScene)
        SceneHelper.hModelsMiniScene = nil
    end

    if SceneHelper.tbMiniScene then
		local tModelFreeQueue = SceneHelper.tbMiniScene
		for _, hModelView in ipairs(tModelFreeQueue) do
			hModelView:release()
		end
	end
	SceneHelper.tbMiniScene = {}
    self.tbSceneState = setmetatable({}, {__mode = "k"})
    self.nExSceneRefCount = 0
    self.nLoadingSceneCount = 0
    self.bIsLoading = false

    Event.UnRegAll(self.tbEventHandler)
end

function SceneHelper.IsLoading()
    return SceneHelper.bIsLoading
end

function SceneHelper.Create(szSceneFile, bDisableForceload, bCoinShop, bDispatchProgress)
    szSceneFile = szSceneFile or "data\\source\\maps\\HD商城_2022_灰_001\\HD商城_2022_灰_001.jsonmap"
    LOG.INFO("SceneHelper.Create start sceneFile=%s dispatchProgress=%s refCount=%d", tostring(szSceneFile), tostring(bDispatchProgress), self.nExSceneRefCount or 0)

    local bNeedPause = (self.nExSceneRefCount or 0) == 0
    if bNeedPause then
        UIMgr.HideLayer(UILayer.Scene)
        SceneHelper.PauseEngineGrainAndCA()
    end

    local scene = KG3DEngine.NewExScene(UTF8ToGBK(szSceneFile), bDisableForceload, bCoinShop)
    if not scene then
        if bNeedPause then
            SceneHelper.ResumeEngineGrainAndCA()
            UIMgr.ShowLayer(UILayer.Scene)
        end
        LOG.ERROR("SceneHelper.Create failed sceneFile=%s", tostring(szSceneFile))
        return nil
    end

    self.nExSceneRefCount = (self.nExSceneRefCount or 0) + 1
    local tSceneState = GetSceneState(scene)
    tSceneState.bDeleting = nil
    LOG.INFO("SceneHelper.Create success scene=%s sceneFile=%s refCount=%d", tostring(scene), tostring(szSceneFile), self.nExSceneRefCount or 0)

    if bDispatchProgress then
        tSceneState.bDispatchProgress = true
        tSceneState.tbProgressHandler = {}
        UpdateLoadingState(1)

        tSceneState.nSceneLoadTimerID = Timer.AddFrameCycle(tSceneState.tbProgressHandler, 2, function()
            local szType, nValue = scene:GetLoadingProcess()
            if szType == "_error0" then
                ClearSceneLoadState(scene)
            end
        end)

        Event.Reg(tSceneState.tbProgressHandler, "SCENE_CALL_BACK", function(szEventType, dwID, fProcess)
            if szEventType == "GetLoadingProcess" then
                local nProcess = math.floor(fProcess * 100)

                Event.Dispatch(EventType.OnMiniSceneLoadProgress, nProcess)

                if nProcess >= 100 then
                    ClearSceneLoadState(scene)
                end
            end
        end)
    end

    return scene
end

function SceneHelper.Delete(scene)
    if scene then
        local tSceneState = GetSceneState(scene)
        if tSceneState.bDeleting then
            LOG.INFO("SceneHelper.Delete skip scene=%s reason=deleting", tostring(scene))
            return
        end

        LOG.INFO("SceneHelper.Delete request scene=%s refCount=%d", tostring(scene), self.nExSceneRefCount or 0)
        tSceneState.bDeleting = true
        ClearSceneLoadState(scene)
        Timer.AddFrame(SceneHelper, 1, function ()
            ClearSceneLoadState(scene)
            KG3DEngine.DeleteExScene(scene)
            if self.tbSceneState then
                self.tbSceneState[scene] = nil
            end

            local nRefCountBefore = self.nExSceneRefCount or 0
            self.nExSceneRefCount = math.max(nRefCountBefore - 1, 0)
            LOG.INFO("SceneHelper.Delete complete scene=%s refCount=%d->%d", tostring(scene), nRefCountBefore, self.nExSceneRefCount)
            if self.nExSceneRefCount == 0 then
                SceneHelper.ResumeEngineGrainAndCA()
                UIMgr.ShowLayer(UILayer.Scene)
            end
        end)
    end
end

function SceneHelper.GetModelsMiniScene(bCreateIfNil)
    local hModelView = SceneHelper.ModelsMiniScene
	local szSceneName = "MiniScene_Models"
	if not hModelView and bCreateIfNil then
        local szModelsMiniScene = "data\\source\\maps\\HD商城_2022_灰_001\\HD商城_2022_灰_001.jsonmap"

		hModelView = ModelsView.CreateInstance(ModelsView)
        hModelView:ctor()
        SceneHelper.hModelsMiniScene = SceneHelper.Create(szModelsMiniScene, true, true, true)
        hModelView:Init3D({bModLod = false, szName = szSceneName, scene = SceneHelper.hModelsMiniScene})
        SceneHelper.ModelsMiniScene = hModelView
	end

    return hModelView
end

function SceneHelper.PauseEngineGrainAndCA()
    self.bLastGrain = KG3DEngine.GetPostRenderGrainEnable()
    self.bLastCA = KG3DEngine.GetPostRenderChromaticAberrationEnable()

    KG3DEngine.SetPostRenderGrainEnable(false)
    KG3DEngine.SetPostRenderChromaticAberrationEnable(false)
end

function SceneHelper.ResumeEngineGrainAndCA()
    if self.bLastGrain ~= nil then
        KG3DEngine.SetPostRenderGrainEnable(self.bLastGrain)
        self.bLastGrain = nil
    end

    if self.bLastCA ~= nil then
        KG3DEngine.SetPostRenderChromaticAberrationEnable(self.bLastCA)
        self.bLastCA = nil
    end
end








-- 老的方式创建和删除场景
function SceneHelper.NewScene_Old(szSceneFilePath, szName)
    if string.is_nil(szSceneFilePath) then return end

    UIMgr.HideLayer(UILayer.Scene)
    return KG3DEngine.NewScene(szSceneFilePath, szName)
end

function SceneHelper.DeleteScene_Old(scene)
    if not scene then return end

    KG3DEngine.DeleteScene(scene)
    UIMgr.ShowLayer(UILayer.Scene)
end




