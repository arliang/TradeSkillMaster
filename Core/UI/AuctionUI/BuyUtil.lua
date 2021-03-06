-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local _, TSM = ...
local BuyUtil = TSM.UI.AuctionUI:NewPackage("BuyUtil")
local L = TSM.Include("Locale").GetTable()
local Money = TSM.Include("Util.Money")
local ItemInfo = TSM.Include("Service.ItemInfo")
local CustomPrice = TSM.Include("Service.CustomPrice")
local private = {}



-- ============================================================================
-- Module Functions
-- ============================================================================

function BuyUtil.ShowConfirmation(baseFrame, record, isBuy, auctionNum, numFound, callback)
	local buyout = isBuy and record:GetField("buyout") or TSM.Auction.GetRequiredBidByScanResultRow(record)
	local stackSize = record:GetField("stackSize")
	local itemString = record:GetField("itemString")
	local shouldConfirm = false
	if ItemInfo.IsCommodity(itemString) then
		shouldConfirm = true
	elseif isBuy and record:GetField("isHighBidder") then
		shouldConfirm = true
	elseif TSM.db.global.shoppingOptions.buyoutConfirm then
		shouldConfirm = ceil(buyout / stackSize) >= (CustomPrice.GetValue(TSM.db.global.shoppingOptions.buyoutAlertSource, itemString) or 0)
	end
	if not shouldConfirm then
		return false
	end

	baseFrame = baseFrame:GetBaseElement()
	if baseFrame:IsDialogVisible() then
		return true
	end

	if ItemInfo.IsCommodity(itemString) then
		assert(isBuy)
		local numAvailable = stackSize - record:GetField("numOwnerItems")
		baseFrame:ShowDialogFrame(TSMAPI_FOUR.UI.NewElement("Frame", "frame")
			:SetLayout("VERTICAL")
			:SetStyle("width", 290)
			:SetStyle("height", 144)
			:SetStyle("anchors", { { "CENTER" } })
			:SetStyle("background", "#2e2e2e")
			:SetStyle("border", "#e2e2e2")
			:SetStyle("borderSize", 1)
			:SetStyle("padding", 8)
			:SetContext(callback)
			:SetMouseEnabled(true)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Frame", "item")
				:SetLayout("HORIZONTAL")
				:AddChild(TSMAPI_FOUR.UI.NewElement("Button", "icon")
					:SetStyle("width", 22)
					:SetStyle("height", 22)
					:SetStyle("margin", { right = 8, bottom = 2 })
					:SetStyle("backgroundTexture", ItemInfo.GetTexture(itemString))
					:SetTooltip(itemString)
				)
				:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "name")
					:SetStyle("height", 22)
					:SetStyle("margin", { bottom = 2, right = 16 })
					:SetStyle("font", TSM.UI.Fonts.FRIZQT)
					:SetStyle("fontHeight", 16)
					:SetStyle("justifyH", "LEFT")
					:SetText(TSM.UI.GetColoredItemName(itemString))
				)
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Frame", "price")
				:SetLayout("HORIZONTAL")
				:SetStyle("height", 20)
				:SetStyle("margin.top", 4)
				:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "text")
					:SetStyle("height", 20)
					:SetStyle("font", TSM.UI.Fonts.MontserratRegular)
					:SetStyle("fontHeight", 12)
					:SetStyle("justifyH", "LEFT")
					:SetStyle("textColor", "#e2e2e2")
					:SetText(L["Price Per Item"]..":")
				)
				:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "money")
					:SetStyle("height", 20)
					:SetStyle("font", TSM.UI.Fonts.RobotoMedium)
					:SetStyle("fontHeight", 12)
					:SetStyle("justifyH", "RIGHT")
					:SetStyle("textColor", "#e2e2e2")
					:SetText(Money.ToString(record:GetField("itemBuyout"), nil, "OPT_83_NO_COPPER"))
				)
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Frame", "total")
				:SetLayout("HORIZONTAL")
				:SetStyle("height", 20)
				:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "text")
					:SetStyle("height", 20)
					:SetStyle("font", TSM.UI.Fonts.MontserratRegular)
					:SetStyle("fontHeight", 12)
					:SetStyle("justifyH", "LEFT")
					:SetStyle("textColor", "#e2e2e2")
					:SetText(L["Total price"]..":")
				)
				:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "money")
					:SetStyle("height", 20)
					:SetStyle("font", TSM.UI.Fonts.RobotoMedium)
					:SetStyle("fontHeight", 12)
					:SetStyle("justifyH", "RIGHT")
					:SetStyle("textColor", "#e2e2e2")
					:SetText(Money.ToString(record:GetField("itemBuyout") * stackSize, nil, "OPT_83_NO_COPPER"))
				)
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Frame", "quantity")
				:SetLayout("HORIZONTAL")
				:SetStyle("height", 20)
				:SetStyle("margin.top", 8)
				:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "label")
					:SetStyle("height", 20)
					:SetStyle("fontHeight", 12)
					:SetStyle("justifyH", "LEFT")
					:SetStyle("textColor", "#e2e2e2")
					:SetText(format(L["Qty (%d available)"], numAvailable)..":")
				)
				:AddChild(TSMAPI_FOUR.UI.NewElement("InputNumeric", "input")
					:SetStyle("backgroundTexturePacks", "uiFrames.ActiveInputField")
					:SetStyle("width", 64)
					:SetStyle("height", 20)
					:SetText("1")
					:SetMinNumber(1)
					:SetMaxNumber(numAvailable)
					:SetStyle("justifyH", "CENTER")
					:SetScript("OnTextChanged", private.InputQtyOnTextChanged)
				)
				:AddChild(TSMAPI_FOUR.UI.NewElement("ActionButton", "maxBtn")
					:SetStyle("width", 50)
					:SetStyle("height", 15)
					:SetStyle("margin.left", 4)
					:SetStyle("font", TSM.UI.Fonts.MontserratMedium)
					:SetStyle("fontHeight", 12)
					:SetContext(numAvailable)
					:SetText(L["MAX"])
					:SetScript("OnClick", private.MaxQtyBtnOnClick)
				)
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("ActionButton", "confirmBtn")
				:SetStyle("margin.top", 6)
				:SetStyle("width", 276)
				:SetStyle("height", 26)
				:SetText(L["BUYOUT"])
				:SetScript("OnClick", private.ConfirmBtnOnClick)
			)
			:AddChildNoLayout(TSMAPI_FOUR.UI.NewElement("Button", "closeBtn")
				:SetStyle("width", 18)
				:SetStyle("height", 18)
				:SetStyle("anchors", { { "TOPRIGHT", -4, -4 } })
				:SetStyle("backgroundTexturePack", "iconPack.18x18/Close/Default")
				:SetScript("OnClick", private.BuyoutConfirmCloseBtnOnClick)
			)
		)
	else
		baseFrame:ShowDialogFrame(TSMAPI_FOUR.UI.NewElement("Frame", "frame")
			:SetLayout("VERTICAL")
			:SetStyle("width", 290)
			:SetStyle("height", 156)
			:SetStyle("anchors", { { "CENTER" } })
			:SetStyle("background", "#2e2e2e")
			:SetStyle("border", "#e2e2e2")
			:SetStyle("borderSize", 1)
			:SetStyle("padding", 8)
			:SetContext(callback)
			:SetMouseEnabled(true)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Frame", "item")
				:SetLayout("HORIZONTAL")
				:AddChild(TSMAPI_FOUR.UI.NewElement("Button", "icon")
					:SetStyle("width", 22)
					:SetStyle("height", 22)
					:SetStyle("margin", { right = 8, bottom = 2 })
					:SetStyle("backgroundTexture", ItemInfo.GetTexture(itemString))
					:SetTooltip(itemString)
				)
				:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "name")
					:SetStyle("height", 22)
					:SetStyle("margin", { bottom = 2, right = 16 })
					:SetStyle("font", TSM.UI.Fonts.FRIZQT)
					:SetStyle("fontHeight", 16)
					:SetStyle("justifyH", "LEFT")
					:SetText(TSM.UI.GetColoredItemName(itemString))
				)
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "stack")
				:SetStyle("height", 20)
				:SetStyle("margin.bottom", 4)
				:SetStyle("font", TSM.UI.Fonts.MontserratMedium)
				:SetStyle("fontHeight", 12)
				:SetStyle("justifyH", "LEFT")
				:SetText(L["Qty"]..": "..stackSize)
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Frame", "price")
				:SetLayout("HORIZONTAL")
				:SetStyle("height", 20)
				:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "text")
					:SetStyle("height", 20)
					:SetStyle("font", TSM.UI.Fonts.MontserratRegular)
					:SetStyle("fontHeight", 12)
					:SetStyle("justifyH", "LEFT")
					:SetStyle("textColor", "#e2e2e2")
					:SetText(L["Price Per Item"]..":")
				)
				:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "money")
					:SetStyle("height", 20)
					:SetStyle("font", TSM.UI.Fonts.MontserratRegular)
					:SetStyle("fontHeight", 12)
					:SetStyle("justifyH", "RIGHT")
					:SetStyle("textColor", "#e2e2e2")
					:SetText(Money.ToString(ceil(buyout / stackSize), nil, "OPT_83_NO_COPPER"))
				)
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Frame", "buyout")
				:SetLayout("HORIZONTAL")
				:SetStyle("height", 20)
				:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "text")
					:SetStyle("height", 20)
					:SetStyle("font", TSM.UI.Fonts.MontserratRegular)
					:SetStyle("fontHeight", 12)
					:SetStyle("justifyH", "LEFT")
					:SetStyle("textColor", "#e2e2e2")
					:SetText(isBuy and L["Auction Buyout"]..":" or L["Auction Bid"]..":")
				)
				:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "money")
					:SetStyle("height", 20)
					:SetStyle("font", TSM.UI.Fonts.MontserratRegular)
					:SetStyle("fontHeight", 12)
					:SetStyle("justifyH", "RIGHT")
					:SetStyle("textColor", "#e2e2e2")
					:SetText(Money.ToString(TSM.IsWowClassic() and buyout or ceil(buyout / stackSize), nil, "OPT_83_NO_COPPER"))
				)
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Frame", "stacks")
				:SetLayout("HORIZONTAL")
				:SetStyle("height", 20)
				:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "text")
					:SetStyle("height", 20)
					:SetStyle("font", TSM.UI.Fonts.MontserratRegular)
					:SetStyle("fontHeight", 12)
					:SetStyle("justifyH", "LEFT")
					:SetStyle("textColor", "#e2e2e2")
					:SetText(isBuy and L["Purchasing Auction"]..":" or L["Bidding Auction"]..":")
				)
				:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "number")
					:SetStyle("height", 20)
					:SetStyle("font", TSM.UI.Fonts.MontserratRegular)
					:SetStyle("fontHeight", 12)
					:SetStyle("justifyH", "RIGHT")
					:SetStyle("textColor", "#e2e2e2")
					:SetText(auctionNum.."/"..numFound)
				)
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("ActionButton", "confirmBtn")
				:SetStyle("margin.top", 6)
				:SetStyle("width", 276)
				:SetStyle("height", 26)
				:SetContext(isBuy and stackSize or -stackSize)
				:SetText(isBuy and L["BUYOUT"] or L["BID"])
				:SetScript("OnClick", private.ConfirmBtnOnClick)
			)
			:AddChildNoLayout(TSMAPI_FOUR.UI.NewElement("Button", "closeBtn")
				:SetStyle("width", 18)
				:SetStyle("height", 18)
				:SetStyle("anchors", { { "TOPRIGHT", -4, -4 } })
				:SetStyle("backgroundTexturePack", "iconPack.18x18/Close/Default")
				:SetScript("OnClick", private.BuyoutConfirmCloseBtnOnClick)
			)
		)
	end
	return true
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.BuyoutConfirmCloseBtnOnClick(button)
	button:GetBaseElement():HideDialog()
end

function private.InputQtyOnTextChanged(input)
	local minQuantity, maxQuantity = input:GetMinMaxNumber()
	local quantity = input:GetNumber()
	input:SetText(input:GetText())
	local total = Money.FromString(input:GetElement("__parent.__parent.price.money"):GetText()) * quantity
	input:GetElement("__parent.__parent.total.money"):SetText(Money.ToString(total, nil, "OPT_83_NO_COPPER"))
		:Draw()

	local confirmBtn = input:GetElement("__parent.__parent.confirmBtn")
	if total > 0 and GetMoney() > total and quantity >= minQuantity and quantity <= maxQuantity then
		confirmBtn:SetDisabled(false)
	else
		confirmBtn:SetDisabled(true)
	end
	confirmBtn:Draw()
end

function private.MaxQtyBtnOnClick(button)
	button:GetElement("__parent.input")
		:SetText(button:GetContext())
		:Draw()
end

function private.ConfirmBtnOnClick(button)
	local quantity = button:GetContext()
	if quantity == nil then
		quantity = button:GetElement("__parent.quantity.input"):GetNumber()
	end
	local callback = button:GetParentElement():GetContext()
	button:GetBaseElement():HideDialog()
	if quantity > 0 then
		callback(true, quantity)
	else
		callback(false, -quantity)
	end
end
