const LOCAL_PID = Game.GetLocalPlayerID();

function ApplyGoldBonuses(winrates) {
	if (CustomNetTables.GetTableValue("game_state", "game_options_results")["no_winrate_gold_bonus"]) return;
	if (!winrates) return;
	var preGameRoot = FindDotaHudElement("PreGame");
	const heroCards = preGameRoot.FindChildrenWithClassTraverse("HeroCard");
	if (heroCards.length === 0) {
		$.Schedule(0.1, () => ApplyGoldBonuses(winrates));
		return;
	}

	let heroes_without_bonus = [];
	let playersStats = CustomNetTables.GetTableValue("game_state", "player_stats");
	if (playersStats && playersStats[LOCAL_PID] && playersStats[LOCAL_PID].lastWinnerHeroes) {
		heroes_without_bonus = Object.values(playersStats[LOCAL_PID].lastWinnerHeroes);
	}

	for (var heroCard of heroCards) {
		const heroImage = heroCard.FindChildTraverse("HeroImage");

		if (!heroImage) continue;

		const shortName = heroImage.heroname;
		const heroName = "npc_dota_hero_" + shortName;

		if (heroes_without_bonus.indexOf(heroName) > -1) continue;

		const winrate = winrates[heroName];
		if (!winrate) continue;

		const bonusGoldBackground =
			heroImage.FindChild("BonusGoldBackground") || $.CreatePanel("Panel", heroImage, "BonusGoldBackground");
		bonusGoldBackground.style.width = "100%";
		bonusGoldBackground.style.paddingBottom = "8px";
		bonusGoldBackground.style.align = "center top";
		bonusGoldBackground.style.backgroundColor = `gradient(linear, 0% 0%, 0% 100%, from(#895c00), to(#fac30000))`;

		const goldLabel =
			bonusGoldBackground.FindChild("BonusGold") || $.CreatePanel("Label", bonusGoldBackground, "BonusGold");
		goldLabel.style.backgroundImage = `url("file://{resources}/images/custom_game/import_dota/gold_small_psd.png")`;
		goldLabel.style.textShadow = "2px 2px 8px 3 #333333b0";
		goldLabel.style.backgroundRepeat = "no-repeat";
		goldLabel.style.backgroundSize = "10px 10px";
		goldLabel.style.backgroundPosition = "right middle";
		goldLabel.style.fontFamily = "monospaceNumbersFont";
		goldLabel.style.fontSize = "12px";
		goldLabel.style.color = "#fac300";
		goldLabel.style.fontWeight = "bold";
		goldLabel.style.paddingRight = "10px";
		goldLabel.style.horizontalAlign = "center";
		goldLabel.style.marginTop = "2px";

		// formula for display text only, actual gold given is calculated in addon_game_mode.lua in OnNPCSpawned
		const fixed_winrate = Math.min(winrate * 100.0, 49.99);
		goldLabel.text = Math.floor((-100 * fixed_winrate + 5100) / 5.0) * 5;
	}
}

var startingItemsLeftColumn = FindDotaHudElement("StartingItemsLeftColumn");
for (var child of startingItemsLeftColumn.Children()) {
	if (child.BHasClass("PatreonBonusButtonContainer")) {
		child.DeleteAsync(0);
	}
}

var inventoryStrategyControl = FindDotaHudElement("InventoryStrategyControl");
inventoryStrategyControl.style.marginTop = 46 - 32 + "px";

var patreonBonusButton = $.CreatePanel("Panel", startingItemsLeftColumn, "");
patreonBonusButton.BLoadLayout(
	"file://{resources}/layout/custom_game/common/hero_selection_overlay/patreon_bonus_button.xml",
	false,
	false,
);
startingItemsLeftColumn.MoveChildAfter(patreonBonusButton, startingItemsLeftColumn.GetChild(0));

var heroPickRightColumn = FindDotaHudElement("HeroPickRightColumn");
var smartRandomButton = heroPickRightColumn.FindChildTraverse("smartRandomButton");
if (smartRandomButton != null) smartRandomButton.DeleteAsync(0);
smartRandomButton = $.CreatePanel("Button", heroPickRightColumn, "smartRandomButton");
smartRandomButton.BLoadLayout(
	"file://{resources}/layout/custom_game/common/hero_selection_overlay/smart_random.xml",
	false,
	false,
);

SubscribeToNetTableKey("game_state", "player_stats", function (playerStats) {
	var localStats = playerStats[LOCAL_PID];
	if (!localStats) return;

	$("#PlayerStatsAverageWinsLoses").text = localStats.wins + "/" + localStats.loses;
	$("#PlayerStatsAverageKDA").text = [localStats.averageKills, localStats.averageDeaths, localStats.averageAssists]
		.map(Math.round)
		.join("/");
	$("#PlayerStatsAverageStreak").text = localStats.bestStreak + "/" + localStats.streak;
});

SubscribeToNetTableKey("heroes_winrate", "heroes", ApplyGoldBonuses);

$.GetContextPanel().SetDialogVariable("map_name", Game.GetMapInfo().map_display_name);
