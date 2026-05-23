-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICameraEditorView
-- Date: 2022-11-08 11:21:09
-- Desc: ?
-- ---------------------------------------------------------------------------------



-- ==========================================================================
-- 外观商城
-- ==========================================================================
local tbRangeList_Shop =
{
    [1] = {-500, 50},       -- X
    [2] = {-200, 800},      -- Y
    [3] = {-1500, 100},      -- Z
    [4] = {-8, 8},          -- Yaw
    [5] = {-30, 30},        -- OffsetX
    [6] = {-90, 90},        -- RotX
    [7] = {-100, 100}, -- ModelX
    [8] = {-100, 100},     -- ModelY
    [9] = {-100, 100},   -- ModelY
}

local tbTitleList_Shop =
{
    [1] = "X",
    [2] = "Y",
    [3] = "Z",
    [4] = "Yaw",
    [5] = "OffsetX",
    [6] = "RotX",
    [7] = "ModelX",
    [8] = "ModelY",
    [9] = "ModelZ",
}

-- ==========================================================================
-- 试穿界面
-- ==========================================================================
local tbRangeList_Preview =
{
    [1] = {-500, 500},  -- x
    [2] = {-300, 300},     -- y
    [3] = {-1000, 1000},   -- z
    [4] = {-300, 300}, -- look_x
    [5] = {-300, 300},     -- look_y
    [6] = {-300, 300},   -- look_z
    [7] = {-8, 8},          -- yaw
    [8] = {0, 3},           -- fovY
    [9] = {0, 5},           -- aspect
    [10] = {0, 50},         -- near
    [11] = {0, 80000},      -- far
    [12] = {-500, 500},        -- model_x
    [13] = {-300, 300},            -- model_y
    [14] = {-1000, 1000},          -- model_z
}

local tbTitleList_Preview =
{
    [1] = "X",
    [2] = "Y",
    [3] = "Z",
    [4] = "look_x",
    [5] = "look_y",
    [6] = "look_z",
    [7] = "yaw",
    [8] = "fovY",
    [9] = "aspect",
    [10] = "near",
    [11] = "far",
    [12] = "model_x",
    [13] = "model_y",
    [14] = "model_z",
}

-- ==========================================================================
-- 其他界面
-- ==========================================================================
local tbRangeList_Other =
{
    [1]  = {-500, 500},     -- x
    [2]  = {-300, 300},     -- y
    [3]  = {-1000, 1000},   -- z
    [4]  = {-300, 300},     -- look_x
    [5]  = {-300, 300},     -- look_y
    [6]  = {-300, 300},     -- look_z
    [7]  = {-15, 15},         -- yaw
    [8]  = {0, 3},          -- fovY
    [9]  = {0, 5},          -- aspect
    [10] = {0, 50},         -- near
    [11] = {0, 80000},      -- far
    [12] = {-500, 500},     -- model_x
    [13] = {-300, 300},     -- model_y
    [14] = {-1000, 1000},   -- model_z
}

local tbTitleList_Other =
{
    [1]  = "X",
    [2]  = "Y",
    [3]  = "Z",
    [4]  = "look_x",
    [5]  = "look_y",
    [6]  = "look_z",
    [7]  = "yaw",
    [8]  = "fovY",
    [9]  = "aspect",
    [10] = "near",
    [11] = "far",
    [12] = "model_x",
    [13] = "model_y",
    [14] = "model_z",
}


-- ==========================================================================
-- 捏脸相关界面
-- ==========================================================================
local tbRangeList_Face =
{
    [1] = {132500, 133500},  -- x
    [2] = {3900, 4700},     -- y
    [3] = {35400, 36100},   -- z
    [4] = {133000, 134000}, -- look_x
    [5] = {4000, 4500},     -- look_y
    [6] = {35600, 36200},   -- look_z
    [7] = {-8, 8},          -- yaw
    [8] = {0, 3},           -- fovY
    [9] = {0, 5},           -- aspect
    [10] = {0, 50},         -- near
    [11] = {0, 80000},      -- far
    [12] = {133320, 133520},        -- model_x
    [13] = {4000, 4300},            -- model_y
    [14] = {35822, 36200},          -- model_z
}

local tbTitleList_Face =
{
    [1] = "X",
    [2] = "Y",
    [3] = "Z",
    [4] = "look_x",
    [5] = "look_y",
    [6] = "look_z",
    [7] = "yaw",
    [8] = "fovY",
    [9] = "aspect",
    [10] = "near",
    [11] = "far",
    [12] = "model_x",
    [13] = "model_y",
    [14] = "model_z",
}








local UICameraEditorView = class("UICameraEditorView")

function UICameraEditorView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bIsOutfitPreview = UIMgr.GetView(VIEW_ID.PanelOutfitPreview) ~= nil
    self.bIsShop = UIMgr.GetView(VIEW_ID.PanelExteriorMain) ~= nil
    self.bIsStore = UIMgr.GetView(VIEW_ID.PanelActivityStoreNew) ~= nil
    self.bIsFace = UIMgr.GetView(VIEW_ID.PanelBuildFace_Step2) ~= nil or UIMgr.GetView(VIEW_ID.PanelBuildFace) ~= nil or UIMgr.GetView(VIEW_ID.PanelModelVideo) ~= nil
    self.bIsRoleChoices = UIMgr.GetView(VIEW_ID.PanelRoleChoices) ~= nil
    self.tbRangeList = tbRangeList_Other
    self.tbTitleList = tbTitleList_Other

    if self.bIsShop or self.bIsFace or self.bIsRoleChoices then
        self.tbRangeList = tbRangeList_Shop
        self.tbTitleList = tbTitleList_Shop
    elseif self.bIsOutfitPreview then
        self.tbRangeList = tbRangeList_Preview
        self.tbTitleList = tbTitleList_Preview
    end

    self:UpdateInfo()

    UITouchHelper.EnterEditMode()
end

function UICameraEditorView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    UITouchHelper.ExitEditMode()
end

function UICameraEditorView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick, function(btn)
        if self.bIsShop or self.bIsFace or self.bIsRoleChoices then
            self:CopyMiniSceneCameraData()
        else
		    self:CopyCameraData()
        end
    end)
end

function UICameraEditorView:RegEvent()
    KeyBoard.BindKeyDown({cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_C}, "复制数据", function()
        if self.bIsShop or self.bIsFace or self.bIsRoleChoices then
            self:CopyMiniSceneCameraData()
        else
		    self:CopyCameraData()
        end
	end)
end

function UICameraEditorView:UnRegEvent()
    KeyBoard.UnBindKeyDown({cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_C})
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UICameraEditorView:UpdateInfo()
    self.BtnTip:setButtonComponentEnabled(false)

    for k, cell in ipairs(self.tbCellList) do
        local szTitle = self.tbTitleList[k]
        UIHelper.SetVisible(cell, false)
        if not string.is_nil(szTitle) then
            UIHelper.SetVisible(cell, true)
            local LabelTitle = UIHelper.GetChildByName(cell, "LabelTitle")
            local EditBoxValue = UIHelper.GetChildByName(cell, "EditBox")
            local Slider = UIHelper.GetChildByName(cell, "Slider")

            UIHelper.SetString(LabelTitle, szTitle)
            self:InitPercentByVal(k, Slider, EditBoxValue)

            UIHelper.BindUIEvent(Slider, EventType.OnChangeSliderPercent, function(_slider, event)
                if event == ccui.SliderEventType.slideBallUp or event == ccui.SliderEventType.percentChanged then
                    local nPercent = UIHelper.GetProgressBarPercent(Slider) / 100
                    self:UpdateSliderString(k, nPercent, EditBoxValue)
                end
            end)

            if Platform.IsWindows() or Platform.IsMac() then
                UIHelper.RegisterEditBoxEnded(EditBoxValue, function()
                    local szValue = UIHelper.GetString(EditBoxValue)
                    local fValue = tonumber(szValue)
                    if not fValue then
                        local nPercent = UIHelper.GetProgressBarPercent(Slider) / 100
                        self:UpdateSliderString(k, nPercent, EditBoxValue)
                    else
                        local tbRange = self.tbRangeList[k]
                        local nPercent = (fValue - tbRange[1]) / (tbRange[2] - tbRange[1])
                        self:UpdateSliderString(k, nPercent, EditBoxValue)
                    end
                end)
            else
                UIHelper.RegisterEditBoxReturn(EditBoxValue, function()
                    local szValue = UIHelper.GetString(EditBoxValue)
                    local fValue = tonumber(szValue)
                    if not fValue then
                        local nPercent = UIHelper.GetProgressBarPercent(Slider) / 100
                        self:UpdateSliderString(k, nPercent, EditBoxValue)
                    else
                        local tbRange = self.tbRangeList[k]
                        local nPercent = (fValue - tbRange[1]) / (tbRange[2] - tbRange[1])
                        self:UpdateSliderString(k, nPercent, EditBoxValue)
                    end
                end)
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollView)
end

function UICameraEditorView:InitPercentByVal(nIndex, slider, editBox)
    local tbRange = self.tbRangeList[nIndex]
    local nVal = self:GetValueByIndex(nIndex) or 0
    local nPercent = (nVal - tbRange[1]) / (tbRange[2] - tbRange[1]) * 100
    UIHelper.SetProgressBarPercent(slider, nPercent)

    local bFloat = false
    if self.bIsShop or self.bIsFace or self.bIsRoleChoices then bFloat = (nIndex >= 1 or nIndex <= 6) else bFloat = (nIndex >= 1 or nIndex <= 6) end
    if bFloat then
        UIHelper.SetText(editBox, string.format("%.2f", nVal))
    else
        UIHelper.SetText(editBox, string.format("%d", nVal))
    end
end

function UICameraEditorView:UpdateSliderString(nIndex, nPercent, editBox)
    local tbRange = self.tbRangeList[nIndex]
    local nVal = (tbRange[2] - tbRange[1]) * nPercent + tbRange[1]

    local bFloat = false
    if self.bIsShop or self.bIsFace or self.bIsRoleChoices then bFloat = (nIndex >= 1 or nIndex <= 6) else bFloat = (nIndex >= 1 or nIndex <= 6) end
    if bFloat then
        UIHelper.SetText(editBox, string.format("%.2f", nVal))
    else
        UIHelper.SetText(editBox, string.format("%d", nVal))
    end

    self:SetValueByIndex(nIndex, nVal)
end

function UICameraEditorView:GetValueByIndex(nIndex)
    if self.bIsShop or self.bIsFace or self.bIsRoleChoices then
        return self:GetValueByIndex_Shop(nIndex)
    end

    return self:GetValueByIndex_Other(nIndex)
end

function UICameraEditorView:GetValueByIndex_Shop(nIndex)
    local camera = self:getCamera()
    local model = self:getModel()
    if not camera and not model then
        return nil
    end

    local tbBasePos = ExteriorCharacter.GetBasePos()

    if nIndex <= 3 then
        local x, y, z = nil, nil, nil
        if camera then x, y, z = camera:GetBasePosition() else  x, y, z = model:GetCameraPos() end
        if nIndex == 1 then return x - tbBasePos[1] end
        if nIndex == 2 then return y - tbBasePos[2] end
        if nIndex == 3 then return z - tbBasePos[3] end
    end

    if nIndex == 4 then
        local yaw = model:GetYaw()
        return yaw
    end

    if nIndex == 5 then
        local nOffsetX = camera and camera:GetOffsetAngle() or 0
        return nOffsetX
    end

    if nIndex == 6 then
        local nRotationX = camera and camera:GetRotation() or 0
        return nRotationX
    end

    if nIndex >= 7 and nIndex <= 9 then
        local x, y, z = model:GetTranslation()
        if nIndex == 7 then return x end
        if nIndex == 8 then return y end
        if nIndex == 9 then return z end
    end
end

function UICameraEditorView:GetValueByIndex_Other(nIndex)
    local camera = self:getCamera()
    local model = self:getModel()
    if not camera and not model then
        return nil
    end

    if nIndex <= 3 then
        local x, y, z = nil, nil, nil
        if camera then x, y, z = camera:getpos() else  x, y, z = model:GetCameraPos() end
        if nIndex == 1 then return x end
        if nIndex == 2 then return y end
        if nIndex == 3 then return z end
    end

    if nIndex >=4 and nIndex <= 6 then
        local x, y, z = nil, nil, nil
        if camera then x, y, z = camera:getlook() else  x, y, z = model:GetCameraLookPos() end
        if nIndex == 4 then return x end
        if nIndex == 5 then return y end
        if nIndex == 6 then return z end
    end

    if nIndex == 7 then
        local yaw = model:GetYaw()
        local nFactor = self.tbRangeList[nIndex][2]
        yaw = model.IsPendant and yaw / nFactor or yaw
        return yaw
    end

    if nIndex >= 8 and nIndex <= 11 then
        local fovY, aspect, near, far = (self.bIsFace or self.bIsRoleChoices) and camera:getperspective() or model:GetCameraPerspective()
        if nIndex == 8 then return fovY end
        if nIndex == 9 then return aspect end
        if nIndex == 10 then return near end
        if nIndex == 11 then return far end
    end

    if nIndex >= 12 and nIndex <= 14 then
        local x, y, z = model:GetTranslation()
        if nIndex == 12 then return x end
        if nIndex == 13 then return y end
        if nIndex == 14 then return z end
    end
end

function UICameraEditorView:SetValueByIndex(nIndex, nVal)
    if self.bIsShop or self.bIsFace or self.bIsRoleChoices then
        return self:SetValueByIndex_Shop(nIndex, nVal)
    end

    return self:SetValueByIndex_Other(nIndex, nVal)
end

function UICameraEditorView:SetValueByIndex_Shop(nIndex, nVal)
    local camera = self:getCamera()
    local model = self:getModel()
    if not camera and not model then
        return nil
    end

    local tbBasePos = ExteriorCharacter.GetBasePos()

    if nIndex <= 3 then
        local x, y, z = nil, nil, nil
        if camera then x, y, z = camera:GetBasePosition() else x, y, z = model:GetCameraPos() end
        if nIndex == 1 then x = nVal + tbBasePos[1] end
        if nIndex == 2 then y = nVal + tbBasePos[2] end
        if nIndex == 3 then z = nVal + tbBasePos[3] end
        if camera then camera:SetBasePosition(x, y, z) else model:SetCameraPos(x, y, z) end
    end

    if nIndex == 4 then
        model:SetYaw(nVal)
    end

    if nIndex == 5 then
        local x, y, z = model:GetTranslation()
        camera:SetOffsetAngle(nVal, 0, 0, x, y, z)
    end

    if nIndex == 6 then
        camera:SetRotation(nVal)
    end

    if nIndex >= 7 and nIndex <= 9 then
        local x, y, z = model:GetTranslation()
        if nIndex == 7 then x = nVal end
        if nIndex == 8 then y = nVal end
        if nIndex == 9 then z = nVal end
        model:SetTranslation(x, y, z)
        camera:SetOffsetAngle(nil, nil, nil, x, y, z)
    end
end

function UICameraEditorView:SetValueByIndex_Other(nIndex, nVal)
    local camera = self:getCamera()
    local model = self:getModel()
    if not camera and not model then
        return nil
    end

    if nIndex <= 3 then
        local x, y, z = nil, nil, nil
        if camera then x, y, z = camera:getpos() else  x, y, z = model:GetCameraPos() end
        if nIndex == 1 then x = nVal end
        if nIndex == 2 then y = nVal end
        if nIndex == 3 then z = nVal end
        if camera then camera:setpos(x, y, z) else model:SetCameraPos(x, y, z) end
    end

    if nIndex > 3 and nIndex <= 6 then
        local x, y, z = nil, nil, nil
        if camera then x, y, z = camera:getlook() else  x, y, z = model:GetCameraLookPos() end
        if nIndex == 4 then x = nVal end
        if nIndex == 5 then y = nVal end
        if nIndex == 6 then z = nVal end
        if camera then camera:setlook(x, y, z) else model:SetCameraLookPos(x, y, z) end
    end

    if nIndex == 7 then
        local nFactor = self.tbRangeList[nIndex][2]
        local _val = model.IsPendant and nFactor * nVal or nVal
        model:SetYaw(_val)
    end

    if nIndex >= 8 and nIndex <= 10 then
        local fovY, aspect, near, far = (self.bIsFace or self.bIsRoleChoices) and camera:getperspective() model:GetCameraPerspective()
        if nIndex == 8 then fovY = nVal end
        if nIndex == 9 then aspect = nVal end
        if nIndex == 10 then near = nVal end
        if nIndex == 11 then far = nVal end
        if self.bIsFace or self.bIsRoleChoices then camera:setperspective(fovY, aspect, near, far) else model:SetCameraPerspective(fovY, aspect, near, far) end
    end

    if nIndex >= 12 and nIndex <= 14 then
        local x, y, z = model:GetTranslation()
        if nIndex == 12 then x = nVal end
        if nIndex == 13 then y = nVal end
        if nIndex == 14 then z = nVal end
        model:SetTranslation(x, y, z)
    end
end

function UICameraEditorView:CopyMiniSceneCameraData()
    local camera = self:getCamera()
    if not camera then
        return
    end

    local model = self:getModel()
    if not model then
        return
    end

    local x, y, z = camera:GetBasePosition()
    local rx, ry, rz = camera:GetRotation()
    local yaw = model:GetYaw()
    local fovY, aspect, near, far = camera:getperspective()
    local mx, my, mz = model:GetTranslation()

    local szClipboard = string.format("[%.2f,%.2f,%.2f]\t[%.2f,%.2f,%.2f]\t%.2f\t%.2f\t[%d,%d,%d]",
                                    x, y, z, rx or 0, ry or 0, rz or 0, fovY, yaw, mx, my, mz)
    SetClipboard(szClipboard)

    TipsHelper.ShowNormalTip("镜头数据已成功拷贝到剪贴板。")
end

function UICameraEditorView:CopyCameraData()
    local model = self:getModel()
    if not model then
        return
    end

    local x, y, z = model:GetCameraPos()
    local lx, ly, lz = model:GetCameraLookPos()
    local yaw = model:GetYaw()
    local fovY, aspect, near, far = model:GetCameraPerspective()
    local mx, my, mz = model:GetTranslation()

    local scriptView = nil
    local nID = nil
    local szType = nil

    -- 红尘侠影
    scriptView = UIMgr.GetViewScript(VIEW_ID.PanelPartnerDetails)
    if scriptView then
        nID = scriptView.dwID
        szType = "PartnerNpc"
    end

    -- 宠物
    scriptView = UIMgr.GetViewScript(VIEW_ID.PanelPetMap)
    if scriptView then
        nID = scriptView.tPets[scriptView.nCurIndex].dwPetIndex
        szType = "Pet"
    end

    -- 坐骑
    scriptView = UIMgr.GetViewScript(VIEW_ID.PanelSaddleHorse)
    if scriptView then
        nID = scriptView.itemInfo.nUiId
        szType = "Ride"
    end

    -- 全屏商店
    scriptView = UIMgr.GetViewScript(VIEW_ID.PanelActivityStoreNew)
    if scriptView then
        local dwItemType, dwItemID = scriptView:GetCurItemInfo()
        nID = string.format("%s\t%s", tostring(dwItemType), tostring(dwItemID))
        szType = scriptView:GetCurItemType() or "Store"
    end

    if nID == nil or szType == nil then
        return
    end

    local szClipboard = string.format("%s\t%s\t[%d,%d,%d]\t[%d,%d,%d]\t[%.2f,%.2f,%.2f,%.2f]\t%.2f\t[%d,%d,%d]",
                                    szType, tostring(nID), x, y, z, lx, ly, lz, fovY, aspect, near, far, yaw, mx, my, mz)
    SetClipboard(szClipboard)

    TipsHelper.ShowNormalTip("镜头数据已成功拷贝到剪贴板。")
end

function UICameraEditorView:getCamera()
    local camera = UITouchHelper.GetCamera()
    if camera == nil then
        if self.bIsFace or self.bIsRoleChoices then
            local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
            camera = moduleCamera.GetCamera()
        end
    end

    return camera
end

function UICameraEditorView:getModel()
    local model = UITouchHelper.GetModel()
    if model == nil then
        if self.bIsFace or self.bIsRoleChoices then
            local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
            model = moduleScene.GetModel(self.bIsFace and LoginModel.FORCE_ROLE or LoginModel.ROLE)
        end
    end

    if model == nil then
        model = LastModelView
    end

    return model
end

return UICameraEditorView