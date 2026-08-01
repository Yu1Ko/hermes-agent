print("Test.lua -------------------------------")

Test = {}

function Test.Case_1()
    cc.utils:sreenSaveToLocalFile(function(nCaptureRet, szScreenPath, pRetTexture)
        print("sreenSaveToLocalFile")
        print(nCaptureRet, szScreenPath, pRetTexture)
        end, "screen.png", 1)
end

function Test.Case_2()
    if not _G_B_Test_Case_2 then
        UIMgr.HideLayer(UILayer.Scene)
        UIMgr.HideLayer(UILayer.Battle)
        UIMgr.HideLayer(UILayer.Main)
        UIMgr.HideLayer(UILayer.Page)
        UIMgr.HideLayer(UILayer.Guide)
        UIMgr.HideLayer(UILayer.Debug)
        UIMgr.HideLayer(UILayer.MessageBox)
        UIMgr.HideLayer(UILayer.HoverTips)
        UIMgr.HideLayer(UILayer.Tips)

        local script = UIMgr.GetViewScript(VIEW_ID.PanelServerSelect)
        UIHelper.SetVisible(script._rootNode, false)
        _G_B_Test_Case_2 = true
    else
        UIMgr.ShowLayer(UILayer.Scene)
        UIMgr.ShowLayer(UILayer.Battle)
        UIMgr.ShowLayer(UILayer.Main)
        UIMgr.ShowLayer(UILayer.Page)
        UIMgr.ShowLayer(UILayer.Guide)
        UIMgr.ShowLayer(UILayer.Debug)
        UIMgr.ShowLayer(UILayer.MessageBox)
        UIMgr.ShowLayer(UILayer.HoverTips)
        UIMgr.ShowLayer(UILayer.Tips)

        local script = UIMgr.GetViewScript(VIEW_ID.PanelServerSelect)
        UIHelper.SetVisible(script._rootNode, true)
        _G_B_Test_Case_2 = false
    end
end


function Test.Case_3()
    if _G_B_Test_Case_3 then
        _G_B_Test_Case_3 = false
        UIMgr.Close(VIEW_ID.PanelServerSelect)
        return
    end

    _G_B_Test_Case_3 = true

    local viewScript = UIMgr.GetViewScript(VIEW_ID.PanelServerSelect)
    if not viewScript then
        viewScript = UIMgr.Open(VIEW_ID.PanelServerSelect)
    end

    local AniAll = viewScript._rootNode:getChildByName("AniAll")
    UIHelper.SetVisible(AniAll, false)
end

Test.Case_3()