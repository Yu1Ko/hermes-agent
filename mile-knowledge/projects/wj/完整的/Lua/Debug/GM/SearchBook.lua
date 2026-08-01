if not SearchBook then
    SearchBook = {
        text = "【书籍】",
        szPlaceHolder = "输入书名或套书ID",
        nViewID = VIEW_ID.PanelGMRightView,
        lastStartSearchTime = 0,
        lastResultsInfo = '',
        bLastPartMode = false,
        tbLastGMView = {},
        isCallBack = 1,
        tBook = {},
        tPartFile = {}, --用于存储已加载的部件表现表；
    }
end

function SearchBook:FillAll()
    -- local dwBookID, dwSegmentID = GlobelRecipeID2BookID(dwRecipeID)
    -- szName = Table_GetBookName(dwBookID, dwSegmentID)
    local tbBookSegment = g_tTable.BookSegment
    local nRow = tbBookSegment:GetRowCount()
    for i = 2, nRow do
        local tBookStringInfo = tbBookSegment:GetRow(i)
        if tBookStringInfo then
            local szSegmentName = '['..tBookStringInfo.dwBookID..'] '..'['..tBookStringInfo.dwSegmentID..'] '..tBookStringInfo.szSegmentName
            local tTemp = { ID = tBookStringInfo.dwBookID, SegmentID = tBookStringInfo.dwSegmentID, BookItemIndex = tBookStringInfo.dwBookItemIndex,
                            BookName = tBookStringInfo.szBookName, Name = szSegmentName, ButtonLabel = '获取',
                            tBtnStatus = {
                                    BtnOperate = true, BtnOperate1 = false, BtnOperate2 = false,
                                    BtnOperate3 = false, BtnOperate4 = false
                                        }
                            }
            table.insert(SearchBook.tBook, tTemp)
        end
    end
end

function SearchBook:ShowSubWindow(tbGMView)
    tbGMView.PanelRightView:setVisible(true)
    tbGMView.WidgetExterior:setVisible(true)
    tbGMView.TogPartMode:setVisible(true)
    tbGMView.TogFileMode:setVisible(false)
    tbGMView.WidgetSwitch:setVisible(false)
    tbGMView.EditSearchRight:setPlaceHolder(SearchBook.szPlaceHolder)
    if tbGMView.tbLastData~=nil and next(tbGMView.tbLastData) then
        UIHelper.SetString(tbGMView.EditSearchRight, tbGMView.tbLastData.EditLabelRight)
    else
        UIHelper.SetString(tbGMView.EditSearchRight, "")
    end
    -- 设置勾选状态
    UIHelper.SetSelected(tbGMView.TogPartMode, SearchBook.bLastPartMode)
    UIHelper.SetString(tbGMView.LabelPartMode, '获取套书')
    SearchBook.tbLastGMView = tbGMView
end

function SearchBook:OnClick(tbGMView)
    if not next(SearchBook.tBook) then
        SearchBook:FillAll()
    end
    SearchBook:ShowSubWindow(tbGMView)
    UIHelper.SetString(tbGMView.EditSearchRight, "")
    tbGMView.tbGMPanelRight = SearchBook
    tbGMView.tbRawDataRight = SearchBook.tBook
    tbGMView.tbSearchResultRight = SearchBook.tBook
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end


function SearchBook:BtnOperate(tbData)
    SearchBook.bLastPartMode =  UIHelper.GetSelected(SearchBook.tbLastGMView.TogPartMode)

    if not SearchBook.bLastPartMode then
        local tItemID = tbData.BookItemIndex
        local  tBookIndex = (tbData.ID - 1) * 8 + tbData.SegmentID - 1
        SendGMCommand("player.AddItem(5 ,".. tItemID ..", " ..tBookIndex ..")")
        OutputMessage("MSG_ANNOUNCE_NORMAL", "获得物品【" .. UIHelper.GBKToUTF8(tbData.Name) .. "】\n")
    else
        local tbAllBook = GMMgr.GetRightData(tbData.ID, SearchBook.tBook)
        for index, book in pairs(tbAllBook) do
            local tItemID = book.BookItemIndex
            local  tBookIndex = (book.ID - 1) * 8 + book.SegmentID - 1
            SendGMCommand("player.AddItem(5 ,".. tItemID ..", " ..tBookIndex ..")")
            OutputMessage("MSG_ANNOUNCE_NORMAL", "获得物品【" .. UIHelper.GBKToUTF8(book.Name) .. "】\n")
        end
    end
end

function SearchBook:GetAllData(tbGMView)
    tbGMView.tbSearchResultRight = SearchBook.tBook
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbSearchResultRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end