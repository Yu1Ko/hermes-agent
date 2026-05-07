-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: MonopolyRightEvent
-- Date: 2026-04-24 17:13:07
-- Desc: 大富翁 右侧通用面板DX DataModel整合
-- ---------------------------------------------------------------------------------

MonopolyRightEvent = MonopolyRightEvent or {className = "MonopolyRightEvent"}
local self = MonopolyRightEvent

local m_tDataModelMap = {}
function MonopolyRightEvent.GetDataModel(szRightEvent)
    return m_tDataModelMap[szRightEvent]
end

do
    -- copy from DX Revision: 1832497
    -----------------------------MonopolySelectDirection------------------------------
    local DataModel = {}

    function DataModel.Init()
        DataModel.bSubmitted = false
        DataModel.nLastLeftTime = nil
        local tCountDown = DFW_GetCountDownTime()
        if tCountDown then
            DataModel.nEndTime = tCountDown[1] or 0
        else
            DataModel.nEndTime = 0
        end
    end

    function DataModel.UnInit()
        DataModel.bSubmitted = nil
        DataModel.nLastLeftTime = nil
        DataModel.nEndTime = nil
    end

    function DataModel.SetSubmitted(bSubmitted)
        DataModel.bSubmitted = bSubmitted and true or false
    end

    function DataModel.GetLeftTime()
        if not DataModel.nEndTime or DataModel.nEndTime <= 0 then
            return 0
        end

        return math.max(0, DataModel.nEndTime - GetCurrentTime())
    end

    m_tDataModelMap[MonopolyRightEventType.SelectDirection] = DataModel
end

do
    -- copy from DX Revision: 1823544
    -----------------------------MonopolyCardCast------------------------------
    local DataModel = {}

    function DataModel.Init(nCardID)
        DataModel.nCardID   = nCardID
        DataModel.tCardInfo = Table_GetMonopolyCardInfoByID(nCardID)
    end

    function DataModel.UnInit()
        for i, v in pairs(DataModel) do
            if type(v) ~= "function" then
                DataModel[i] = nil
            end
        end
    end

    m_tDataModelMap[MonopolyRightEventType.CardCast] = DataModel
end

do
    -- copy from DX Revision: 1836527
    -----------------------------MonopolyLandPurchaseDlg------------------------------
    local DataModel = {}
    local m_tData = {}

    function DataModel.Init()
        m_tData = {
            nGridIndex = 0,
            nType      = 0,      -- 0/1: 购买, 2: 升级
            nPrice     = 0,
            nCash      = 0,
            bReplied   = false,
        }
    end

    function DataModel.UnInit()
        m_tData = {}
    end

    function DataModel.SetData(tData)
        for k, v in pairs(tData) do
            m_tData[k] = v
        end
    end

    function DataModel.GetData()
        return m_tData
    end

    function DataModel.SetReplied(bReplied)
        m_tData.bReplied = bReplied
    end

    m_tDataModelMap[MonopolyRightEventType.LandPurchase] = DataModel
end

do
    -- copy from DX Revision: 1825481
    -----------------------------MonopolyTargetSelectPanel------------------------------
    local DataModel = {}

    local m_tData = {
        nCardID = 0,
        nSelectedIndex = 0,
    }

    function DataModel.Init(nCardID)
        m_tData.nCardID = nCardID or 0
        m_tData.nSelectedIndex = 0
    end

    function DataModel.UnInit()
        m_tData.nCardID = 0
        m_tData.nSelectedIndex = 0
    end

    function DataModel.SetSelected(nDfwIndex)
        m_tData.nSelectedIndex = nDfwIndex or 0
    end

    function DataModel.GetData()
        return m_tData
    end

    m_tDataModelMap[MonopolyRightEventType.TargetSelect] = DataModel
end

do
    -- copy from DX Revision: 
    -----------------------------MonopolyAuctionInfoPanel------------------------------
    local DataModel = {
        nState = MONOPOLY_AUCTION_STATE.MY_BID,
        nGridID = 0,
        nInitPrice = 0,
        nFinalBid = 0,
        nWinnerIndex = 0,
    }
    
    function DataModel.Init()
        DataModel.nState = MONOPOLY_AUCTION_STATE.MY_BID
        local nGridID = DFW_GetTableAuctionGrid() or 0
        DataModel.nGridID = nGridID or 0
        DataModel.nInitPrice = 0
        DataModel.nFinalBid = 0
        DataModel.nWinnerIndex = 0
    end
    
    function DataModel.UnInit()
        for k, v in pairs(DataModel) do
            if type(v) ~= "function" then
                DataModel[k] = nil
            end
        end
    end
    
    function DataModel.GetGridData()
        if not DataModel.nGridID or DataModel.nGridID <= 0 then
            return nil
        end
        return DFW_GetGridData(DataModel.nGridID)
    end
    
    function DataModel.GetGridLevel()
        local tGridData = DataModel.GetGridData() or {}
        return tGridData.level or tGridData.nLevel or tGridData[2] or 0
    end
    
    function DataModel.GetGridRent()
        local tGridData = DataModel.GetGridData() or {}
        return tGridData.nRent or tGridData.rent or tGridData[5] or 0
    end
    
    function DataModel.GetPriceIndexMuli()
        return DFW_GetTablePriceMuli() or 1
    end
    
    function DataModel.CalcInitPrice()
        local nLevel = DataModel.GetGridLevel()
        local nRent = DataModel.GetGridRent()
        local nMuli = DataModel.GetPriceIndexMuli()
        -- 起拍价由当前地块等级、租金和桌面倍率共同计算。
        local nPrice = math.floor((nLevel or 0) * (nRent or 0) * (nMuli or 1))
        if nPrice < 0 then
            nPrice = 0
        end
        DataModel.nInitPrice = nPrice
        return nPrice
    end
    
    function DataModel.SetState(nState)
        DataModel.nState = nState or MONOPOLY_AUCTION_STATE.MY_BID
    end
    
    function DataModel.SetGridID(nGridID)
        if nGridID and nGridID > 0 then
            DataModel.nGridID = nGridID
        end
    end
    
    function DataModel.PullAuctionResult()
        local nFinalBid, nPlayerIndex = DFW_GetAuctionLastResult()
        DataModel.nWinnerIndex = nPlayerIndex or 0
        DataModel.nFinalBid = nFinalBid or 0
    end

    m_tDataModelMap[MonopolyRightEventType.AuctionInfo] = DataModel
end

do
    -- copy from DX Revision: 
    -----------------------------MonopolyLandExchangeRequest------------------------------
    local DataModel = {}

    m_tDataModelMap[MonopolyRightEventType.LandExchange] = DataModel
end