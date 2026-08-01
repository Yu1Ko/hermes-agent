if not GetPoints then 
    GetPoints = {
        text = '坐标记录',
        IsNeedFace = false,
        IsNeedMAP = false,
        szLabelEditorUp = '',
        szLabelEditorDown = '',
        nPointNpcCount = 0,
        newX_3D = 0,
        newY_3D = 0,
        newZ_3D = 0,
    } 
end

function GetPoints:ShowSubWindow(tbGMView)
    tbGMView.PanelRightView:setVisible(false)
    if not UIMgr.GetView(VIEW_ID.PanelGMRightExpansion) then
        UIMgr.Open(VIEW_ID.PanelGMRightExpansion, GetPoints)
    end
end

function GetPoints:OnClick(tbGMView)
    GetPoints:ShowSubWindow(tbGMView)
    tbGMView.tbGMPanelRight = GetPoints
end

function GetPoints:BtnGetPosition(ExpansionView)
    -- 原来的内容
    local szEditSearchUp = UIHelper.GetString(ExpansionView.LabelEditBoxUp)
    local szEditSearchDown = UIHelper.GetString(ExpansionView.LabelEditBoxDown)
    
    -- 新的内容
    local szNewEditSearchUp = ''
    local szNewEditSearchDown = ''
    local player = GetClientPlayer()
    local dwMapID = player.GetMapID() or 0
    GetPoints.IsNeedMAP = UIHelper.GetSelected(ExpansionView.TogMap)
    GetPoints.IsNeedFace = UIHelper.GetSelected(ExpansionView.TogFace)
    if GetPoints.IsNeedMAP then
        szNewEditSearchUp = szEditSearchUp .. "{" .. dwMapID .. ", ".. player.nX .. ", " .. player.nY .. ", " .. player.nZ
        szNewEditSearchDown = szEditSearchDown .. "{" .. dwMapID .. ", ".. player.nX .. ", " .. player.nY .. ", " .. player.nZ
    else
        szNewEditSearchUp = szEditSearchUp .. "{".. player.nX .. ", " .. player.nY .. ", " .. player.nZ
        szNewEditSearchDown = szEditSearchDown .. "{".. player.nX .. ", " .. player.nY .. ", " .. player.nZ
    end

    if GetPoints.IsNeedFace then
        szNewEditSearchUp = szNewEditSearchUp .. ", " .. player.nFaceDirection
        szNewEditSearchDown = szNewEditSearchDown .. ", " .. player.nFaceDirection
    end
    szNewEditSearchUp = szNewEditSearchUp .. "},\n"
    Update3DPoints(player)
    szNewEditSearchDown = szNewEditSearchDown .. "), ==>3d: " .. "(" .. GetPoints.newX_3D .. ", " .. GetPoints.newY_3D .. ", " .. GetPoints.newZ_3D
    local dwMapIndex =  player.GetScene().nCopyIndex or 1
    local szMapName = Table_GetMapName(dwMapID) or ""
    szNewEditSearchDown = szNewEditSearchDown .. "), (" .. dwMapID .. ", " .. dwMapIndex .. "): " .. UIHelper.GBKToUTF8(szMapName) .. ",\n"
            
    -- local szEditSearchUp = UIHelper.GetString(ExpansionView.LabelEditBoxUp)
    -- local szEditSearchDown = UIHelper.GetString(ExpansionView.LabelEditBoxDown)
    -- szEditSearchUp = szEditSearchUp .. '{10181, 37346, 1076864}\n'
    -- szEditSearchDown = szEditSearchDown .. '(10181, 37346, 1076864), ==>3d: (15907.8125, 5525, 58353.125), (1, 1): 稻香村\n'
    UIHelper.SetString(ExpansionView.LabelEditBoxUp, szNewEditSearchUp)
    UIHelper.SetString(ExpansionView.LabelEditBoxDown, szNewEditSearchDown)
    GetPoints.szLabelEditorUp = szNewEditSearchUp
    GetPoints.szLabelEditorDown = szNewEditSearchDown
    UIHelper.SetString(ExpansionView.EditSearchUp, '')
    UIHelper.SetString(ExpansionView.EditSearchDown, '')
end

function GetPoints:BtnSettPosition()
    local szTime = ""
    local tTime = TimeToDate(GetCurrentTime())
    szTime = tTime["year"] .. "-" .. tTime["month"] .. "-" .. tTime["day"] .. " " .. tTime["hour"] .. ":" .. tTime["minute"] .. ":" .. tTime["second"]
    OutputMessage("MSG_ANNOUNCE_NORMAL", "已放置标记到你现在的位置，不要重复放置。" .. szTime .. "\n")
    OutputMessage("MSG_SYS", "已放置标记到你现在的位置，不要重复放置。" .. szTime .. "\n")
    GetPoints.nPointNpcCount = GetPoints.nPointNpcCount + 1
    SendGMCommand("player.GetScene().CreateNpc(15949, player.nX,  player.nY, player.nZ, player.nFaceDirection,-1,'PointNpc_"..GetPoints.nPointNpcCount.."').SetDialogFlag(0);")
end

function GetPoints:BtnClear(ExpansionView)
    UIHelper.SetString(ExpansionView.LabelEditBoxUp, szNewEditSearchUp)
    UIHelper.SetString(ExpansionView.LabelEditBoxDown, szNewEditSearchDown)
    GetPoints.szLabelEditorUp = szNewEditSearchUp
    GetPoints.szLabelEditorDown = szNewEditSearchDown
end

function GetCallBackFun3DPoints()
    return function(...)
    local tArg = {...}
    GetPoints.newX_3D,	GetPoints.newY_3D,	GetPoints.newZ_3D = tArg[1], tArg[2], tArg[3]
    end	
end

function Update3DPoints(p)
    if not _G.bClassic then	
        PostThreadCall(GetCallBackFun3DPoints(), nil, 'Scene_GameWorldPositionToScenePosition',p.nX,p.nY,p.nZ);
    else	
        --不需要多线程回调实现
        GetPoints.newX_3D,	GetPoints.newY_3D,	GetPoints.newZ_3D = Scene_GameWorldPositionToScenePosition(p.nX,p.nY,p.nZ, true)
    end
end
    
