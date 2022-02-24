// The tips we can show
var tipsGeneral = [
    {
        img: 'file://{resources}/images/custom_game/tips_icon/tip_chat_wheel.png',
        txt: '#LoadingTip_1'
    },{
        img: 'file://{resources}/images/custom_game/tips_icon/towers.png',
        txt: '#LoadingTip_2'
    },{
        img: 'file://{resources}/images/custom_game/tips_icon/kicktroll.png',
        txt: '#LoadingTip_3'
    },{
        img: 'file://{resources}/images/custom_game/tips_icon/respawn.png',
        txt: '#LoadingTip_4'
    },{
        img: 'file://{resources}/images/custom_game/tips_icon/disablehelp.png',
        txt: '#LoadingTip_5'
    },{
        img: 'file://{resources}/images/custom_game/tips_icon/mute.png',
        txt: '#LoadingTip_6'
    },{
        img: 'file://{resources}/images/custom_game/tips_icon/raxes.png',
        txt: '#LoadingTip_7'
    },{
        img: 'file://{resources}/images/custom_game/tips_icon/fountain.png',
        txt: '#LoadingTip_8'
    },{
        img: 'file://{resources}/images/custom_game/tips_icon/itemtransfer.png',
        txt: '#LoadingTip_9'
    },{
        img: 'file://{resources}/images/custom_game/tips_icon/perks.png',
        txt: '#LoadingTip_10'
    },{
        img: 'file://{resources}/images/custom_game/tips_icon/nerfed.png',
        txt: '#LoadingTip_11'
    },{
        img: 'file://{resources}/images/custom_game/tips_icon/helpus.png',
        txt: '#LoadingTip_12'
    },{
        img: 'file://{resources}/images/custom_game/tips_icon/savefavs.png',
        txt: '#LoadingTip_13'
    },{
		img: 'file://{resources}/images/custom_game/tips_icon/mmr_balance.png',
		txt: '#LoadingTip_14'
	},{
		img: 'file://{resources}/images/custom_game/tips_icon/nerfed2.png',
		txt: '#LoadingTip_15'
	},
];
// Start flag
var isTipStarted = false;

// How long to wait before we show the next tip
var tipDelay = 15;

// Tip context panel
var tipContextPanel = null;

var phase = 0;

// Contains a list of all tip IDs
var allTips = [];
var tipUpto = 0;

var randomLists = [tipsGeneral];
var randomedTips = {};

function checkCount( lists ) {
    return lists.filter(function(list){
        return Object.keys(list).length > 0;
    }).length > 0;
}

var count = 0;
while (checkCount(randomLists)) {
    for(var i = 0; i < randomLists.length; i++){
        var list = randomLists[i];
        if (Object.keys(list).length == 0)
            continue;

        var key = Object.keys(list)[Math.floor(Math.random() * Object.keys(list).length)];
        randomedTips[count] = list[key];
        count++;

        delete list[key];
    }
}

// Sets the hint
function setHint(img, txt) {
	if (tipContextPanel == null)
		return;

    // Set the image
    var tipImage = tipContextPanel.FindChildTraverse('LoadingTipImage');
    if(tipImage != null) {
        tipImage.SetImage(img);
    }

    var tipText = tipContextPanel.FindChildTraverse('LoadingTipText');
    if(tipText != null) {
        tipText.text = txt;
    }
}
var nextTipSchelude
var hintsTurn = []
// Show the next hint
function nextHint(stopFunct) {
	if(nextTipSchelude){
		$.CancelScheduled(nextTipSchelude);
	}
    // Set the next tip
    var tip = randomedTips[tipUpto++];
    setHint(tip.img, $.Localize(tip.txt));

    if(tipUpto > Object.keys(randomedTips).length - 1) {
        tipUpto = 0;
    }
	hintsTurn.push(tip)
    // Schedule the next tip
    nextTipSchelude = $.Schedule(tipDelay, function() {
    	nextTipSchelude = undefined;
		nextHint();
	});

	if (hintsTurn.length == 1){$("#PrevTip").visible = false}else{$("#PrevTip").visible = true}
}

function prevHint(stopFunct) {
	if(hintsTurn.length > 1){
		if(nextTipSchelude){
			$.CancelScheduled(nextTipSchelude);
		}
		nextTipSchelude = $.Schedule(tipDelay, function() {
			nextTipSchelude = undefined;
			nextHint();
		});
		hintsTurn = hintsTurn.slice(0, -1);
		var tip = hintsTurn[hintsTurn.length - 1]
		if (hintsTurn.length == 1){$("#PrevTip").visible = false}
		if(tip != undefined){
			setHint(tip.img, $.Localize(tip.txt));
		}
	}
}


function startTips(panel){
    if (panel == null)
        return;

    if (tipContextPanel != null)
    tipContextPanel.visible = false;

    tipContextPanel = panel;

    if (!isTipStarted){
        // Show the first hint
        nextHint();
        isTipStarted = true;
    }
};
startTips($("#LoadingScreenTipsPanel"));
