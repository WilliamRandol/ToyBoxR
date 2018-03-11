local ToyBoxR = LibStub("AceAddon-3.0"):NewAddon("ToyBoxR", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local LibQTip = LibStub("LibQTip-1.0");
local appName = ...

ToyBoxR.TBR = {};
local TBR = ToyBoxR.TBR;
TBR.VERSION = GetAddOnMetadata(appName, "Version");

TBR.OnlyMissing = false;

TBR.MOP = 1
TBR.WOD = 2

TBR.DEBUG_MODE = false;

TBR.IconFormat = "|T%s:20:20|t"

TBR.ToysShowing = false;

local MENU_ALPHABETIC = 1
local MENU_CATEGORY = 2
local MENU_EXPANSION = 3
local MENU_MISSING = 4

local TEXT_WIDTH = 200

local inTooltip

--local Orig_GameTooltip_OnShow
local Orig_GameTooltip_SetItem
local Orig_GameTooltip_ClearItem

--local Orig_ItemRefTooltip_OnShow
local Orig_ItemRefTooltip_SetItem
local Orig_ItemRefTooltip_ClearItem

local defaults = {
	profile = {
		Scale = 1,
		Coloring = true,
	},
	char = {
		LastVersion = TBR.VERSION,
		ToyBoxRList = {},
		UseGlobal = false,
		Custom = {},
	},
	global = {
		minimap = { hide = false },
		mod = 1,
		ToyBoxRList = {},
		ShowMissing = true,
		Width = 900,
		Height = 560,
		HideNLA = false,
		HidePurchased = false,
		HideFaction = false,
		View = TBR.VIEW_ALL,
	}
}

function ToyBoxR:Print(...)
	local output, part
	for i=1, select("#", ...) do
		part = select(i, ...)
		part = tostring(part):gsub("{{", "|cffddeeff"):gsub("}}", "|r")
		if part ~= "" then
			if (output) then output = output .. " " .. part
			else output = part end
		end
	end
	ChatFrame1:AddMessage("|cff00E5EEToyBoxR: |r"..output, 1.0, 1.0, 1.0);
end

function ToyBoxR:Debug(...)
	if(TBR.DEBUG_MODE) then
		local output, part
		for i=1, select("#", ...) do
			part = select(i, ...)
			part = tostring(part):gsub("{{", "|cffddeeff"):gsub("}}", "|r")
			if (output) then output = output .. " " .. part
			else output = part end
		end
		ChatFrame1:AddMessage("|cff00E5EEToyBoxR Debug: |r"..output, 1.0, 1.0, 1.0);
	end
end

function ToyBoxR:RegisterSlashCommands()
	self:RegisterChatCommand("TBR", "ChatCmd");
end

function ToyBoxR:ChatCmd(args)
	if args == "scan" then
		ToyBoxR:Scan()
	elseif args == "help" then
		print("|cff1eff00TBR :|r Opens UI");
		print("|cff1eff00TBR scan|r : Scan all bags (bank if open) for toys.");
	else
		ToyBoxR:UIOpen();
	end
end

local isTooltipDone = nil;

local function TBR_ItemFromLink(link)
--	local itemString = string.match(link, "item[%-?%d:]+")
--	local _, itemID, permEnchant, jewelId1, jewelId2, jewelId3, jewelId4, suffix, uniqueId, linkLevel, reforgeId = strsplit(":", link)
--	local itemName = strmatch(link, "|h%[([^%]]*)%]|h");
	local _, itemID = strsplit(":", link)
	return tonumber(itemID);
end

--local function OnItemRefTooltipShow(tooltip, ...)
--	if Orig_ItemRefTooltip_OnShow then
--		Orig_ItemRefTooltip_OnShow(tooltip, ...)
--	end
--
--	ItemRefTooltip:Show()
--end

local function OnItemRefTooltipSetItem(tooltip, ...)
	if Orig_ItemRefTooltip_SetItem then
		Orig_ItemRefTooltip_SetItem(tooltip, ...)
	end
	
	if (not isTooltipDone) and tooltip and not inTooltip then
		local name, link = tooltip:GetItem()
		isTooltipDone = true
		if link then
			local itemID = TBR_ItemFromLink(link);
			if itemID ~= nil then
				local toy = ToyBoxR.ToyDB:GetToy(itemID);
				if toy ~= nil then
					ToyBoxR:TooltipInfo(toy, tooltip)
				end
			end
		end
	end
end

local function OnItemRefTooltipCleared(tooltip, ...)
	isTooltipDone = nil
	return Orig_ItemRefTooltip_ClearItem(tooltip, ...)
end

--local function OnGameTooltipShow(tooltip, ...)
--	if Orig_GameTooltip_OnShow then
--		Orig_GameTooltip_OnShow(tooltip, ...)
--	end	
--	
--	GameTooltip:Show()
--end

local function OnGameTooltipSetItem(tooltip, ...)
	if Orig_GameTooltip_SetItem then
		Orig_GameTooltip_SetItem(tooltip, ...)
	end
	if (not isTooltipDone) and tooltip and not inTooltip then
		local name, link = tooltip:GetItem()
		isTooltipDone = true
		if link then
			local itemID = TBR_ItemFromLink(link);
			if itemID ~= nil then
				local toy = ToyBoxR.ToyDB:GetToy(itemID);
				if toy ~= nil then
					ToyBoxR:TooltipInfo(toy, tooltip)
				end
			end
		end
	end
end

local function OnGameTooltipCleared(tooltip, ...)
	isTooltipDone = nil
	return Orig_GameTooltip_ClearItem(tooltip, ...)
end


function ToyBoxR:OnInitialize()
	TBR.KnownToys = {};
	TBR.UnknownToys = {};
	TBR.frame = nil;
	TBR.grp = nil;

	TBR.db = LibStub("AceDB-3.0"):New("ToyBoxRDB", defaults, true);

	TBR.db.char.OnlyChar = nil;

	TBR.db.global.Notes = nil;

	if TBR.db.char.Custom == nil then
		TBR.db.char.Custom = {};
	end

	TBR.db.global.HideWoD = nil;

	ToyBoxR:RegisterSlashCommands();
	-- Run AceConfigReg/Dialog
--	Orig_GameTooltip_OnShow = GameTooltip:GetScript("OnShow")
	Orig_GameTooltip_SetItem = GameTooltip:GetScript("OnTooltipSetItem")
	Orig_GameTooltip_ClearItem = GameTooltip:GetScript("OnTooltipCleared")	
--	Orig_ItemRefTooltip_OnShow = ItemRefTooltip:GetScript("OnShow")
	Orig_ItemRefTooltip_SetItem = ItemRefTooltip:GetScript("OnTooltipSetItem")
	Orig_ItemRefTooltip_ClearItem = ItemRefTooltip:GetScript("OnTooltipCleared")
	
--	GameTooltip:SetScript("OnShow", OnGameTooltipShow)
	GameTooltip:SetScript("OnTooltipSetItem", OnGameTooltipSetItem)
	GameTooltip:SetScript("OnTooltipCleared", OnGameTooltipCleared)
--	ItemRefTooltip:SetScript("OnShow", OnItemRefTooltipShow)
	ItemRefTooltip:SetScript("OnTooltipSetItem", OnItemRefTooltipSetItem)
	ItemRefTooltip:SetScript("OnTooltipCleared", OnItemRefTooltipCleared)
end

function ToyBoxR:OnEnable()
	C_ToyBox.SetAllSourceTypeFilters( true );
	C_ToyBox.SetCollectedShown( true );
	C_ToyBox.SetUncollectedShown( true );
	C_ToyBox.SetFilterString("");
	ToggleCollectionsJournal();

	if TBR.db.char.UseGlobal then
		TBR.db.char.ToyBoxRList = TBR.TableCopy(TBR.db.global.ToyBoxRList);
	end
	ToyBoxR:UpdateKnownToys();
	self:RegisterEvent("TOYS_UPDATED", "UpdateKnownToys")
	ToggleCollectionsJournal();
	TBR.faction = UnitFactionGroup("player");
end

local function UISelectExpTree(container, event, group)
	TBR.ExpTree = group;
	container:ReleaseChildren();
	ToyBoxR:PopulateWindowExpansion(container, TBR.ExpTree);
end

local function UISelectCatTree(container, event, group)
	TBR.CatTree = group;
	container:ReleaseChildren();
	ToyBoxR:PopulateWindowCategory(container, TBR.CatTree);
end

local function UISort_Alphebetic(container)
	ToyBoxR:PopulateWindowCategory(TBR.UIData, TBR.ALL:GetName());
end

local function UISort_Expansion(container)
	local tree = AceGUI:Create("TreeGroup");
	tree:SetLayout("Fill");

	local treeinfo = {};
	local expansions = ToyBoxR.ToyDB:GetExpansionList();
	local first = expansions[1];
	for i,j in pairs(expansions) do
		cnt = ToyBoxR.ToyDB:GetKnownExpCnt(i);
		if TBR.db.global.ShowMissing then
			cnt = cnt + ToyBoxR.ToyDB:GetUnknownExpCnt(i)
		end
		if cnt ~= 0 then
			local val = { text=j.." ["..cnt.."]", value=j };
			table.insert(treeinfo, val);
		end
	end
	tree:SetTree(treeinfo);
	tree:SetCallback("OnGroupSelected", UISelectExpTree);

	if TBR.ExpTree ~= nil then
		tree:SelectByValue(TBR.ExpTree)
	else
		tree:SelectByValue(first);
	end
	TBR.UIData:AddChild(tree);
end

local function UISort_ToyBoxR(container)
	local tree = AceGUI:Create("TreeGroup");
	tree:SetLayout("Fill");

	local treeinfo = {};
	local categories = ToyBoxR.ToyDB:GetCategoryList();
	for i,j in pairs(categories) do
		if j ~= TBR.GENERAL then
			local cnt;

			if TBR.OnlyMissing == true then
				cnt = j:GetUnknownCnt();
			else
				cnt = j:GetKnownCnt();
				if TBR.db.global.ShowMissing then
					cnt = cnt + j:GetUnknownCnt();
				end
			end
			if cnt ~= 0 then
				local val = { text=j:GetName().." ["..cnt.."]", value=j:GetName() };
				table.insert(treeinfo, 1, val);
			end
		end
	end

	tree:SetTree(treeinfo);
	tree:SetCallback("OnGroupSelected", UISelectCatTree);
	if TBR.CatTree ~= nil then
		tree:SelectByValue(TBR.CatTree)
	else
		tree:SelectByValue(TBR.ALL:GetName());
	end
	TBR.UIData:AddChild(tree);
end

local function UISelectTab(container, event, group)
	TBR.container = container;
	container:ReleaseChildren();
	TBR.ToysShowing = false;
	if group == "toys" then
		TBR.ToysShowing = true;
		container:SetLayout("Flow");
		ToyBoxR:UIToyTab(container, event, group);	
	elseif group == "custom" then
		container:SetLayout("Fill");
		ToyBoxR:UICustomTab(container, event, group);
	elseif group == "config" then
		container:SetLayout("Flow");
		ToyBoxR:UIConfigTab(container, event, group);
	end
end

local function confirmPopup(rootframe, message, func, ...)
	if not StaticPopupDialogs["ACECONFIGDIALOG30_CONFIRM_DIALOG"] then
		StaticPopupDialogs["ACECONFIGDIALOG30_CONFIRM_DIALOG"] = {}
	end
	local t = StaticPopupDialogs["ACECONFIGDIALOG30_CONFIRM_DIALOG"]
	for k in pairs(t) do
		t[k] = nil
	end
	t.text = message
	t.button1 = ACCEPT
	t.button2 = CANCEL
	t.preferredIndex = STATICPOPUP_NUMDIALOGS
	local dialog, oldstrata
	t.OnAccept = function()
		func();
	end
	t.OnCancel = function()
	end
	t.timeout = 0
	t.whileDead = 1
	t.hideOnEscape = 1

	dialog = StaticPopup_Show("ACECONFIGDIALOG30_CONFIRM_DIALOG")
	if dialog then
		oldstrata = dialog:GetFrameStrata()
		dialog:SetFrameStrata("TOOLTIP")
	end
end

function TBR_Confirmed()
	local allon = true;
	local someoff = false;

	for i, j in pairs(TBR.CheckBoxList) do
		local toy = j:GetUserData('toy');
		if j:GetValue() == true then
			allon = false;
		end
	end

	for i, j in pairs(TBR.CheckBoxList) do
		local toy = j:GetUserData('toy');
		if not allon or toy:CanUse() then
			j:SetValue(allon);
			toy:UpdateList(allon);
		end
		if allon and not toy:CanUse() then
			someoff = true;
		end
	end
	if someoff then
		ToyBoxR:Print("Some toys did not select due to faction, rep, profession or level restrictions.");
	end
end

local function TBR_AddTooltipInfo(self, info)
	ShowUIPanel(GameTooltip);
	GameTooltip:SetOwner(self.frame, "ANCHOR_RIGHT", 0, -25);
	GameTooltip:AddLine(info, nil, nil, nil, true);
	GameTooltip:Show();
end

local function TBR_GameTooltip(box)
	if IsControlKeyDown() then
		return 
	end

	ShowUIPanel(GameTooltip);

	local toy = box:GetUserData('toy');

	GameTooltip:SetOwner(box.frame, "ANCHOR_RIGHT", 0, -75);
	GameTooltip:SetHyperlink(toy:GetLink())

	ToyBoxR:TooltipInfo(toy, GameTooltip)

	GameTooltip:Show()
end

function ToyBoxR:UICustomTab(container, event, group)
	local sf = AceGUI:Create("ScrollFrame");
	sf:SetLayout("List");

	container:AddChild(sf);

	local editbox = AceGUI:Create("EditBox");
	editbox:SetLabel("Enter (or drop) new custom item here:");
	editbox:SetCallback("OnEnterPressed", function(self, event, text)
		if text == "" then return end
		local toyID = tonumber(text);
		if toyID == nil then
			local _, itemlink = GetItemInfo(text);
			if itemlink then
				text = itemlink;
			end
		end

		if toyID == nil then
			toyID = TBR_ItemFromLink(text);
			if toyID == nil then
				ToyBoxR:Print("Item", text, "not found.");
				return;
			end
		end

		local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(toyID);
		if itemName == nil then
			ToyBoxR:Print("Item", text, "not found.");
			return;
		end
		
		local toy = ToyBoxR.ToyDB:GetToy(toyID);
		if toy ~= nil then
			ToyBoxR:Print("Item", itemName, "is already in your ToyBox");
			return;
		end
		ToyBoxR.ToyDB:CreateToy(toyID, ToyBoxR.ToyDB:GetCustom());
		ToyBoxR.ToyDB:AddToyInfo(itemName, itemLink, itemTexture, toyID, true);
		table.insert(TBR.db.char.Custom, {toyID, false});
		UISelectTab(TBR.container, nil, "custom");
		ToyBoxR:UpdateToyCnt();
		end);
	editbox:SetCallback("OnEnter", function(self, event)
		TBR_AddTooltipInfo(self, "This allows you to add custom items from your inventory to ToyBoxR. Enter item name, id or drag and drop the item. Items can be found in the 'Custom' category.");
		end);
	editbox:SetCallback("OnLeave", function () 
		ShowUIPanel(GameTooltip)
		GameTooltip:Hide() 
		end);
	sf:AddChild(editbox);

	local header = AceGUI:Create("Heading");
	header:SetText("Known Custom Toys");
	sf:AddChild(header)

	for i,j in pairs(TBR.db.char.Custom) do
		local containerpairing = AceGUI:Create("SimpleGroup")
		containerpairing:SetLayout("Flow") 
		containerpairing:SetWidth(700);

		local box = AceGUI:Create("QCheckBox");
		local toy = ToyBoxR.ToyDB:GetToy(j[1]);
		local name = toy:GetName();

		local r, g, b, hex = GetItemQualityColor(toy:GetQuality());
		box:SetColor(r, g, b);
		box:SetWidth(TEXT_WIDTH);
		box:SetLabel(toy:GetName());
		box:SetImage(toy:GetIcon());
		box:SetImageSize(18,18);
		box:RemoveCheck(true);
		box:SetUserData('toy', toy);
		box:SetUserData('link', toy:GetLink());
		containerpairing:AddChild(box);
		box:SetCallback("OnEnter", function (self, event) 
			inTooltip = true;
			TBR_GameTooltip(self);
		end);
		box:SetCallback("OnLeave", function () ShowUIPanel(GameTooltip)
			inTooltip = false;
			GameTooltip:Hide() end);

		local btn = AceGUI:Create("Button");
		btn:SetText("x");
		btn:SetHeight(18);
		btn:SetWidth(42);
		btn:SetUserData('toy', toy);
		btn:SetCallback("OnClick", function(self, event, key) 
			local toy = self:GetUserData('toy');
			local toyID = toy:GetID();
			local idx;
			for i,j in pairs(TBR.db.char.Custom) do
				if j[1] == toyID then
					idx = i;
				end
			end
			table.remove(TBR.db.char.Custom, idx);
			toy:Delete();
			UISelectTab(TBR.container, nil, "custom");
			ShowUIPanel(GameTooltip)
			GameTooltip:Hide() 
			ToyBoxR:UpdateToyCnt();
		end);
		btn:SetCallback("OnEnter", function(self, event)
			TBR_AddTooltipInfo(self, "Delete this custom toy from ToyBoxR.");
			end);
		btn:SetCallback("OnLeave", function () 
			ShowUIPanel(GameTooltip)
			GameTooltip:Hide() 
		end);
		containerpairing:AddChild(btn);

		local transform = AceGUI:Create("CheckBox");
		transform:SetWidth(100);
		transform:SetLabel("Transform?");
		transform:SetUserData('toy', toy);
		transform:SetValue(toy:IsTransform());
		transform:SetCallback("OnValueChanged", function(self, event, key)
			local toy = self:GetUserData('toy');
			local cat = ToyBoxR.ToyDB:GetTransform();
			if key == false then
				toy:RemoveCategory(cat);
			else
				toy:AddCategory(cat);
			end
			local toyID = toy:GetID();
			for i,j in pairs(TBR.db.char.Custom) do
				if j[1] == toyID then
					j[2] = key;
				end
			end
		end);
		transform:SetCallback("OnEnter", function(self, event)
			TBR_AddTooltipInfo(self, "Check if this item can transform your character, so it will be used in the 'random transformation' selection.");
			end);
		transform:SetCallback("OnLeave", function () 
			ShowUIPanel(GameTooltip)
			GameTooltip:Hide() 
		end);
		containerpairing:AddChild(transform);
		sf:AddChild(containerpairing);
	end
end

function ToyBoxR:UIConfigTab(container, event, group)
	local scale = AceGUI:Create("Slider");
	scale:SetSliderValues(.5, 1.5, .05);
	scale:SetLabel("Menu Scale");
	scale:SetValue(TBR.db.profile.Scale);
	scale:SetCallback("OnMouseUp", function(self, event, value)
		TBR.db.profile.Scale = value;
	        end);
	scale:SetCallback("OnEnter", function(self, event)
		TBR_AddTooltipInfo(self, "Changes the scale of the ToyBoxR menu.");
	end);
	scale:SetCallback("OnLeave", function () 
		ShowUIPanel(GameTooltip)
		GameTooltip:Hide() 
	end);
	container:AddChild(scale);

	local minimap = AceGUI:Create("CheckBox");
	minimap:SetLabel("Minimap Icon");
	minimap:SetWidth(125);
	minimap:SetValue(not TBR.db.global.minimap.hide);
	minimap:SetCallback("OnValueChanged", function(self, event, val)
		TBR.db.global.minimap.hide = not val;
		ToyBoxR.LDB:ChangeIcon(val);
	end);
	minimap:SetCallback("OnEnter", function(self, event)
		TBR_AddTooltipInfo(self, "Display the Minimap Icon for ToyBoxR.");
	end);
	minimap:SetCallback("OnLeave", function () 
		ShowUIPanel(GameTooltip)
		GameTooltip:Hide() 
	end);
	container:AddChild(minimap);

	local useglobal = AceGUI:Create("CheckBox");
	useglobal:SetLabel("Individual Toy List");
	useglobal:SetValue(not TBR.db.char.UseGlobal);
	useglobal:SetWidth(150);
	useglobal:SetCallback("OnValueChanged", function(self, event, val)
		TBR.db.char.UseGlobal = not val;
		if TBR.db.char.UseGlobal then 
			for i, j in pairs(TBR.db.char.ToyBoxRList) do
				local toy = ToyBoxR.ToyDB:GetToy(i);
				if toy then
					toy.checked = false;
				else
					TBR.db.char.ToyBoxRList[i] = nil;
				end
			end
			TBR.db.char.ToyBoxRList = TBR.TableCopy(TBR.db.global.ToyBoxRList); 
			for i, j in pairs(TBR.db.char.ToyBoxRList) do
				local toy = ToyBoxR.ToyDB:GetToy(i);
				if toy and toy:CanUse() then
					toy.checked = true;
				else
					TBR.db.char.ToyBoxRList[i] = nil;
				end
			end
		end
	end)
	useglobal:SetCallback("OnEnter", function(self, event)
		TBR_AddTooltipInfo(self, "This character has their own toy list, not shared across the account.");
	end);
	useglobal:SetCallback("OnLeave", function () 
		ShowUIPanel(GameTooltip)
		GameTooltip:Hide() 
	end);
	container:AddChild(useglobal);

	local hidenla = AceGUI:Create("CheckBox");
	hidenla:SetLabel("Hide Not Available Toys");
	hidenla:SetValue(TBR.db.global.HideNLA);
	hidenla:SetWidth(185);
	hidenla:SetCallback("OnValueChanged", function(self, event, val)
		TBR.db.global.HideNLA = val;
		ToyBoxR:UpdateToyCnt();
	end)
	hidenla:SetCallback("OnEnter", function(self, event)
		TBR_AddTooltipInfo(self, "Hide all toys no longer available in game, if not owned.");
	end);
	hidenla:SetCallback("OnLeave", function () 
		ShowUIPanel(GameTooltip)
		GameTooltip:Hide() 
	end);
	container:AddChild(hidenla);

	local hidepurchase = AceGUI:Create("CheckBox");
	hidepurchase:SetLabel("Hide Cash Toys");
	hidepurchase:SetValue(TBR.db.global.HidePurchased);
	hidepurchase:SetWidth(155);
	hidepurchase:SetCallback("OnValueChanged", function(self, event, val)
		TBR.db.global.HidePurchased = val;
		ToyBoxR:UpdateToyCnt();
	end)
	hidepurchase:SetCallback("OnEnter", function(self, event)
		TBR_AddTooltipInfo(self, "Hide all toys that can only be purchased outside the game with cash, if not owned.");
	end);
	hidepurchase:SetCallback("OnLeave", function () 
		ShowUIPanel(GameTooltip)
		GameTooltip:Hide() 
	end);
	container:AddChild(hidepurchase);

	local hidefaction = AceGUI:Create("CheckBox");
	hidefaction:SetLabel("Hide Faction Toys");
	hidefaction:SetValue(TBR.db.global.HideFaction);
	hidefaction:SetWidth(155);
	hidefaction:SetCallback("OnValueChanged", function(self, event, val)
		TBR.db.global.HideFaction = val;
		ToyBoxR:UpdateToyCnt();
	end)
	hidefaction:SetCallback("OnEnter", function(self, event)
		TBR_AddTooltipInfo(self, "Hide toys only available to the opposite faction.");
	end);
	hidefaction:SetCallback("OnLeave", function () 
		ShowUIPanel(GameTooltip)
		GameTooltip:Hide() 
	end);
	container:AddChild(hidefaction);
end

function ToyBoxR:UIToyTab(container, event, group)
	local dropdown_lst = {};
	tinsert(dropdown_lst, MENU_ALPHABETIC, "Alphabetic");
	tinsert(dropdown_lst, MENU_CATEGORY, "Category");
	tinsert(dropdown_lst, MENU_EXPANSION, "Expansion");
	tinsert(dropdown_lst, MENU_MISSING, "Missing");
	TBR.grp = AceGUI:Create("Dropdown");
	TBR.grp:SetList(dropdown_lst);
	TBR.grp:SetCallback("OnValueChanged", function(self, event, key)
		TBR.UIMenu = key;
		UISelectTab(TBR.container, nil, "toys");
		end);
	container:AddChild(TBR.grp);

	if TBR.UIMenu ~= MENU_MISSING then
		local missing = AceGUI:Create("CheckBox");
		missing:SetWidth(145);
		missing:SetLabel("Include Missing");
		missing:SetValue(TBR.db.global.ShowMissing);
		missing:SetCallback("OnValueChanged", function(self, event, key)
			if key == false then
				TBR.db.global.ShowMissing = false;
				UISelectTab(TBR.container, nil, "toys");
			else
				TBR.db.global.ShowMissing = true;
				UISelectTab(TBR.container, nil, "toys");
			end
		end);
		missing:SetCallback("OnEnter", function(self, event)
			TBR_AddTooltipInfo(self, "Include missing toys in the lists below.");
		end);
		missing:SetCallback("OnLeave", function () 
			ShowUIPanel(GameTooltip)
			GameTooltip:Hide() 
		end);
		container:AddChild(missing);

		local toggleall = AceGUI:Create("Button");
		toggleall:SetText("Toggle All On/Off");
		toggleall:SetWidth(150);
		toggleall:SetCallback("OnEnter", function(self, event)
			TBR_AddTooltipInfo(self, "Toggle all toys listed below on or off.");
		end);
		toggleall:SetCallback("OnLeave", function () 
			ShowUIPanel(GameTooltip)
			GameTooltip:Hide() 
		end);
		toggleall:SetCallback("OnClick", function(self, event, key) 
			confirmPopup(TBR.frame, "Confirm: Toggle All?", TBR_Confirmed);
			
		end);
		container:AddChild(toggleall);
	end
		
	local scanbags = AceGUI:Create("Button");
	scanbags:SetText("Scan Bags");
	scanbags:SetWidth(130);
	scanbags:SetCallback("OnClick", function(self, event, key) 
		ToyBoxR:Scan();	
	end);
	scanbags:SetCallback("OnEnter", function(self, event)
		local msg = "Scan all open bags for toys, flags those found as owned by this character. Open bank bags to include those too.";
		if DataStore and BankItems_Save ~= nil then
			msg = msg.." BankItems and Altaholic detected, will scan all characters.";
		elseif DataStore then
			msg = msg.." Altaholic detected, will scan all characters."
		elseif BankItems_Save ~= nil then
			msg = msg.." BankItems detected, will scan all characters.";
		end
		TBR_AddTooltipInfo(self, msg);
	end);
	scanbags:SetCallback("OnLeave", function () 
		ShowUIPanel(GameTooltip)
		GameTooltip:Hide() 
	end);
	container:AddChild(scanbags);

	local simplecontainer = AceGUI:Create("SimpleGroup")
	simplecontainer:SetFullWidth(true)
	simplecontainer:SetFullHeight(true) 
	simplecontainer:SetLayout("Fill") 
	container:AddChild(simplecontainer);
	TBR.UIData = simplecontainer;

	if TBR.UIMenu == nil then
		TBR.UIMenu = MENU_CATEGORY;
	end

	TBR.grp:SetValue(TBR.UIMenu); 

	if TBR.UIMenu == MENU_CATEGORY then
		TBR.OnlyMissing = false;
		UISort_ToyBoxR(container);
	elseif TBR.UIMenu == MENU_ALPHABETIC then
		TBR.OnlyMissing = false;
		UISort_Alphebetic(container);
	elseif TBR.UIMenu == MENU_EXPANSION then
		TBR.OnlyMissing = false;
		UISort_Expansion(container);
	elseif TBR.UIMenu == MENU_MISSING then
		TBR.OnlyMissing = true;
		UISort_ToyBoxR(container);
	end

end

function HeightChange(widget, amt)
	TBR.db.global.Height = amt;
end

function WidthChange(widget, amt)
	TBR.db.global.Width = amt;
end

function ToyBoxR:UpdateToyCnt()
	if TBR.frame == nil then return end
	if TBR.KnownOppFacCnt == nil then TBR.KnownOppFacCnt = 0 end
	local text

	if TBR.db.global.HideFaction then
		text = "ToyBoxR - v"..TBR.VERSION.." - "..(#TBR.KnownToys-TBR.KnownOppFacCnt).." Total Toys Known";
	else
		text = "ToyBoxR - v"..TBR.VERSION.." - "..#TBR.KnownToys.." Total Toys Known";
	end
	if #TBR.db.char.Custom > 0 then
		text = text.." ("..#TBR.db.char.Custom.." Custom)";
	end
	TBR.frame:SetStatusText(text);
end

function ToyBoxR:UIOpen()
	if not TBR.frame then 
		ToyBoxR.ToyDB:UpdateCustom();
		TBR.frame = AceGUI:Create("Frame");
		TBR.frame.OnHeightSet = nil
		TBR.frame.OnWidthSet = nil
		TBR.frame:SetTitle("ToyBoxR");
		TBR.frame:SetLayout("Fill");
		ToyBoxR:UpdateToyCnt();

		TBR.frame:SetCallback("OnClose", 
		     function(widget) 
		        TBR.FrameOpen = false;
		     end)

		local tab = AceGUI:Create("TabGroup");
		tab:SetLayout("Flow");
		tab:SetFullWidth(true);
		tab:SetFullHeight(true);
		tab:SetTabs({{text="Toys", value="toys"}, {text="Custom", value="custom"}, {text="Config", value="config"}});

		tab:SetCallback("OnGroupSelected", UISelectTab);

		TBR.frame:AddChild(tab);
		tab:SelectTab("toys");
		if TBR.db.global.Width ~= nil then
			TBR.frame:SetWidth(TBR.db.global.Width);
		end
		if TBR.db.global.Height ~= nil then
			TBR.frame:SetHeight(TBR.db.global.Height);
		end
		TBR.frame.OnHeightSet = HeightChange;
		TBR.frame.OnWidthSet = WidthChange;
		_G["ToyBoxRFrame"] = TBR.frame;
		tinsert(UISpecialFrames, "ToyBoxRFrame");
	end
	TBR.frame:Show();
	TBR.FrameOpen = true;
end

function ToyBoxR:Scan()
	ToyBoxR:Print("Scanning for toys...");

	for x = -1,11 do
		for y = 1, GetContainerNumSlots(x) do
			local id = GetContainerItemID(x,y);
			if id ~= nil then
				local toy = ToyBoxR.ToyDB:GetToy(id);
				if toy ~= nil and not toy:IsCustom() then
					local dup = "";
					if toy:IsOwned() then
						dup = "(Duplicate)";
					end
					ToyBoxR:Print(dup, "Found toy ", toy:GetLink());
				end
			end
		end
	end

	if CanUseVoidStorage() and IsVoidStorageReady() then
		for y = 1, 2 do
			for x = 1, 80 do
				local id = GetVoidItemInfo(y,x);
				if id ~= nil then
					local toy = ToyBoxR.ToyDB:GetToy(id);
					if toy ~= nil and not toy:IsCustom() then
						local dup = "";
						if toy:IsOwned() then
							dup = "(Duplicate)";
						end
						ToyBoxR:Print(dup, "Found toy ", toy:GetLink());
					end
				end
			end
		end
	end

	if BankItems_Save ~= nil then
		ToyBoxR:ScanBankItems()
	end

	if DataStore then
		ToyBoxR:ScanDataStore()
	end

	if TBR.container ~= nil and TBR.container.frame:IsShown() then
		UISelectTab(TBR.container, nil, "toys");
	end
end


local function TBR_DataStore_CheckCharacter(character, name, realm, account)
	local myname = GetUnitName("player", false);
	local myrealm = GetRealmName();

	if myrealm == realm and myname == name then return end
	local itemID, itemLink, itemCount
	local containers = DataStore:GetContainers(character)
	local fullname = name.."-"..realm;

	if containers then
		for containerName, container in pairs(containers) do
			for slotID = 1, container.size do
				itemID = DataStore:GetSlotInfo(container, slotID)
				if itemID then
					local toy = ToyBoxR.ToyDB:GetToy(itemID);
					if toy ~= nil and not toy:IsCustom() and not toy:IsOwned() then
						ToyBoxR:Print("Found toy ", toy:GetLink(), " on ", fullname);
					end
				end
			end
		end
	end
end

function ToyBoxR:ScanDataStore()
	ToyBoxR:Print("DataStore found (Altaholic), scanning all characters for unknown toys...");
	for account in pairs(DataStore:GetAccounts()) do
		for realm in pairs(DataStore:GetRealms(account)) do
			for characterName, character in pairs(DataStore:GetCharacters(realm, account)) do
				TBR_DataStore_CheckCharacter(character, characterName, realm, account);
			end
		end
	end
end

function ToyBoxR:ScanBankItems()
	local myname = GetUnitName("player", false);
	local myrealm = GetRealmName();
	ToyBoxR:Print("BankItems Addon found, scanning all characters for unknown toys...");
	for key, bankPlayer in pairs(BankItems_Save) do
		local name, realm = strsplit("|", key);
		if type(bankPlayer) == "table" and (name ~= myname or realm ~= myrealm) then
			for num = 1, 28 do
				if bankPlayer[num] and type(bankPlayer[num]) == 'table' then
					local fullname = name.."-"..realm;
					local itemID = TBR_ItemFromLink(bankPlayer[num].link);
					if itemID ~= nil then
						itemID = tonumber(itemID);
						local toy = ToyBoxR.ToyDB:GetToy(itemID);
						if toy ~= nil and not toy:IsCustom() and not toy:IsOwned() then
							ToyBoxR:Print("Found toy ", toy:GetLink(), " on ", fullname);
						end
					end
				end
			end
			for x = 0, 12 do
				local num = x;
				if num == 12 then num = 104 end -- Void Storage
				local bag = "Bag"..num;
				if bankPlayer[bag] and type(bankPlayer[bag]) == 'table' then
					for i = 1, bankPlayer[bag].size do
						if bankPlayer[bag][i] ~= nil then
							local fullname = name.."-"..realm;
							local itemID = TBR_ItemFromLink(bankPlayer[bag][i].link);
							if itemID ~= nil then
								itemID = tonumber(itemID);
								local toy = ToyBoxR.ToyDB:GetToy(itemID);
								if toy ~= nil and not toy:IsCustom() and not toy:IsOwned() then
									ToyBoxR:Print("Found toy ", toy:GetLink(), " on ", fullname);
								end
							end
						end
					end
				end
			end
		end
	end
end

function ToyBoxR:TooltipInfo(toy, tooltip)
	local cats = toy:GetCategories();
	local cattext = nil;
	tooltip:AddLine(" ");
	tooltip:AddLine("ToyBoxR:");

	for a, b in pairs(cats) do
		local catname = b:GetName();
		if catname ~= TBR.ALL:GetName() then
			if cattext == nil then
				cattext = "|cFFFFCC00Categories:|r "..catname;
			else
				cattext = cattext..", "..catname;
			end
		end
	end
	tooltip:AddLine(cattext, 1, 1, 1, true);

	local expansion = toy:GetExpansion();
	tooltip:AddLine("|cFFFFCC00Expansion:|r "..expansion, 1, 1, 1, true);

	local location = toy:GetLocation();
	if location ~= nil then
		tooltip:AddLine("|cFFFFCC00Location:|r "..location, 1, 1, 1, true);
	end
end

local function TBR_SortCats(a, b)
	local missing = TBR.MISSING:GetName();
	local general = TBR.GENERAL:GetName();
	if a == missing and b ~= missing then
		return nil;
	elseif b == missing and a ~= missing then
		return 1;
	end

	if a == general and b ~= general then
		return nil;
	elseif b == general and a ~= general then
		return 1;
	end

	if a < b then
		return 1;
	else
		return nil;
	end
end

local function UICreateCheckBox(toy, show_check)
	local box = AceGUI:Create("QCheckBox");

	local r, g, b, hex = GetItemQualityColor(toy:GetQuality());
	box:SetColor(r, g, b);
	box:SetWidth(TEXT_WIDTH);
	box:SetLabel(toy:GetName());
	box:SetImage(toy:GetIcon());
	box:SetImageSize(18,18);
	box:SetUserData('toy', toy);
	box:SetUserData('link', toy:GetLink());
	if show_check then
		box:RemoveCheck(false);
		table.insert(TBR.CheckBoxList, box);
		box:SetCallback("OnValueChanged", function(self, event, key)
			local toy = self:GetUserData('toy');
			if not toy:FactionCheck() then
				self:SetValue(false);
				ToyBoxR:Print(toy:GetLink(), " can't be used by your faction.");
			elseif not toy:LevelCheck() then
				self:SetValue(false);
				ToyBoxR:Print(toy:GetLink(), " can't be used at your level.");
			elseif not toy:RepCheck() then
				self:SetValue(false);
				ToyBoxR:Print(toy:GetLink(), " can't be used at current reputation.");
			elseif not toy:ProfessionCheck() then
				self:SetValue(false);
				ToyBoxR:Print(toy:GetLink(), " can't be used with your profession.");
			else
				toy:UpdateList(key);
			end
		end);
		if not toy:CanUse() then
			box:SetValue(false);
		else
			box:SetValue(toy:GetChecked());
		end
	else
		box:RemoveCheck(true);
	end
	box:SetCallback("OnEnter", function (self, event) 
		inTooltip = true;
		TBR_GameTooltip(self);
	end);
	box:SetCallback("OnLeave", function () ShowUIPanel(GameTooltip)
		inTooltip = false;
		GameTooltip:Hide() end);
	return box;
end

function ToyBoxR:PopulateWindowCategory(parent, filter_category)
	local sf = AceGUI:Create("ScrollFrame");
	sf:SetLayout("Flow");
	local toy;

	parent:AddChild(sf);

	local categories = {};

	TBR.CheckBoxList = {};

	for i,toy in pairs(TBR.KnownToys) do
		local cats = toy:GetCategories();
		local name = toy:GetName();
		if toy:FactionCheck() or not TBR.db.global.HideFaction then
			for a,b in pairs(cats) do
				local catname = b:GetName();
				if TBR.OnlyMissing == false and (catname == filter_category or b:GetParentName() == filter_category) then
					local box = UICreateCheckBox(toy, true);
					if catname == filter_category then catname = TBR.GENERAL:GetName() end
					if categories[catname] == nil then
						local simplecontainer = AceGUI:Create("SimpleGroup") 
						simplecontainer:SetFullWidth(true)
						simplecontainer:SetLayout("Flow") 
						categories[catname] = simplecontainer;
					end
					categories[catname]:AddChild(box);
				end
			end
		end
	end

	if TBR.db.global.ShowMissing or TBR.OnlyMissing == true then
		for i,toy in pairs(TBR.UnknownToys) do
			local cats = toy:GetCategories();
			local name = toy:GetName();
			if (not toy:IsHidden() or not TBR.db.global.HideNLA) and (not toy:CashOnly() or not TBR.db.global.HidePurchased) and (toy:FactionCheck() or not TBR.db.global.HideFaction) then
				for a,b in pairs(cats) do
					if b:GetName() == filter_category or b:GetParentName() == filter_category then
						local catname;
						if TBR.UIMenu ~= MENU_MISSING then
							catname = TBR.MISSING:GetName();
						else
							catname = b:GetName();
							if catname == filter_category then 
								catname = TBR.GENERAL:GetName(); 
							end
						end
						local box = UICreateCheckBox(toy, false);
						if categories[catname] == nil then
							local simplecontainer = AceGUI:Create("SimpleGroup") -- "InlineGroup"
							simplecontainer:SetFullWidth(true)
							simplecontainer:SetLayout("Flow") 
							categories[catname] = simplecontainer;
						end
						categories[catname]:AddChild(box);
					end
				end
			end

		end
	end
	local catsort = {};

	for i, j in pairs(categories) do
		table.insert(catsort, i);
	end

	table.sort(catsort, TBR_SortCats);
	for i, j in pairs(catsort) do
		local header = AceGUI:Create("Heading");
		header:SetFullWidth(true);
		header:SetText(j);
		sf:AddChild(header);
		sf:AddChild(categories[j]);
	end

end

function ToyBoxR:PopulateWindowExpansion(parent, filter_expansion)
	local sf = AceGUI:Create("ScrollFrame");
	sf:SetLayout("Flow");
	local known_cnt = 0;
	local unknown_cnt = 0;
	local known = nil;
	local unknown = nil;
	local toy;

	parent:AddChild(sf);

	TBR.CheckBoxList = {};
	
	for i,toy in pairs(TBR.KnownToys) do
		local name = toy:GetName();
		local expansion = toy:GetExpansion();
		if toy:FactionCheck() or not TBR.db.global.HideFaction then
			if expansion == filter_expansion then
				local box = UICreateCheckBox(toy, true);
				if known_cnt == 0 then
					known = AceGUI:Create("SimpleGroup");
					known:SetFullWidth(true);
					known:SetLayout("Flow"); 
				end
				known_cnt = known_cnt + 1;
				known:AddChild(box);
			end
		end
	end

	if TBR.db.global.ShowMissing then
		for i,toy in pairs(TBR.UnknownToys) do
			if (not toy:IsHidden() or not TBR.db.global.HideNLA) and (not toy:CashOnly() or not TBR.db.global.HidePurchased) and (toy:FactionCheck() or not TBR.db.global.HideFaction) then
				local name = toy:GetName();
				local expansion = toy:GetExpansion();
				if expansion == filter_expansion then
					local box = UICreateCheckBox(toy, false);
					if unknown_cnt == 0 then
						unknown = AceGUI:Create("SimpleGroup");
						unknown:SetFullWidth(true);
						unknown:SetLayout("Flow"); 
					end
					unknown_cnt = unknown_cnt + 1;
					unknown:AddChild(box);
				end
			end
		end
	end

	if known_cnt > 0 then
		local header = AceGUI:Create("Heading");
		header:SetFullWidth(true);
		header:SetText(filter_expansion);
		sf:AddChild(header);
		sf:AddChild(known);
	end
	if unknown_cnt > 0 then
		local header = AceGUI:Create("Heading");
		header:SetFullWidth(true);
		header:SetText(TBR.MISSING:GetName());
		sf:AddChild(header);
		sf:AddChild(unknown);
	end


end

function ToyBoxR:UpdateKnownToys()
	C_ToyBox.SetAllSourceTypeFilters( true );
	C_ToyBox.SetCollectedShown( true );
	C_ToyBox.SetUncollectedShown( true );
	C_ToyBox.SetFilterString("");

	local NumToys = C_ToyBox.GetNumToys();
	-- When zoning, sometimes all the toys are blank. Don't update in that case.
	local zonebug = true;
	for i = NumToys, 1, -1 do
		local idx = C_ToyBox.GetToyFromIndex(i);
		local _, name = C_ToyBox.GetToyInfo(idx);
		if name ~= nil then
			zonebug = false;
		end
	end

	if zonebug == true then return end

	table.wipe(TBR.KnownToys);
	table.wipe(TBR.UnknownToys);

	TBR.db.profile.toylist = nil;
	for i = NumToys, 1, -1 do
		local idx = C_ToyBox.GetToyFromIndex(i);
		local toyID, name, icon, fav = C_ToyBox.GetToyInfo(idx);
		local link = C_ToyBox.GetToyLink(idx);

		if name ~= nil and toyID ~= nil then 
			isOwned = PlayerHasToy(toyID);
			local toy = ToyBoxR.ToyDB:AddToyInfo(name, link, icon, toyID, isOwned);
		elseif name == nil and toyID ~= -1 and toyID ~= nil and TBR.DEBUG_MODE == true then
			ToyBoxR:Print("Item id", toyID, "is unknown");
			--ToyBoxR:Print(TBR.GetUnknownCnt() "unknown toys");
		end
	end
	ToyBoxR.ToyDB:ValidateToys();
	if TBR.ToysShowing == true and TBR.FrameOpen == true then
		UISelectTab(TBR.container, nil, "toys");
	end
	ToyBoxR:UpdateToyCnt();
end

function TBR.TableCopy(tbl, copied)
	copied = copied or {}
	local copy = {};
	copied[tbl] = copy;
	for i, v in pairs(tbl) do
		if type(v) == "table" then
			if copied[v] then
				copy[i] = copied[v];
			else
				copy[i] = TBR.TableCopy(v, copied);
			end
		else
			copy[i] = v;
		end
	end
	return copy;
end
