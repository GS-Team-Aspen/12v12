itemPanels = []
droppedItems = []

$( "#ItemsContainer" ).RemoveAndDeleteChildren()

function NeutralItemPickedUp( data ) {
	Game.EmitSound( "DOTA_Item.IronTalon.Activate" )
	if ( itemPanels[data.item] ) {
		return
	}

	var choiceWasMade = false
	let item = $.CreatePanel( "Panel", $( "#ItemsContainer" ), "" )
	item.BLoadLayoutSnippet( "NewItem" )
	item.AddClass( "Slide" )
	item.FindChildTraverse( "ItemImage" ).itemname = Abilities.GetAbilityName( data.item )
	item.FindChildTraverse( "ButtonKeep" ).SetPanelEvent( "onactivate", function() {
		GameEvents.SendCustomGameEventToServer( "neutral_item_keep", {
			item: data.item,
			secret: data.secret
		} )
		item.visible = false
		choiceWasMade = true
	} )
	item.FindChildTraverse( "ButtonDrop" ).SetPanelEvent( "onactivate", function() {
		GameEvents.SendCustomGameEventToServer( "neutral_item_drop", {
			item: data.item,
			secret: data.secret
		} )
		item.visible = false
		choiceWasMade = true
	} )

	item.FindChildTraverse( "Countdown" ).AddClass( "Active" )

	itemPanels[data.item] = true

	$.Schedule( 15, function() {
		if (!choiceWasMade){
			GameEvents.SendCustomGameEventToServer( "neutral_item_drop", {
            	item: data.item,
            	secret: data.secret
			} )
		}
		item.RemoveClass( "Slide" )
		item.DeleteAsync( 0.3 )
		itemPanels[data.item] = false
	} )
}

function NeutralItemDropped( data ) {
	Game.EmitSound( "Loot_Drop_Stinger_Short" )
	let item = $.CreatePanel( "Panel", $( "#ItemsContainer" ), "" )
	item.BLoadLayoutSnippet( "TakeItem" )
	item.AddClass( "Slide" )
	item.FindChildTraverse( "ItemImage" ).itemname = Abilities.GetAbilityName( data.item )
	item.FindChildTraverse( "ButtonTake" ).SetPanelEvent( "onactivate", function() {
		GameEvents.SendCustomGameEventToServer( "neutral_item_take", {
			item: data.item,
			secret: data.secret
		} )
	} )
	item.FindChildTraverse( "CloseButton" ).SetPanelEvent( "onactivate", function() {
		item.visible = false
	} )

	item.FindChildTraverse( "Countdown" ).AddClass( "Active" )

	droppedItems[data.item] = item

	$.Schedule( 15, function() {
		if (item.IsValid()) {
			item.RemoveClass( "Slide" )
			item.DeleteAsync( 0.3 )
		}
	})
}

function NeutralItemTaked( data ) {
	Game.EmitSound( "Loot_Drop_Stinger_Short" )

	if ( droppedItems[data.item] ) {
		droppedItems[data.item].DeleteAsync( 0 )
		droppedItems[data.item].RemoveClass( "Slide" )
		droppedItems[data.item].visible = false
		droppedItems[data.item] = false
	}

	let taked = $.CreatePanel( "Panel", $( "#ItemsContainer" ), "" )
	taked.BLoadLayoutSnippet( "WhoTakedItem" )
	taked.AddClass( "Slide" )
	taked.FindChildTraverse( "ItemImage" ).itemname = Abilities.GetAbilityName( data.item )
	taked.FindChildTraverse( "HeroImage" ).heroname = Players.GetPlayerSelectedHero( data.player )

	$.Schedule( 5, function() {
		taked.RemoveClass( "Slide" )
		taked.DeleteAsync( 0.3 )
	} )
}

GameEvents.SubscribeProtected( "neutral_item_taked", NeutralItemTaked )
GameEvents.SubscribeProtected( "neutral_item_dropped", NeutralItemDropped )
GameEvents.SubscribeProtected( "neutral_item_picked_up", NeutralItemPickedUp )