-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: DCAssetFreezeData
-- Date: 2025-05-07 15:44:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

DCAssetFreezeData = DCAssetFreezeData or {className = "DCAssetFreezeData"}
local self = DCAssetFreezeData
-------------------------------- 消息定义 --------------------------------
DCAssetFreezeData.Event = {}
DCAssetFreezeData.Event.XXX = "DCAssetFreezeData.Msg.XXX"

function DCAssetFreezeData.Init()

end

function DCAssetFreezeData.UnInit()

end

function DCAssetFreezeData.OnLogin()

end

function DCAssetFreezeData.OnFirstLoadEnd()

end

function DCAssetFreezeData.UpdateDCAssetFreeze(bFreeze)
    self.bFreeze = bFreeze
    if bFreeze then
        BubbleMsgData.PushMsgWithType("LockTransactionTips", {
            szAction = function ()
                WebUrl.OpenByID(66)
            end,
        })
    else
        BubbleMsgData.RemoveMsg("LockTransactionTips")
        UIMgr.Close(VIEW_ID.PanelEmbeddedWebPages)
        UIMgr.Close(VIEW_ID.PanelH5GameView)
    end
end