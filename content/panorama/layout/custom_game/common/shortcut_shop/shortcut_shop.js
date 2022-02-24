"use strict";

// item_name: item_id
const items = { 
	"item_ward_sentry": 43, 
	"item_dust": 40
}

let item_costs

const SHOP = FindDotaHudElement("shop")
const QUICK_BUY = FindDotaHudElement("lower_hud").FindChildTraverse("quickbuy")
const QUICK_BUY_ROW = QUICK_BUY.FindChildTraverse("Row1")
const CONTEXT = $.GetContextPanel()

function CreateItemButton(name, id) {
	const panel = $.CreatePanelWithProperties("DOTAShopItem", CONTEXT, id, { itemname: name })
	
	panel.style.width = "38px"
	panel.style.height = "28px"
	panel.style.margin = "1px"

	// I cant find way to trigger DOTAShopPanel update, so for now this disabled
	panel.FindChild("OutOfStockOverlay").ClearPropertyFromCode("clip")

	panel.SetPanelEvent("oncontextmenu", () => {

		if (!panel.BHasClass("CanPurchase") || panel.BHasClass("OutOfStock") || Game.IsGamePaused()) return;

		Game.EmitSound("General.Buy")
		Game.PrepareUnitOrders({
			OrderType: dotaunitorder_t.DOTA_UNIT_ORDER_PURCHASE_ITEM,
			UnitIndex: Players.GetLocalPlayerPortraitUnit(),
			AbilityIndex: id,
			Queue: false,
			ShowEffects: true
		})
	})

	const update = function() {
		if (!panel.IsValid()) return
		$.Schedule(0., update)
			
		const gold = Players.GetGold(Game.GetLocalPlayerID())
		panel.SetHasClass("CanPurchase", gold >= item_costs[name])

		CONTEXT.style.marginBottom = QUICK_BUY.actuallayoutheight / ( Game.GetScreenHeight() / 1080 ) + "px"
	}

	const updateSlow = function() {
		if (!panel.IsValid()) return
		$.Schedule(0.33, updateSlow)

		// Ultimative hack to check stock amount
		const dummy = $.CreatePanelWithProperties("DOTAShopItem", CONTEXT, "", { itemname: name })
		dummy.visible = false
		panel.SetHasClass("OutOfStock", dummy.BHasClass("OutOfStock"))
		panel.SetHasClass("ShowStockAmount", dummy.BHasClass("ShowStockAmount"))
		panel.FindChild("StockAmount").text = dummy.FindChild("StockAmount").text
		dummy.DeleteAsync(0)
	}

	update()
	updateSlow()
}

GameEvents.SendCustomGameEventToServer("shortcut_shop_request_item_costs", items)
GameEvents.SubscribeProtected("shortcut_shop_item_costs", function(data) {
	item_costs = data

	CONTEXT.RemoveAndDeleteChildren()
	Object.entries(items).forEach( entry => {
		const [name, id] = entry;
		CreateItemButton(name, id) 
	})
}) 

$.RegisterEventHandler("PanelStyleChanged", QUICK_BUY_ROW, function() {
	CONTEXT.SetHasClass("QuickBuyTwoRows", !QUICK_BUY_ROW.BHasClass("Empty"))
})

$.RegisterEventHandler("PanelStyleChanged", SHOP, function() {
	CONTEXT.SetHasClass("Hidden", SHOP.BHasClass("ShopOpen"))
})
