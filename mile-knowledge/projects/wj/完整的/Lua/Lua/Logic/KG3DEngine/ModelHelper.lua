ModelHelper = ModelHelper or {}

ModelHelper.tSetCamera = {0, 0, -100, 0, 0, 0}
ModelHelper.tSetCameraSize = {
    [ROLE_TYPE.STANDARD_MALE] = { 530, 530 },
    [ROLE_TYPE.STANDARD_FEMALE] = { 500, 500 },
    [ROLE_TYPE.LITTLE_BOY] = { 350, 350 },
    [ROLE_TYPE.LITTLE_GIRL] = { 350, 350 },
}

function ModelHelper.SetViewer3DModel(Viewer3D, nRoleType)
    if not Viewer3D or not Viewer3D.SetScene then return end

    local nWidth, nHeight = table.unpack(ModelHelper.tSetCameraSize[nRoleType])
    local tCamera = ModelHelper.tSetCamera
    local hModelView = SceneHelper.GetModelsMiniScene(true)
    Viewer3D:SetScene(hModelView.m_scene)
    hModelView:SetCamera({tCamera[1], tCamera[2], tCamera[3], tCamera[4], tCamera[5], tCamera[6], nWidth, nHeight, 20, 40000, false })
end

function ModelHelper.UpdateModel(nViewer3DIndex, tRepresentID, nRoleType)
    if true then return end

    local hModelView = SceneHelper.GetModelsMiniScene(false)
    if tRepresentID then
        hModelView:UnloadModel(nViewer3DIndex)
        hModelView:UpdateRepresentID(nViewer3DIndex, tRepresentID, nRoleType)
        hModelView:PlayAnimation(nViewer3DIndex, "StandardNew", "loop")
    else
        hModelView:UnloadModel(nViewer3DIndex)
    end
end
