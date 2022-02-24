const TEAMS_ROOT = $(`#EG_TeamsTable`);
const TEAM_GOODGUYS = 2;
const TEAM_BADGUYS = 3;
const LOCAL_PLAYER_ID = Game.GetLocalPlayerID();

function CreatePlayer(player_id, players_root, team_id) {
	const player_panel = $.CreatePanel("Panel", players_root, `EG_PlayerRoot_${player_id}`);
	player_panel.BLoadLayoutSnippet("EG_Player");

	var player_info = Game.GetPlayerInfo(player_id);
	if (player_info == undefined) return;

	player_panel.SetHasClass("LocalPlayer", player_id == LOCAL_PLAYER_ID);

	const set_number_value_stat = function (panel_name, value) {
		player_panel.FindChildTraverse(panel_name).text = ParseBigNumber(Math.ceil(value || 0));
	};

	var hero_portrait = player_panel.FindChildTraverse("HeroIcon");
	if (player_info.player_selected_hero !== "") {
		hero_portrait.SetImage(GetPortraitImage(player_id, player_info.player_selected_hero));
	} else {
		hero_portrait.SetImage("file://{images}/custom_game/unassigned.png");
	}

	player_panel.FindChildTraverse("PlayerName").text = player_info.player_name;

	var hero_name_desc = player_panel.FindChildTraverse("HeroNameAndDescription");

	if (player_info.player_selected_hero_id == -1) {
		hero_name_desc.SetDialogVariable("hero_name", $.Localize(`#DOTA_Scoreboard_Picking_Hero`));
	} else {
		hero_name_desc.SetDialogVariable("hero_name", $.Localize(`#${player_info.player_selected_hero}`));
	}

	hero_name_desc.SetDialogVariableInt("hero_level", player_info.player_level);

	set_number_value_stat("Kills", Players.GetKills(player_id));
	set_number_value_stat("Deaths", Players.GetDeaths(player_id));
	set_number_value_stat("Assists", Players.GetAssists(player_id));

	const hero_ent_idx = Players.GetPlayerHeroEntityIndex(player_id);

	const items = Game.GetPlayerItems(player_id);
	if (items && items.inventory) {
		const items_root = player_panel.FindChildTraverse("EG_Items");
		for (let idx = 0; idx <= 6; idx++) {
			if (!items.inventory[idx]) continue;
			items_root.GetChild(idx).itemname = items.inventory[idx].item_name;
		}

		const n_item = Entities.GetItemInSlot(hero_ent_idx, 16);
		if (n_item) items_root.GetChild(6).itemname = Abilities.GetAbilityName(n_item);
	}

	if (
		GetModifierStackCount(hero_ent_idx, "modifier_item_ultimate_scepter") != undefined ||
		GetModifierStackCount(hero_ent_idx, "modifier_item_ultimate_scepter_consumed") != undefined ||
		GetModifierStackCount(hero_ent_idx, "modifier_item_ultimate_scepter_consumed_alchemist") != undefined
	)
		player_panel
			.FindChildTraverse("EG_AghScepter")
			.SetImage("s2r://panorama/images/hud/reborn/aghsstatus_scepter_on_psd.vtex");

	if (GetModifierStackCount(hero_ent_idx, "modifier_item_aghanims_shard") != undefined)
		player_panel
			.FindChildTraverse("EG_AghShard")
			.SetImage("s2r://panorama/images/hud/reborn/aghsstatus_shard_on_psd.vtex");

	const moonshard_panel = player_panel.FindChildTraverse("Moonshard");
	const b_hero_has_moonshard = GetModifierStackCount(hero_ent_idx, "modifier_item_moon_shard_consumed") != undefined;

	moonshard_panel.SetHasClass("NotActive", !b_hero_has_moonshard);
	moonshard_panel.SetPanelEvent("onmouseover", function () {
		if (b_hero_has_moonshard) $.DispatchEvent("DOTAShowAbilityTooltip", moonshard_panel, "item_moon_shard");
		else
			$.DispatchEvent(
				"DOTAShowTitleTextTooltip",
				moonshard_panel,
				`#EG_Moonshard_Title`,
				`#EG_Moonshard_Description`,
			);
	});

	moonshard_panel.SetPanelEvent("onmouseout", function () {
		if (b_hero_has_moonshard) $.DispatchEvent("DOTAHideAbilityTooltip", moonshard_panel);
		else $.DispatchEvent("DOTAHideTitleTextTooltip", moonshard_panel);
	});

	set_number_value_stat("Gpm", Players.GetGoldPerMin(player_id));

	var end_game_stats = CustomNetTables.GetTableValue("custom_stats", player_id.toString());
	const killed_enemies_root = player_panel.FindChildTraverse("EG_KilledHeroes");
	for (const _team of Game.GetAllTeamIDs()) {
		if (_team == team_id) continue;
		for (const _player_id of Game.GetPlayerIDsOnTeam(_team)) {
			const enemy_player_info = Game.GetPlayerInfo(_player_id);
			if (enemy_player_info) {
				var e_hero = enemy_player_info.player_selected_hero;
				if (e_hero != -1 && e_hero != "" && typeof e_hero == "string") {
					var icon = $.CreatePanel("Image", killed_enemies_root, "");
					icon.SetImage(`file://{images}/heroes/icons/${e_hero}.png`);
					icon.AddClass("HeroIcon");

					if (end_game_stats && end_game_stats.killed_heroes && end_game_stats.killed_heroes[e_hero]) {
						var count = $.CreatePanel("Label", icon, "");
						count.text = "x" + ParseBigNumber(end_game_stats.killed_heroes[e_hero]);
						count.AddClass("KilledCount");
					} else {
						icon.AddClass("NoKills");
					}
				}
			}
		}
	}

	const mmr_change = GetRatingChanges(player_id);
	const rating_changes_label = player_panel.FindChildTraverse(`RatingChanges`);

	rating_changes_label.text = `${mmr_change >= 0 ? "+" : ""}${ParseBigNumber(mmr_change)}`;
	if (mmr_change != 0) rating_changes_label.AddClass(mmr_change > 0 ? "MmrInc" : "MmrDec");

	if (!end_game_stats) return;

	if (end_game_stats.perk && end_game_stats.perk != "") {
		const perk_name = end_game_stats.perk.replace(/_t\d$/, "_t1");
		const perk_panel = player_panel.FindChildTraverse("Perk");
		perk_panel.SetImage(`file://{resources}/layout/custom_game/common/game_perks/icons/${perk_name}.png`);

		perk_panel.SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("DOTAShowTextTooltip", perk_panel, `DOTA_Tooltip_${perk_name}`);
		});
		perk_panel.SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("DOTAHideTextTooltip", perk_panel);
		});
	}

	set_number_value_stat("Networth", end_game_stats.networth);
	set_number_value_stat("Xpm", end_game_stats.xpm);
	set_number_value_stat("BuildingDamage", end_game_stats.building_damage);
	set_number_value_stat("HeroDamage", end_game_stats.hero_damage);
	set_number_value_stat("DamageTaken", end_game_stats.damage_taken);
	set_number_value_stat("Heal", end_game_stats.total_healing);

	const wards_root = player_panel.FindChildTraverse("Wards");
	wards_root.SetDialogVariable("observers", end_game_stats.wards.npc_dota_observer_wards);
	wards_root.SetDialogVariable("sentries", end_game_stats.wards.npc_dota_sentry_wards);
}

function GetTeamAverageRating(team) {
	let avg_rating = 1500;
	if (Game.IsInToolsMode()) return avg_rating;
	const local_players_stats = CustomNetTables.GetTableValue("game_state", "player_stats");
	if (!local_players_stats) return avg_rating;

	let rating_total = 0;
	let rating_count = 0;
	Object.entries(local_players_stats).forEach(([player_id, player_data]) => {
		player_id = parseInt(player_id);
		if (!player_id) return;
		if (Players.GetTeam(player_id) != target_team) return;

		rating_total += player_data.rating || 1500;
		rating_count++;
	});
	if (rating_count > 0) avg_rating = rating_total / rating_count;

	return avg_rating;
}

function GetOtherTeamsAverageRating(target_team) {
	let avg_rating = 1500;
	if (Game.IsInToolsMode()) return avg_rating;
	const local_players_stats = CustomNetTables.GetTableValue("game_state", "player_stats");
	if (!local_players_stats) return avg_rating;

	let rating_total = 0;
	let rating_count = 0;
	Object.entries(local_players_stats).forEach(([player_id, player_data]) => {
		player_id = parseInt(player_id);
		if (!player_id) return;
		if (Players.GetTeam(player_id) == target_team) return;

		rating_total += player_data.rating || 1500;
		rating_count++;
	});
	if (rating_count > 0) avg_rating = rating_total / rating_count;

	return avg_rating;
}

function GetPlayerRating(target_player_id) {
	let player_rating = 1500;

	const local_rating_data = CustomNetTables.GetTableValue("game_state", "player_stats");

	if (local_rating_data && local_rating_data[target_player_id.toString()])
		player_rating = local_rating_data[target_player_id.toString()].rating || 1500;

	return player_rating;
}

function GetRatingChanges(input_player_id) {
	const player_team = Players.GetTeam(input_player_id);

	const multiplier = 0.025;
	const base_change = Game.GetGameWinner() == player_team ? 30 : -30;
	const cap = 15;

	let other_teams_avg_rating = GetOtherTeamsAverageRating(player_team);
	let primary_rating = GetTeamAverageRating(player_team);

	let score_delta = Math.round((other_teams_avg_rating - primary_rating) * multiplier);

	const is_player_bot = () => {
		const player_info = Game.GetPlayerInfo(input_player_id);
		if (!player_info) return true;

		return player_info.player_connection_state == DOTAConnectionState_t.DOTA_CONNECTION_STATE_NOT_YET_CONNECTED;
	};

	return is_player_bot() ? 0 : base_change + Math.clamp(score_delta, -cap, cap);
}

function CreateTeamRoot(team_id) {
	const team_panel = $.CreatePanel("Panel", TEAMS_ROOT, "");
	team_panel.BLoadLayoutSnippet("EG_Team");

	const root_for_players = team_panel.FindChildTraverse("PlayersContainer");
	for (const player_id of Game.GetPlayerIDsOnTeam(team_id)) {
		CreatePlayer(player_id, root_for_players, team_id);
	}
	const team_info = Game.GetTeamDetails(team_id);
	team_panel.FindChildTraverse("EG_TeamName").text = `${$.Localize(team_info.team_name)}: ${team_info.team_score}`;

	team_panel.AddClass(`Team_${team_id}`);
	team_panel.SetHasClass("LocalTeam", team_id == Players.GetTeam(LOCAL_PLAYER_ID));
}

function EG_ShowChat() {
	$.GetContextPanel().ToggleClass("ShowChat");
}

(function () {
	TEAMS_ROOT.RemoveAndDeleteChildren();

	$("#EG_VictoryLabel").SetDialogVariable(
		"winning_team_name",
		$.Localize(Game.GetTeamDetails(Game.GetGameWinner()).team_name),
	);

	CreateTeamRoot(TEAM_GOODGUYS);
	CreateTeamRoot(TEAM_BADGUYS);
})();
