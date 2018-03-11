local ToyBoxR = LibStub("AceAddon-3.0"):GetAddon("ToyBoxR");

ToyBoxR.ToyDB = ToyBoxR:NewModule("ToyDB");

local Toy = {};
Toy.__index = Toy;

local TBR = ToyBoxR.TBR;

local ToyList = {};

local Category = {}
Category.__index = Category;
local CategoryList = {};

local INSTANCE, HUB, PROFESSION, RARESPAWN, PROMOTION, REPUTATION, QUEST, VENDOR, WORLDEVENT, OTHER, CUSTOM, FACTION, TREASURE, GARRISON, P61
local SCENARIO, ICECROWN, TOT, DUNGEON, FIRELANDS
local ARGENT, BARRENS, MOLTEN
local ARCHY, COOKING, ENGINEERING, FISHING
local PANDARARE, TIMELESS, WODRARE
local TCG, BLIZZCON, STORE
local MOPREP
local BMAH, GOLD 
local DARKMOON, LUNAR, LOVE, CHILDREN, MIDSUMMER, BREWFEST, HALLOW, WINTER, PILGRIM
local ROGUE
local HORDE, ALLIANCE

local TRANSFORM
local TRANSFORM_MOVE, TRANSFORM_IMM, TRANSFORM_MOUNT

local HIDDEN

local UNKNOWN;
local GENERAL;
local ALL;
local MISSING;

local FAC_FRIENDLY =5;
local FAC_HONORED =6;
local FAC_REVERED =7;
local FAC_EXALTED =8;

local FAC_ORDER_OF_THE_CLOUD_SERPENT = 1271;
local FAC_TILLERS = 1271;
local FAC_KIRIN_TOR_OFFENSIVE = 1387;
local FAC_SUNREAVER_ONSLAUGHT = 1388;
local FAC_FROSTWOLF_ORCS = 1445;
local FAC_SHATARI_DEFENSE = 1710;
local FAC_TIMBERMAW_HOLD = 576;
local FAC_LAUGHING_SKULL_ORCS = 1708;
local FAC_BARADINS_WARDENS = 1177;
local FAC_HELLSCREAMS_REACH = 1178;

local PROF_ENGINEER = 202;
local PROF_ENGINEER_GNOMISH = 0
local PROF_ENGINEER_GOBLIN = 1

local UNKNOWN_EXP, CLASSIC, BC, WRATH, CATA, MOP, WOD, BL, BFA = 1, 2, 3, 4, 5, 6, 7, 8, 9;
local ExpansionList = { "Unknown",
			"Classic WoW",
			"Burning Crusade",
			"Wrath",
			"Cataclysm",
			"Mists of Pandaria",
			"Warlords",
			"Burning Legion",
			"Battle"
			};

local Custom_List = {};

local function CreateToy(toyID, xpac, ...)
	local toy = Toy:new();
	toy.toyID = toyID;
	toy.categorylist = {};
	local isCustom = false;
	
	if type(xpac) ~= 'number' then
--		print("Toy "..toyID.." has no expansion set.");
		table.insert(toy.categorylist, 1, xpac);
		toy.expansion = UNKNOWN_EXP;
	else
		toy.expansion = xpac;
	end
	for i = 1, select("#", ...) do
		local part = select(i, ...);
--		if part == nil then
--			print("Unknown type for toyinfo id "..toyID);
--		end
		table.insert(toy.categorylist, 1, part);
		if part == CUSTOM then
			isCustom = true;
		end
		if part == HIDDEN then
			toy.hidden = true;
		end
		if part == ALLIANCE then
			toy.alliance = true;
		end
		if part == HORDE then
			toy.horde = true;
		end
	end
	table.insert(toy.categorylist, 1, ALL);
	ToyList[toyID] = toy;
	if TBR.db.char.ToyBoxRList[toyID] == 1 then 
		toy.checked = true;
	else
		toy.checked = false;
	end

	if isCustom == true then
		local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(toyID);
		table.insert(Custom_List, toy);
	end
	return toy;
end

function ToyBoxR.ToyDB:CreateToy(toyID, xpac, ...)
	local toy = CreateToy(toyID, xpac, ...);
	return toy;
end

function ToyBoxR.ToyDB:GetToy(id)
	return ToyList[id];
end

function ToyBoxR.ToyDB:UpdateCustom()
	for i,j in pairs(Custom_List) do
		j:GetName();
	end
end

function ToyBoxR.ToyDB:ValidateToys()
	for i, j in pairs(ToyList) do
		if j.name == nil then 
			local cats = j:GetCategories();
			local hidden = false;
			for i,j in pairs(cats) do
				if j == HIDDEN then
					hidden = true;
				end
			end
--			if hidden == false then
--				print("Toy is not in the box: "..i);
--			end
		end
	end
end

local function ToySort(a, b)
	local aname = a:GetName();
	local bname = b:GetName();

	if aname > bname then
		return nil;
	elseif aname < bname then
		return 1;
	end
end

function Toy:Delete()
	local is_known = tContains(TBR.KnownToys, self);
	local is_unknown = tContains(TBR.UnknownToys, self);

	if is_known then
		for i,j in pairs(TBR.KnownToys) do
			if j == self then
				table.remove(TBR.KnownToys, i);
			end
		end
		table.sort(TBR.KnownToys, ToySort);
	end

	if is_unknown then
		for i,j in pairs(TBR.UnknownToys) do
			if j == self then
				table.remove(TBR.UnknownToys, i);
			end
		end
		table.sort(TBR.UnknownToys, ToySort);
	end
	ToyList[self.toyID] = nil;
end

function Toy:IsHidden()
	return self.hidden;
end

function Toy:CashOnly()
	local cash = true;
	for i, cat in pairs(self.categorylist) do
		if cat ~= ALL and cat ~= TCG and cat ~= STORE and cat ~= TRANSFORM and cat.parent ~= TRANSFORM then
			cash = false;
		end
	end
	return cash;
end

function Toy:AddCategory(cat)
	local is_known = tContains(TBR.KnownToys, self);

	table.insert(self.categorylist, 1, cat);
	if cat == HIDDEN then
		self.hidden = true;
	end
	if cat == ALLIANCE then
		self.alliance = true;
	end
	if cat == HORDE then
		self.horde = true;
	end
end

function Toy:CanUse()
	if self:LevelCheck() and self:RepCheck() and self:FactionCheck() and self:ProfessionCheck() then
		return true
	else
		return false;
	end
end

function Toy:ProfessionCheck()
	if self.profession == nil then return true end

	local prof1, prof2 = GetProfessions();
	if prof1 ~= nil then
		local _, _, skillLevel, _, _, _, skillLine, _, specializationIndex = GetProfessionInfo(prof1);
		if skillLine == self.profession then
			if (self.prof_spec == nil or self.prof_spec == specializationIndex) and skillLevel >= self.prof_val then
				return true;
			end
		end
	end
	if prof2 ~= nil then
		local _, _, skillLevel, _, _, _, skillLine, _, specializationIndex = GetProfessionInfo(prof2);
		if skillLine == self.profession then
			if (self.prof_spec == nil or self.prof_spec == specializationIndex) and skillLevel >= self.prof_val then
				return true;
			end
		end
	end
	return false;
end
		
function Toy:RepCheck()
	if self.reputation == nil then return true end

	local name, _, standing = GetFactionInfoByID(self.reputation);
	if name == nil then return false end

	if standing >= self.repval then 
		return true
	else
		return false
	end
end

function Toy:LevelCheck()
	if self.level == nil then return true end
	local playerlvl = UnitLevel("player");
	if playerlvl >= self.level then 
		return true;
	else
		return false;
	end
end

function Toy:FactionCheck()
	if not self.alliance and not self.horde then
		return true;
	end
	if self.alliance and TBR.faction == "Alliance" then
		return true;
	end
	if self.horde and TBR.faction == "Horde" then
		return true;
	end
	return false;
end

function Toy:RemoveCategory(cat)
	local is_known = tContains(TBR.KnownToys, self);

	if cat == ALLIANCE then
		self.alliance = nil;
	end
	if cat == HORDE then
		self.horde = nil;
	end
	for i,j in pairs(self.categorylist) do
		if j == cat then
			table.remove(self.categorylist, i);
		end
	end
end

function Toy:UpdateOwned(isOwned)
	local is_known = tContains(TBR.KnownToys, self);
	local is_unknown = tContains(TBR.UnknownToys, self);

	if is_known and isOwned then return end
	if is_unknown and not isOwned then return end

	self.isOwned = isOwned;

	if isOwned then
		table.insert(TBR.KnownToys, 1, self);
		table.sort(TBR.KnownToys, ToySort);

		if is_unknown then
			for i, j in pairs(TBR.UnknownToys) do
				if j == self then 
					table.remove(TBR.UnknownToys, i);
				end
			end
			table.sort(TBR.UnknownToys, ToySort);
		end
	else
		table.insert(TBR.UnknownToys, 1, self);
		table.sort(TBR.UnknownToys, ToySort);
		if is_known then
			for i, j in pairs(TBR.KnownToys) do
				if j == self then 
					table.remove(TBR.KnownToys, i);
				end
			end
			table.sort(TBR.KnownToys, ToySort);
		end
		self:UpdateList(false)
	end
end

function ToyBoxR.ToyDB:AddToyInfo(name, link, icon, toyID, isOwned)
	local toy = ToyBoxR.ToyDB:GetToy(toyID);
	if toy == nil then
		toy = CreateToy(toyID, UNKNOWN_EXP);
	end
	toy.name = name;
	toy.icon = icon;
	toy.link = link;
	local _, _, quality, _, minlevel = GetItemInfo(toyID);
	toy.quality = quality;
	if minlevel > 1 then
		toy.level = minlevel;
	end

	toy:UpdateOwned(isOwned);

	return toy;
end

function Toy:IsOwned()
	return self.isOwned;
end

function Toy:GetQuality()
	return self.quality;
end

function Toy:SetReputation(rep, val)
	self.reputation = rep;
	self.repval = val;
end

function Toy:SetLocation(location)
	self.location = location;
end
function Toy:SetProfession(profession, spec, val)
	self.profession = profession;
	self.prof_spec = spec;
	self.prof_val = val;
end

function Toy:GetLocation(location)
	return self.location;
end

function Toy:GetExpansion()
	return ExpansionList[self.expansion];
end

function Toy:GetCategories()
	return self.categorylist;
end

function ToyBoxR.ToyDB:GetCategoryList()
	return CategoryList;
end

function ToyBoxR.ToyDB:GetExpansionList()
	return ExpansionList;
end

function ToyBoxR.ToyDB:GetUnknown()
	return UNKNOWN;
end

function ToyBoxR.ToyDB:GetAll()
	return ALL;
end

function ToyBoxR.ToyDB:GetCustom()
	return CUSTOM;
end

function ToyBoxR.ToyDB:GetTransform()
	return TRANSFORM_MOVE;
end

function Toy:new()
	local self = {};
	setmetatable(self, Toy);
	return self;
end

function Toy:GetID()
	return self.toyID;
end

function Toy:GetName()
	if self.name == nil then
		local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(self.toyID);
		if itemName == nil then
			ToyBoxR:Print("Item id", self.toyID, "did not load."); 
			return nil;
		end
		local isOwned = false;
		if self:IsCustom() then
			isOwned = true
		end
		ToyBoxR.ToyDB:AddToyInfo(itemName, itemLink, itemTexture, self.toyID, isOwned);
	end
	return self.name;
end

function Toy:GetIcon()
	return self.icon;
end

function Toy:GetToyID()
	return self.toyID;
end

function Toy:GetLink()
	return self.link;
end

function Toy:UpdateList(val)
	if val == true and TBR.db.char.ToyBoxRList[self.toyID] == nil then
		TBR.db.char.ToyBoxRList[self.toyID] = 1;
		if TBR.db.char.UseGlobal then
			TBR.db.global.ToyBoxRList[self.toyID] = 1;
		end
	elseif val == false and TBR.db.char.ToyBoxRList[self.toyID] == 1 then
		TBR.db.char.ToyBoxRList[self.toyID] = nil;
		if TBR.db.char.UseGlobal then
			TBR.db.global.ToyBoxRList[self.toyID] = nil;
		end
	end
	self.checked = val;
end

function Toy:GetChecked()
	return self.checked;
end

function Toy:IsTransform()
	local cats = self.categorylist;
	for a,b in pairs(cats) do
		if b == TRANSFORM_MOVE then
			return true;
		end
	end
	return false;
end

function Toy:IsCustom()
	local cats = self.categorylist;
	for a,b in pairs(cats) do
		if b == CUSTOM then
			return true;
		end
	end
	return false;
end

local function CategorySort(a, b)
	local aname = a:GetName();
	local bname = b:GetName();

	if a == ALL and b ~= ALL then
		return nil;
	elseif b == ALL and a ~= ALL then
		return 1;
	end
	if aname < bname then
		return nil;
	elseif aname > bname then
		return 1;
	end
end

local function NewCategory(name)
	local cat = Category:new(name);
	cat.sublist = {};
	table.insert(CategoryList, 1, cat);
	table.sort(CategoryList, CategorySort);
	return cat;
end

local function CategoryInit()
	TRANSFORM 	= NewCategory("Transformation");
	TRANSFORM_MOVE	= TRANSFORM:AddSubCategory("Transformation (Can Move)");
	TRANSFORM_IMM	= TRANSFORM:AddSubCategory("Transformation (Can Not Move)");
	TRANSFORM_MOUNT	= TRANSFORM:AddSubCategory("Transformation (Can Mount)");
	HIDDEN		= NewCategory("Not Available");

	INSTANCE	= NewCategory("Dungeons / Raids");
	SCENARIO	= INSTANCE:AddSubCategory("Scenarios");
	ICECROWN	= INSTANCE:AddSubCategory("Icecrown Citadel");
	FIRELANDS	= INSTANCE:AddSubCategory("Firelands");
	TOT		= INSTANCE:AddSubCategory("Throne of Thunder");
	DUNGEON		= INSTANCE:AddSubCategory("Dungeons");

	HUB		= NewCategory("Outdoor Hubs");
	ARGENT		= HUB:AddSubCategory("Argent Tourney");
	BARRENS		= HUB:AddSubCategory("Battlefield Barrens");
	MOLTEN		= HUB:AddSubCategory("Molten Front");

	PROFESSION	= NewCategory("Professions");
	ARCHY		= PROFESSION:AddSubCategory("Archaeology");
	COOKING		= PROFESSION:AddSubCategory("Cooking");
	ENGINEERING	= PROFESSION:AddSubCategory("Engineering");
	FISHING		= PROFESSION:AddSubCategory("Fishing");

	RARESPAWN	= NewCategory("Rare Spawns");
	PANDARARE	= RARESPAWN:AddSubCategory("Pandaria Rares");
	WODRARE		= RARESPAWN:AddSubCategory("WoD Rares");
	TIMELESS	= RARESPAWN:AddSubCategory("Timeless Isle Rares");

	PROMOTION	= NewCategory("Promotions");
	TCG		= PROMOTION:AddSubCategory("Trading Card Game");
	BLIZZCON	= PROMOTION:AddSubCategory("Blizzcon");
	STORE		= PROMOTION:AddSubCategory("Blizzard Store");

	REPUTATION	= NewCategory("Reputation");
	MOPREP		= REPUTATION:AddSubCategory("Mists of Pandaria Reputation");

	QUEST		= NewCategory("Questing");

	VENDOR		= NewCategory("Vendor");
	BMAH		= VENDOR:AddSubCategory("Black Market Auction House");
	GOLD		= VENDOR:AddSubCategory("Gold");

	WORLDEVENT	= NewCategory("Holiday Events");
	DARKMOON	= WORLDEVENT:AddSubCategory("Darkmoon Faire");
	LUNAR		= WORLDEVENT:AddSubCategory("Lunar Festival");
	LOVE		= WORLDEVENT:AddSubCategory("Love is in the Air");
	CHILDREN	= WORLDEVENT:AddSubCategory("Children's Week");
	MIDSUMMER	= WORLDEVENT:AddSubCategory("Midsummer Fire Festival");
	BREWFEST	= WORLDEVENT:AddSubCategory("Brewfest");
	HALLOW		= WORLDEVENT:AddSubCategory("Hallow's End");
	WINTER		= WORLDEVENT:AddSubCategory("Feast of Winter Veil");
	PILGRIM		= WORLDEVENT:AddSubCategory("Pilgrim's Bounty");

	OTHER		= NewCategory("Other");
	ROGUE		= OTHER:AddSubCategory("Rogues");
	UNKNOWN		= OTHER:AddSubCategory("Unknown");

	FACTION		= NewCategory("Faction");
	ALLIANCE	= FACTION:AddSubCategory("Alliance");
	HORDE		= FACTION:AddSubCategory("Horde");

	TREASURE	= NewCategory("Treasure");

	GARRISON	= NewCategory("Garrison");

	P61		= NewCategory("Patch 6.1");

	GENERAL 	= NewCategory("General");
	ALL 		= NewCategory("All");
	MISSING 	= NewCategory("Missing");
	
	CUSTOM          = NewCategory("Custom");

	TBR.ALL = ALL;
	TBR.UNKNOWN = UNKNOWN;
	TBR.GENERAL = GENERAL;
	TBR.MISSING = MISSING;
	TBR.TRANSFORM_MOVE = TRANSFORM_MOVE;
	TBR.TRANSFORM_MOUNT = TRANSFORM_MOUNT;
end

local function ToyInit()
	CreateToy(86589,  MOP, TRANSFORM_MOUNT, PANDARARE); -- Ai-Li's Skymirror
	CreateToy(119217, WOD, UNKNOWN, ALLIANCE); -- Alliance Flag of Viictory
	CreateToy(69776,  CLASSIC, TRANSFORM_IMM, ARCHY); -- Ancient Amber
	CreateToy(113570, WOD, TRANSFORM_IMM, WODRARE); -- Ancient's Bloom
	CreateToy(117550, WOD, TREASURE); -- Angry Beehive
	CreateToy(118191, WOD, GARRISON); -- Archmage Vargoth's Spare Staff
	CreateToy(46843,  WRATH, ARGENT); -- Argent Crusader's Banner
	CreateToy(64456,  BC, ARCHY); -- Arrival of the Naaru
	CreateToy(104329, MOP, TIMELESS); -- Ash-Covered Horn
	CreateToy(118427, WOD, GARRISON); -- Autographed Hearthstone Card
	CreateToy(90067,  MOP, PANDARARE); -- B. F. F. Necklace
	CreateToy(86565,  MOP, PANDARARE); -- Battle Horn
	CreateToy(97921,  MOP, BARRENS, HIDDEN); -- Bom'bay's Color-Seein' Sauce
	CreateToy(119178, WOD, WODRARE); -- Black Whirlwind
	CreateToy(104302, MOP, TIMELESS); -- Blackflame Daggers
	CreateToy(115503, WOD, QUEST); -- Blazing Diamond Pendant
	CreateToy(116115, MOP, DARKMOON); -- Blazing Wings
	CreateToy(64481,  WRATH, ARCHY, TRANSFORM_MOVE); -- Blessing of the Old God
	CreateToy(113096, WOD, TRANSFORM_MOVE, VENDOR, GARRISON); -- Bloodmane Charm
	CreateToy(54343,  CLASSIC, GOLD); -- Blue Crashin' Thrashin' Racer Controller
	CreateToy(64646,  WRATH, TRANSFORM_MOVE, ARCHY); -- Bones of Transformation
	CreateToy(119432, WOD, WODRARE, TRANSFORM_IMM); -- Botani Camouglage
	CreateToy(34686,  CLASSIC, MIDSUMMER); -- Brazier of Dancing Flames
	CreateToy(71137,  CLASSIC, BREWFEST); -- Brewfest Keg Pony
	CreateToy(33927,  CLASSIC, BREWFEST); -- Brewfest Pony Keg
	CreateToy(116122, WOD, WODRARE); -- Burning Legion Missive
	CreateToy(103685, MOP, MOPREP, TRANSFORM_MOUNT); -- Celestial Defender's Medallion
	CreateToy(102467, MOP, VENDOR); -- Censer of Eternal Agony
	CreateToy(86575,  MOP, PANDARARE); -- Chalice of Secrets
	CreateToy(64373,  CLASSIC, ARCHY); -- Chalice of the Mountain Kings
	CreateToy(89222,  MOP, MOPREP); -- Cloud Ring
	CreateToy(104318, CLASSIC, WINTER); -- Crashin' Thrashin' Flyer Controller
	CreateToy(37710,  CLASSIC, WINTER); -- Crashin' Thrashin' Racer Controller
	CreateToy(23767,  BC, ENGINEERING); -- Crashin' Thrashin' Robot
	CreateToy(88589,  MOP, QUEST); -- Cremating Torch
	CreateToy(38301,  CLASSIC, TCG); -- D.I.S.C.O.
	CreateToy(90899,  CLASSIC, DARKMOON); -- Darkmoon Whistle
	CreateToy(54653,  WRATH, TRANSFORM_MOUNT, WORLDEVENT, HIDDEN, HORDE); -- Darkspear Pride
	CreateToy(45021,  WRATH, ARGENT, REPUTATION, ALLIANCE); -- Darnassus Banner
	CreateToy(36863,  WRATH, ROGUE); -- Decahedral Dwarven Dice
	CreateToy(108743, WOD, TREASURE); -- Deceptia's Smoldering Boots
	CreateToy(79769,  CLASSIC, TCG, TRANSFORM_MOVE); -- Demon Hunter's Aspect
	CreateToy(64361,  CLASSIC, ARCHY); -- Druid and Priest Statue Set
	CreateToy(21540,  CLASSIC, LUNAR); -- Elune's Lantern
	CreateToy(86590,  MOP, PANDARARE); -- Essence of the Breeze
	CreateToy(104309, MOP, TIMELESS); -- Eternal Kiln
	CreateToy(89999,  CATA, SCENARIO, ALLIANCE, HIDDEN); -- Everlasting Alliance Firework
	CreateToy(90000,  CATA, SCENARIO, HORDE, HIDDEN); -- Everlasting Horde Firework
	CreateToy(45020,  WRATH, ARGENT, REPUTATION, ALLIANCE); -- Exodar Banner
	CreateToy(53057,  CLASSIC, QUEST, HORDE); -- Faded Wizard Hat
	CreateToy(86581,  MOP, PANDARARE); -- Farwater Conch
	CreateToy(119145, WOD, QUEST, HORDE); -- Firefury Totem
	CreateToy(33223,  CLASSIC, TCG, BMAH); -- Fishing Chair
	CreateToy(75042,  CLASSIC, DARKMOON); -- Flimsy Yellow Balloon
	CreateToy(88801,  MOP, COOKING); -- Flippable Table
	CreateToy(45063,  CLASSIC, TCG, BMAH); -- Foam Sword Rack
	CreateToy(69227,  CLASSIC, TCG); -- Fool's Gold
	CreateToy(104324, CLASSIC, GOLD); -- Foot Ball
	CreateToy(90888,  CLASSIC, WINTER); -- Foot Ball
	CreateToy(88802,  MOP, GOLD); -- Foxicopter Controller
	CreateToy(44719,  WRATH, TRANSFORM_MOVE, REPUTATION); -- Frenzyheart Brew
	CreateToy(98136,  MOP, TOT); -- Gastropod Shell
	CreateToy(117569, WOD, TREASURE); -- Giant Deathweb Egg
	CreateToy(90175,  MOP, MOPREP); -- Gin-Ji Knife Set
	CreateToy(95589,  MOP, MOPREP, ALLIANCE); -- Glorious Standard of the Kirin Tor Offensive
	CreateToy(95590,  MOP, MOPREP, HORDE); -- Glorious Standard of the Sunreaver Onslaught
	CreateToy(45019,  WRATH, ARGENT, REPUTATION, ALLIANCE); -- Gnomeregan Banner
	CreateToy(54651,  WRATH, HIDDEN, TRANSFORM_MOUNT, WORLDEVENT, ALLIANCE); -- Gnomeregan Pride
	CreateToy(40895,  WRATH, ENGINEERING); -- Gnomish X-Ray Specs
	CreateToy(33219,  CLASSIC, TCG, BMAH); -- Goblin Gumbo Kettle
	CreateToy(35227,  CLASSIC, BMAH, TCG); -- Goblin Weather Machine - Prototype 01-B
	CreateToy(88417,  MOP, QUEST, TRANSFORM_IMM); -- Gokk'lok's Shell
	CreateToy(119180, WOD, WOD); -- Goren "Log" Roller
	CreateToy(69895,  CLASSIC, CHILDREN); -- Green Balloon
	CreateToy(67097,  CLASSIC, TCG); -- Grim Campfire
	CreateToy(86584,  MOP, PANDARARE); -- Hardened Shell
	CreateToy(69777,  CLASSIC, ARCHY); -- Haunted War Drum
	CreateToy(116139, MOP, DARKMOON); -- Haunting Memento
	CreateToy(64358,  CLASSIC, ARCHY); -- Highborne Soul Mirror
	CreateToy(87528,  MOP, SCENARIO); -- Honorary Brewmaster Keg
	CreateToy(119218, WOD, UNKNOWN, HORDE); -- Horde Flag of Victory
	CreateToy(86593,  MOP, PANDARARE, TRANSFORM_MOUNT); -- Hozen Beach Ball
	CreateToy(88385,  MOP, QUEST); -- Hozen Idol
	CreateToy(32542,  CLASSIC, TCG, BMAH); -- Imp in a Ball
	CreateToy(54212,  CLASSIC, TCG); -- Instant Statue Pedestal
	CreateToy(43499,  WRATH, TRANSFORM_MOVE, GOLD); -- Iron Boot Flask
	CreateToy(118244, WOD, WODRARE, TRANSFORM_MOUNT); -- Iron Buccaneer's Hat
	CreateToy(45018,  WRATH, ARGENT, REPUTATION, ALLIANCE); -- Ironforge Banner
	CreateToy(88579,  MOP, QUEST); -- Jin Warmkeg's Brew
	CreateToy(64383,  CLASSIC, ARCHY); -- Kaldorei Wind Chimes
	CreateToy(68806,  CLASSIC, GOLD, TRANSFORM_MOUNT); -- Kalytha's Haunted Locket
	CreateToy(86571,  MOP, PANDARARE); -- Kang's Bindstone
	CreateToy(88580,  MOP, QUEST); -- Ken-Ken's Mask
	CreateToy(116125, WOD, WODRARE, TRANSFORM_IMM); -- Klikixx's Webspinner
	CreateToy(88566,  MOP, TRANSFORM_MOUNT, DUNGEON); -- Krastinov's Bag of Horrors
	CreateToy(88531,  MOP, QUEST); -- Lao Chin's Last Mug
	CreateToy(71259,  CATA, MOLTEN, TRANSFORM_MOUNT); -- Leyara's Locket
	CreateToy(70722,  CLASSIC, HALLOW); -- Little Wickerman
	CreateToy(63269,  CATA, ROGUE); -- Loaded Gnomish Dice
	CreateToy(86591,  MOP, PANDARARE); -- Magic Banana
	CreateToy(72159,  CLASSIC, TCG, TRANSFORM_MOVE); -- Magical Ogre Idol
	CreateToy(89205,  CATA, SCENARIO, HIDDEN, HORDE); -- Mini Mana Bomb
	CreateToy(46709,  CLASSIC, WINTER); -- MiniZep Controller
	CreateToy(101571, MOP, DARKMOON, TRANSFORM_MOUNT); -- Moonfang Shroud
	CreateToy(105898, MOP, TRANSFORM_MOVE, DARKMOON); -- Moonfang's Paw
	CreateToy(86568,  MOP, PANDARARE, TRANSFORM_MOUNT); -- Mr. Smite's Brass Compass
	CreateToy(52201,  WRATH, TRANSFORM_MOUNT, ICECROWN); -- Muradin's Favor
	CreateToy(33079,  CLASSIC, BLIZZCON, TRANSFORM_MOVE, HIDDEN); -- Murloc Costume
	CreateToy(70161,  CATA, MOLTEN); -- Mushroom Chair
	CreateToy(70159,  CATA, MOLTEN, GOLD); -- Mylune's Call
	CreateToy(86596,  MOP, MOPREP); -- Nat's Fishing Chair
	CreateToy(112324, MOP, STORE); -- Nightmarish Hitching Post
	CreateToy(104262, MOP, TIMELESS); -- Odd Polished Stone
	CreateToy(46780,  CLASSIC, TCG, BMAH); -- Ogre Pinata
	CreateToy(1973,   CLASSIC, OTHER, TRANSFORM_MOUNT); -- Orb of Deception
	CreateToy(35275,  BC, TRANSFORM_MOUNT, DUNGEON); -- Orb of the Sin'dorei
	CreateToy(45014,  WRATH, ARGENT, REPUTATION, HORDE); -- Orgrimmar Banner
	CreateToy(90427,  CLASSIC, BREWFEST); -- Pandaren Brewpack
	CreateToy(86588,  MOP, PANDARARE); -- Pandaren Firework Launcher
	CreateToy(89869,  MOP, MOPREP); -- Pandaren Scarecrow
	CreateToy(86586,  MOP, PANDARARE); -- Panflute of Pandaria
	CreateToy(34499,  CLASSIC, TCG, BMAH); -- Paper Flying Machine Kit
	CreateToy(64881,  CATA, ARCHY); -- Pendant of the Scarab Storm
	CreateToy(115468, WOD, VENDOR, HORDE, REPUTATION); -- Permanent Frost Essence
	CreateToy(49703,  CLASSIC, TCG); -- Perpetual Purple Firework
	CreateToy(118221, WOD, WODRARE); -- Petrification Stone
	CreateToy(32566,  CLASSIC, BMAH, TCG); -- Picnic Basket
	CreateToy(30690,  BC, QUEST); -- Power Converter
	CreateToy(108739, WOD, TREASURE); -- Pretty Draenor Pearl
	CreateToy(88370,  MOP, QUEST); -- Puntable Marmot
	CreateToy(64482,  WRATH, ARCHY); -- Puzzle Box of Yogg-Saron
	CreateToy(95566,  MOP, PANDARARE); -- Ra'sha's Sacrificial Dagger
	CreateToy(104294, MOP, TRANSFORM_MOUNT, TIMELESS); -- Rime of the Time-Lost Mariner
	CreateToy(116067, WOD, DARKMOON, QUEST, TRANSFORM_MOVE); -- Ring of Broken Promises
	CreateToy(119215, WOD, OTHER, TRANSFORM_MOVE); -- Robo-Gnomebulator
	CreateToy(86577,  MOP, PANDARARE); -- Rod of Ambershaping
	CreateToy(34480,  CLASSIC, LOVE); -- Romantic Picnic Basket
	CreateToy(71628,  CLASSIC, TCG); -- Sack of Starfish
	CreateToy(45015,  WRATH, ARGENT, REPUTATION, HORDE); -- Sen'jin Banner
	CreateToy(97942,  MOP, HIDDEN, BARRENS); -- Sen'jin Spirit Drum
	CreateToy(98132,  MOP, TOT); -- Shado-Pan Geyser Gun
	CreateToy(86573,  MOP, TRANSFORM_IMM, PANDARARE); -- Shard of Archstone
	CreateToy(119421, WOD, UNKNOWN, TRANSFORM_MOUNT, REPUTATION); -- Sha'tari Defender's Medallion
	CreateToy(88387,  MOP, QUEST); -- Shushen's Spittoon
	CreateToy(45017,  WRATH, ARGENT, REPUTATION, HORDE); -- Silvermoon City Banner
	CreateToy(88381,  MOP, QUEST); -- Silversage Incense
	CreateToy(17716,  CLASSIC, ENGINEERING, WINTER); -- Snowmaster 9000
	CreateToy(119182, WOD, VENDOR, REPUTATION); -- Soul Evacuation Crystal
	CreateToy(72161,  CLASSIC, TCG); -- Spurious Sarcophagus
	CreateToy(91904,  MOP, GOLD); -- Stackable Stag
	CreateToy(109739, WOD, TREASURE); -- Star Chart
	CreateToy(66888,  CLASSIC, REPUTATION, TRANSFORM_MOVE); -- Stave of Fur and Claw
	CreateToy(111476, WOD, WODRARE); -- Stolen Breath
	CreateToy(45011,  WRATH, ARGENT, REPUTATION, ALLIANCE); -- Stormwind Banner
	CreateToy(37254,  WRATH, TRANSFORM_MOVE, OTHER); -- Super Simian Sphere (Northrend drop)
	CreateToy(94154,  CLASSIC, ROGUE); -- Survivor's Bag of Coins
	CreateToy(52253,  WRATH, ICECROWN); -- Sylvanas' Music Box
	CreateToy(38578,  CLASSIC, TCG, BMAH); -- The Flag of Ownership
	CreateToy(80822,  MOP, QUEST); -- The Golden Banana
	CreateToy(50471,  CLASSIC, LOVE); -- The Heartbreaker
	CreateToy(104323, CLASSIC, GOLD); -- The Pigskin
	CreateToy(90883,  CLASSIC, WINTER); -- The Pigskin
	CreateToy(45013,  WRATH, ARGENT, REPUTATION, HORDE); -- Thunder Bluff Banner
	CreateToy(119160, WOD, VENDOR, REPUTATION); -- Tickle Totem
	CreateToy(32782,  BC, TRANSFORM_MOVE, OTHER); -- Time-Lost Figurine
	CreateToy(54438,  CLASSIC, GOLD); -- Tiny Blue Ragdoll
	CreateToy(54437,  CLASSIC, GOLD); -- Tiny Green Ragdoll
	CreateToy(44430,  WRATH, FISHING); -- Titanium Seal of Dalaran
	CreateToy(64997,  CATA, REPUTATION, HORDE); -- Tol Barad Searchlight
	CreateToy(63141,  CATA, REPUTATION, ALLIANCE); -- Tol Barad Searchlight
	CreateToy(88584,  MOP, QUEST); -- Totem of Harmony
	CreateToy(119144, WOD, QUEST, ALLIANCE); -- Touch of the Naaru
	CreateToy(44606,  CLASSIC, GOLD); -- Toy Train Set
	CreateToy(115506, WOD, WOD, TRANSFORM_IMM); -- Treessassin's Guise
	CreateToy(88377,  MOP, QUEST); -- Turnip Paint "Gun"
	CreateToy(45016,  WRATH, ARGENT, REPUTATION, HORDE); -- Undercity Banner
	CreateToy(45984,  WRATH, FISHING); -- Unusual Compass
	CreateToy(69775,  WRATH, TRANSFORM_MOUNT, ARCHY); -- Vrykul Drinking Horn
	CreateToy(69215,  CLASSIC, TCG); -- War Party Hitching Post
	CreateToy(119219, WOD, GARRISON); -- Warlords Flag of Victory
	CreateToy(104331, MOP, TIMELESS); -- Warning Sign
	CreateToy(117573, WOD, GARRISON); -- Wayfarer's Bonfire
	CreateToy(97919,  MOP, TRANSFORM_MOVE, BARRENS, HIDDEN); -- Whole-Body Shrinka'
	CreateToy(45057,  CLASSIC, GOLD); -- Wind-Up Train Wrecker
	CreateToy(17712,  CLASSIC, WINTER, TRANSFORM_IMM); -- Winter Veil Disguise Kit
	CreateToy(64651,  CLASSIC, ARCHY, TRANSFORM_MOVE); -- Wisp Amulet
	CreateToy(18660,  CLASSIC, ENGINEERING); -- World Enlarger
	CreateToy(109183, WOD, ENGINEERING, TRANSFORM_MOUNT); -- World Shrinker
	CreateToy(36862,  WRATH, ROGUE); -- Worn Troll Dice
	CreateToy(98552,  MOP, BARRENS, HIDDEN); -- Xan'tish's Flute

	-- Latest Beta Patch Additions
	CreateToy(116757, WOD, BREWFEST); -- Steamworks Sausage Grill
	CreateToy(118222, WOD, WODRARE); -- Spirit of Bashiok
	CreateToy(116400, WOD, PILGRIM); -- Silver-Plated Turkey Shooter
	CreateToy(116690, WOD, WINTER); -- Safari Lounge Cushion
	CreateToy(116689, WOD, WINTER); -- Pinapple Lounge Cushion
	CreateToy(120276, WOD, WODRARE, TRANSFORM_MOUNT); -- Outrider's Bridle Chain
	CreateToy(113670, WOD, WODRARE); -- Mournful Moan of Murmur
	CreateToy(118938, WOD, GARRISON, TRANSFORM_MOUNT); -- Manastorm's Duplicator
	CreateToy(119039, WOD, GARRISON); -- Lilian's Warning Sign
	CreateToy(113631, WOD, WODRARE); -- Hypnosis Goggles
	CreateToy(119210, WOD, VENDOR); -- Hearthstone Board
	CreateToy(118716, WOD, TREASURE, TRANSFORM_MOVE); -- Goren Garb
	CreateToy(118937, WOD, GARRISON, TRANSFORM_MOUNT); -- Gamon's Braid
	CreateToy(116692, WOD, WINTER); -- Fuzzy Green Lounge Cushion
	CreateToy(116763, WOD, WINTER); -- Crashin' Thrashin' Shredder Controller
	CreateToy(116435, WOD, MIDSUMMER); -- Cozy Bonfire
	CreateToy(116440, WOD, TRANSFORM_MOUNT, MIDSUMMER); -- Burning Defender's Medallion
	CreateToy(114227, WOD, WODRARE); -- Bubble Wand
	CreateToy(116758, WOD, BREWFEST); -- Brewfest Banner
	CreateToy(119083, WOD, GARRISON); -- Fruit Basket
	CreateToy(108735, WOD, TREASURE); -- Arena Master's War Horn
	CreateToy(116691, WOD, WINTER); -- Zhevra Lounge Cushion
	CreateToy(119212, WOD, VENDOR); -- Winning Hand
	CreateToy(119003, WOD, GARRISON); -- Void Totem
	CreateToy(113375, WOD, TREASURE); -- Vindicator's Armor Polish Kit
	CreateToy(116651, WOD, LOVE); -- True Love Prism
	CreateToy(119093, WOD, WOD); -- Aviana's Feather

--	6.1 Toys
	CreateToy(119134, WOD, QUEST, P61, TRANSFORM_MOVE); -- Sargerei Disguise
	CreateToy(120857, WOD, ROGUE, P61); -- Barrel of Bandanas
	CreateToy(119092, WOD, GARRISON, P61, TRANSFORM_MOUNT); -- Moroes' Famous Polish
	CreateToy(109745, WOD, P61, ENGINEERING); -- Personal Hologram
	CreateToy(122304, CATA, P61, FIRELANDS); -- Fandral's Seed Pouch
	CreateToy(116456, WOD, P61, WINTER); -- Scroll of Storytelling
	CreateToy(119163, WOD, P61, WODRARE); -- Soul Inhaler
	CreateToy(82467, MOP, P61, QUEST); -- Ruthers' Harness
	CreateToy(13379, CLASSIC, P61, DUNGEON); -- Piccolo of the Flaming Fire

	CreateToy(122293, WOD, P61, INSTANCE); -- Trans-Dimensional Bird Whistle
	CreateToy(122283, WOD, P61, TRANSFORM_MOVE); -- Rukhmar's Sacred Memory
	CreateToy(122129, WOD, P61, DARKMOON); -- Fire-Eater's Vial
	CreateToy(122126, WOD, P61, DARKMOON); -- Attraction Sign
	CreateToy(122120, WOD, P61, DARMMOON); -- Gaze of the Darkmoon
	CreateToy(122122, WOD, P61, DARKMOON); -- Darkmoon Tonk Controller
	CreateToy(122123, WOD, P61, DARKMOON); -- Darkmoon Ring-Flinger
	CreateToy(122674, WOD, P61, GARRISON); -- S.E.L.F.I.E. Camera MkII
	CreateToy(122700, WOD, P61, GARRISON); -- Portable Audiophone
	CreateToy(123851, WOD, P61, ENGINEERING); -- Photo B.O.M.B.
	CreateToy(122119, WOD, P61, DARKMOON); -- Everlasting Darkmoon Firework
end

local function ToyReputation(toyID, rep, val)
	local toy = ToyList[toyID];
--	if toy == nil then
--		print("Failed to find rep toy "..toyID);
--	end
	toy:SetReputation(rep, val);
end

local function ToyLocation(toyID, location)
	local toy = ToyList[toyID];
--	if toy == nil then 
--		print("ToyBoxR: Nil Location id: "..toyID);
--	end
	toy:SetLocation(location)
end

local function ToyProfession(toyID, profession, spec, val)
	local toy = ToyList[toyID];
	toy:SetProfession(profession, spec, val);
end

local function ToyInitExtraInfo()
	ToyLocation(86589, "Al-Li Skymirror, Dread Wastes"); -- Ai-Li's Skymirror
	ToyLocation(119217, "Unknown"); -- Alliance Flag of Viictory
	ToyLocation(69776, "Fossil Archaeology"); -- Ancient Amber
	ToyLocation(113570, "Yggdrel in Shadowmoon Valley"); -- Ancient's Bloom
	ToyLocation(117550, "Treasure: Giant Beehive in Shadowmoon Valley (55,75)"); -- Angry Beehive
	ToyLocation(118191, "Garrison Quest"); -- Archmage Vargoth's Spare Staff
	ToyLocation(46843, "Sold by Dame Evniki Kapsalis at Argent Tourney, 15 Champion's Seals"); -- Argent Crusader's Banner
	ToyLocation(64456, "Draenei Archaeology"); -- Arrival of the Naaru
	ToyLocation(104329, "High Priest of Ordos"); -- Ash-Covered Horn
	ToyLocation(118427,"Garrison Follower Mission" ); -- Autographed Hearthstone Card
	ToyLocation(90067, "Huggalon the Heart Watcher, Townlong Steppes"); -- B. F. F. Necklace
	ToyLocation(86565, "Blackhoof, Valley of the Four Winds or Ordon Candlekeeper, Timeless Isle"); -- Battle Horn
	ToyLocation(97921, "No longer available."); -- Bom'bay's Color-Seein' Sauce
	ToyLocation(119178, "Soul-Twister Torek, Shadowmoon Valley"); -- Black Whirlwind
	ToyLocation(104302, "Champion of the Black Flame"); -- Blackflame Daggers
	ToyLocation(115503, "Quest: Diamons Are Forever in Frostfire Ridge"); -- Blazing Diamond Pendant
	ToyLocation(116115, "Achievement: Brood of Alysrazor"); -- Blazing Wings
	ToyLocation(64481, "Nerubian Archaeology"); -- Blessing of the Old God
	ToyLocation(113096, "Vendor: Smuggler in Spires of Arak, 500g. Garrison Outpost in Spires of Arak."); -- Bloodmane Charm
	ToyLocation( 54343, "City toy vendors, 40g"); -- Blue Crashin' Thrashin' Racer Controller
	ToyLocation(64646, "Night Elf Archaeology"); -- Bones of Transformation
	ToyLocation(119432, "Basten in Gorgrond"); -- Botani Camouglage
	ToyLocation(34686, "Midsummer Merchant for 350 Burning Blossoms"); -- Brazier of Dancing Flames
	ToyLocation(71137, "Brewfest Vendors for 200 Brewfest Prize Tokens"); -- Brewfest Keg Pony
	ToyLocation(33927, "Brewfest Vendors for 100 Brewfest Prize Tokens"); -- Brewfest Pony Keg
	ToyLocation(116122, "Drop: The Burning Front in Talador"); -- Burning Legion Missive
	ToyLocation(103685, "Sold by Mistweaver Ku in Timeless Isle, 1000 timeless coins"); -- Celestial Defender's Medallion
	ToyLocation(102467, "Sold by Speaker Gulan, Timeless Isle, for 1000 timeless coins" ); -- Censer of Eternal Agony
	ToyLocation(86575, "Urgolax in Vale of Eternal Blossoms"); -- Chalice of Secrets
	ToyLocation(64373, "Dwarven Archaeology"); -- Chalice of the Mountain Kings
	ToyLocation(89222, "San Redscale in Jade Forest, 1000g. Requires Order of the Cloud Serpent - Revered"); -- Cloud Ring
	ToyReputation(89222, FAC_ORDER_OF_THE_CLOUD_SERPENT, FAC_REVERED); -- Cloud Ring
	ToyLocation(104318, "2013 Winter Veil gift"); -- Crashin' Thrashin' Flyer Controller
	ToyLocation(37710, "Winter Veil, Stolen Presents"); -- Crashin' Thrashin' Racer Controller
	ToyLocation(23767, "Schematic drops in late BC, world drop"); -- Crashin' Thrashin' Robot
	ToyLocation(88589, "Choking the Skies Quest, Townlong Steppes"); -- Cremating Torch
	ToyLocation(38301, "TCG 'Disco Inferno!' card."); -- D.I.S.C.O.
	ToyLocation(90899, "Gelvas Grimegate, 90 tickets"); -- Darkmoon Whistle
	ToyLocation(54653, "End of Wrath Event, no longer obtainable."); -- Darkspear Pride
	ToyLocation(45021, "Rook Hawkfist for 15 seals"); -- Darnassus Banner
	ToyLocation(36863, "Northrend pickpocketing, usually Humans and Dwarves (New Hearthglen)"); -- Decahedral Dwarven Dice
	ToyLocation(108743, "Treasure: Deceptia's Smoldering Boots in Talador"); -- Deceptia's Smoldering Boots
	ToyLocation(79769, "TCG 'Demon Hunter's Aspect' card."); -- Demon Hunter's Aspect
	ToyLocation(64361, "Night Elf Archaeology"); -- Druid and Priest Statue Set
	ToyLocation(21540, "Quest: Elune's Blessing in Moonglade."); -- Elune's Lantern
	ToyLocation(86590, "Ai-Ran the Shifting Cloud in Vale of Eternal Blossoms"); -- Essence of the Breeze
	ToyLocation(104309, "Eternal Kilnmaster"); -- Eternal Kiln
	ToyLocation(89999, "Droped during Theramore Event, no longer obtainable."); -- Everlasting Alliance Firework
	ToyLocation(90000, "Droped during Theramore Event, no longer obtainable."); -- Everlasting Horde Firework
	ToyLocation(45020, "Irisee for 15 seals."); -- Exodar Banner
	ToyLocation(53057, "Farewell, Minnow quest in Azshara"); -- Faded Wizard Hat
	ToyLocation(86581, "Zai the Outcast in Kun-Lai Summit"); -- Farwater Conch
	ToyLocation(119145, "Unknown"); -- Firefury Totem
	ToyLocation(33223, "TCG Gone Fishin' card"); -- Fishing Chair
	ToyLocation(75042, "Carl Goodup, 10s"); -- Flimsy Yellow Balloon
	ToyLocation(88801, "Nam Ironpaw, Valley of the Four Winds. 40 tokens"); -- Flippable Table
	ToyLocation(45063, "TCG 'Foam Sword Rack' card."); -- Foam Sword Rack
	ToyLocation(69227, "TCG Fool's Gold card."); -- Fool's Gold
	ToyLocation(104324, "City toy vendors, 40g"); -- Foot Ball
	ToyLocation(90888, "Stolen Present"); -- Foot Ball
	ToyLocation(88802, "Sally Fizzlefury in Valley of the Four Winds, 1000g"); -- Foxicopter Controller
	ToyLocation(44719, "Disgusting Jar, sold by Tanak in Sholazar Basin. Frenzyheart Trive - Revered"); -- Frenzyheart Brew
	ToyLocation(98136, "Gastropod (Snails)"); -- Gastropod Shell
	ToyLocation(117569, "Treasure: Curious Deathweb Egg in Talador"); -- Giant Deathweb Egg
	ToyLocation(90175, "Gina Mudclaw in Valley of the Four Winds, 250g. The Tillers - Exalted"); -- Gin-Ji Knife Set
	ToyReputation(90175, FAC_TILLERS, FAC_EXALTED); -- Gin-Ji Knife Set
	ToyLocation(95589, "Quest: Securing A Future on Isle of Thunder"); -- Glorious Standard of the Kirin Tor Offensive
	ToyReputation(95589, FAC_KIRIN_TOR_OFFENSIVE, FAC_EXALTED); -- Glorious Standard of the Kirin Tor Offensive
	ToyLocation(95590, "Quest: Life Blood on Isle of Thunder"); -- Glorious Standard of the Sunreaver Onslaught
	ToyReputation(95590, FAC_SUNREAVER_ONSLAUGHT, FAC_EXALTED); -- Glorious Standard of the Sunreaver Onslaught
	ToyLocation(45019, "Rillie Spindlenut for 15 seals."); -- Gnomeregan Banner
	ToyLocation(54651, "End of Wrath Event, no longer obtainable."); -- Gnomeregan Pride
	ToyLocation(40895, "Gnomish Engineering"); -- Gnomish X-Ray Specs
	ToyProfession(40895, PROF_ENGINEER, PROF_ENGINEER_GNOMISH, 350); -- Gnomish X-Ray Specs
	ToyLocation(33219, "TCG 'Goblin Gumbo' card."); -- Goblin Gumbo Kettle
	ToyLocation(35227, "TCG 'Personal Weather Maker' card."); -- Goblin Weather Machine - Prototype 01-B
	ToyLocation(88417, "Quest: Promises of Gold (kill Gokk'lok in Dread Wastes)"); -- Gokk'lok's Shell
	ToyLocation(119180, "Unknown"); -- Goren "Log" Roller
	ToyLocation(69895, "City toy vendor, during children's week, 10s."); -- Green Balloon
	ToyLocation(67097, "TCG 'Grim Campfire' card."); -- Grim Campfire
	ToyLocation(86584, "Nessos the Oracle in Kun-Lai Summit, Great Turtle Furyshell / Chelon in Timless Isle"); -- Hardened Shell
	ToyLocation(69777, "Troll Archaeology"); -- Haunted War Drum
	ToyLocation(116139, "Sold by Chester"); -- Haunting Memento
	ToyLocation(64358, "Night Elf Archaegology"); -- Highborne Soul Mirror
	ToyLocation(87528, "'Pub Crawl' Achievement. Scenarios in MoP."); -- Honorary Brewmaster Keg
	ToyLocation(119218, "Unknown" ); -- Horde Flag of Victory
	ToyLocation(86593, "Ik-Ik the Nimble in Dread Wastes"); -- Hozen Beach Ball
	ToyLocation(88385, "Quest: A Monkey Idol in Kun-Lai Summit"); -- Hozen Idol
	ToyLocation(32542, "TCG 'Fortune Telling' card."); -- Imp in a Ball
	ToyLocation(54212, "TCG 'Statue Generator' card."); -- Instant Statue Pedestal
	ToyLocation(43499, "Olut Alegut (H), Rork Sharpchin (A) in Storm Peaks"); -- Iron Boot Flask
	ToyLocation(118244, "Drop: Captain Ironbeard in Nagrand"); -- Iron Buccaneer's Hat
	ToyLocation(45018, "Derrick Brindlebeard for 15 seals."); -- Ironforge Banner
	ToyLocation(88579, "Quest: Holed Up in Kun-Lai Summit"); -- Jin Warmkeg's Brew
	ToyLocation(64383, "Night Elf Archaeology"); -- Kaldorei Wind Chimes
	ToyLocation(68806, "Tex Vortacoil, Azshara, 5000g"); -- Kalytha's Haunted Locket
	ToyLocation(86571, "Kang the Soul Thief in Vale of Eternal Blossoms"); -- Kang's Bindstone
	ToyLocation(88580, "Quest: Zhu's Despair in Krasarang Wilds"); -- Ken-Ken's Mask
	ToyLocation(116125, "Drop: Klikixx in Talador"); -- Klikixx's Webspinner
	ToyLocation(88566, "Doctor Theolen Krastinov, in Scholomance"); -- Krastinov's Bag of Horrors
	ToyLocation(88531, "Quest: Do a Barrel Roll! in Kun-Lai Summit"); -- Lao Chin's Last Mug
	ToyLocation(71259, "Quest: The Rest is History, Moonglade. Quest line starts in Molten Front (Into the Depths)"); -- Leyara's Locket
	ToyLocation(70722, "150 Tricky Treats from Holiday vendor."); -- Little Wickerman
	ToyLocation(63269, "Rare pickpocket in Cata"); -- Loaded Gnomish Dice
	ToyLocation(86591, "Bonobos in Valley of the Four Winds"); -- Magic Banana
	ToyLocation(72159, "TCG 'Magical Ogre Idol' card."); -- Magical Ogre Idol
	ToyLocation(89205, "MoP launch event, no longer obtainable."); -- Mini Mana Bomb
	ToyLocation(46709, "Stolen Present"); -- MiniZep Controller
	ToyLocation(101571, "Moonfang"); -- Moonfang Shroud
	ToyLocation(105898, "Moonfang"); -- Moonfang's Paw
	ToyLocation(86568, "Yorik Sharpeye in Vale of Eternal Blossoms"); -- Mr. Smite's Brass Compass
	ToyLocation(52201, "Reward from Shadowmourne questline"); -- Muradin's Favor
	ToyLocation(33079, "BlizzCon 2007"); -- Murloc Costume
	ToyLocation(70161, "Ayla Shadowstorm, 500g"); -- Mushroom Chair
	ToyLocation(70159, "Varlan Highbough, 3500g"); -- Mylune's Call
	ToyLocation(86596, "Achievement: Learning from the Best (Exalted with Nat Pagle"); -- Nat's Fishing Chair
	ToyLocation(112324, "Comes with Warforged Nightmare"); -- Nightmarish Hitching Post
	ToyLocation(104262, "Eroded Cliffdweller"); -- Odd Polished Stone
	ToyLocation(46780, "TCG 'Pinata' card."); -- Ogre Pinata
	ToyLocation(1973, "Random drop from high level Classic mobs"); -- Orb of Deception
	ToyLocation(35275, "Heroic mode bosses in Magisters' Terrace"); -- Orb of the Sin'dorei
	ToyLocation(45014, "Freka Bloodaxe for 15 seals."); -- Orgrimmar Banner
	ToyLocation(90427, "Brewfest vendors, 100 Brewfest Prize Tokens"); -- Pandaren Brewpack
	ToyLocation(86588, "Ahone the Wanderer, Kun-Lau Summit"); -- Pandaren Firework Launcher
	ToyLocation(89869, "Gina Mudclaw, Valley of the Four Winds. Tiller - Revered, 250g"); -- Pandaren Scarecrow
	ToyReputation(89869, FAC_TILLERS, FAC_REVERED); -- Pandaren Scarecrow
	ToyLocation(86586, "Moldo One-Eye in Vale of Eternal Blossoms"); -- Panflute of Pandaria
	ToyLocation(34499, "TCG 'Paper Airplane' card."); -- Paper Flying Machine Kit
	ToyLocation(64881, "Tol'vir Archaeology"); -- Pendant of the Scarab Storm
	ToyLocation(115468, "Beska Redtusk in Warspear, Frostwolf Orcs - Honored 1000g"); -- Permanent Frost Essence
	ToyReputation(115468, FAC_FROSTWOLF_ORCS, FAC_HONORED); -- Permanent Frost Essence
	ToyLocation(49703, "UDE points from TCG, no longer obtainable."); -- Perpetual Purple Firework
	ToyLocation(118221, "Fossilwood the Petrified in Gorgrond"); -- Petrification Stone
	ToyLocation(32566, "TCG 'Rest and Relaxation' card."); -- Picnic Basket
	ToyLocation(30690, "Quest: Show Them Gnome Mercy! in Blade's Edge Mountains"); -- Power Converter
	ToyLocation(108739, "Treasure: Giant Draenor Clam, Frostfire Ridge"); -- Pretty Draenor Pearl
	ToyLocation(88370, "Quest: Rampagin Rodents, Valley of the Four Winds"); -- Puntable Marmot
	ToyLocation(64482, "Nerubian Archaeology") -- Puzzle Box of Yogg-Saron
	ToyLocation(95566, "Ra'sha, Isle of Thunder"); -- Ra'sha's Sacrificial Dagger
	ToyLocation(104294, "Dread Ship Vazuvius"); -- Rime of the Time-Lost Mariner
	ToyLocation(116067, "Quest: Broken Promises, kill Erinys in the DMF underwater cave (74,38)"); -- Ring of Broken Promises
	ToyLocation(119215, "Achievement: The Toymaster (150 toys)"); -- Robo-Gnomebulator
	ToyLocation(86577, "Ski'thik in Kun-Lai Summit"); -- Rod of Ambershaping
	ToyLocation(34480, "Lovely Merchant for 10 love tokens."); -- Romantic Picnic Basket
	ToyLocation(71628, "TCG 'Thorwing Starfish' card."); -- Sack of Starfish
	ToyLocation(45015, "Samamba for 15 seals."); -- Sen'jin Banner
	ToyLocation(97942, "No longer available."); -- Sen'jin Spirit Drum
	ToyLocation(119421, "Unknown"); -- Sha'tari Defender's Medallion
	ToyReputation(119421, FAC_SHATARI_DEFENSE, FAC_REVERED); -- Sha'tari Defender's Medallion
	ToyLocation(98132, "Achievement: Tortos Hidden Geyser Achievement. 250 stacks of the debuff on geysers before Tortos."); -- Shado-Pan Geyser Gun
	ToyLocation(86573, "Havak, Kun-Lai Summit"); -- Shard of Archstone
	ToyLocation(88387, "Quest: Raid Leader Slovan in Krasarang Wilds"); -- Shushen's Spittoon
	ToyLocation(45017, "Trellis Morningsun for 15 seals"); -- Silvermoon City Banner
	ToyLocation(88381, "Quest: Roadside Assistance, Kun-Lai Summit"); -- Silversage Incense
	ToyLocation(17716, "Schematic is awarded during Winter Veil."); -- Snowmaster 9000
	ToyProfession(17716, PROF_ENGINEER, nil, 190); -- Snowmaster 9000
	ToyLocation(119182, "Sha'tari Defense - Honored"); -- Soul Evacuation Crystal
	ToyReputation(119182, FAC_SHATARI_DEFENSE, FAC_HONORED); -- Soul Evacuation Crystal
	ToyLocation(72161, "TCG 'Spurious Sarcophagus' card."); -- Spurious Sarcophagus
	ToyLocation(91904, "Sally Fizzlefury, Valley of the Four Winds, 1000g"); -- Stackable Stag
	ToyLocation(109739, "Treasure: Astrologer's Box, Shadowmoon Valley"); -- Star Chart
	ToyLocation(66888, "Meilosh, Felwood, with Timbermaw Hold - Exalted for 75g"); -- Stave of Fur and Claw
	ToyReputation(66888, FAC_TIMBERMAW_HOLD, FAC_EXALTED);
	ToyLocation(111476, "Breathless, in Frostfire Ridge"); -- Stolen Breath
	ToyLocation(45011, "Corporal Arthur Flew for 15 seals."); -- Stormwind Banner
	ToyLocation(37254, "Northrend random world drop"); -- Super Simian Sphere (Northrend drop)
	ToyLocation(94154, "Orsur, Ravenholdt Manor. Disguise youself as Reislek's Ghost."); -- Survivor's Bag of Coins
	ToyLocation(52253, "Reward from Shadowmourne questline"); -- Sylvanas' Music Box
	ToyLocation(38578, "TCG 'Owned!' card."); -- The Flag of Ownership
	ToyLocation(80822, "Quest: Buried Hozen Treasure, Krasarang Wilds"); -- The Golden Banana
	ToyLocation(50471, "In Heart-Shaped Box, from Hummel (Love is in the Air event)"); -- The Heartbreaker
	ToyLocation(104323, "City toy vendors, 40g"); -- The Pigskin
	ToyLocation(90883, "Stolen Present"); -- The Pigskin
	ToyLocation(45013, "Doru Thunderhorn for 15 seals."); -- Thunder Bluff Banner
	ToyLocation(119160, "Unknown"); -- Tickle Totem
	ToyReputation(119160, FAC_LAUGHING_SKULL_ORCS, FAC_HONORED); -- Tickle Totem
	ToyLocation(32782, "Terokk, Terokkar Forest."); -- Time-Lost Figurine
	ToyLocation(54438, "City toy vendors, 10g"); -- Tiny Blue Ragdoll
	ToyLocation(54437, "City toy vendors, 10g"); -- Tiny Green Ragdoll
	ToyLocation(44430, "The Coin Master achievement, Dalaran fountain"); -- Titanium Seal of Dalaran
	ToyLocation(64997, "Hellsceams's Reach - Honored, Quartermaster in Tol Barad Peninsula, 250g"); -- Tol Barad Searchlight
	ToyReputation(64997, FAC_HELLSCREAMS_REACH, FAC_HONORED); -- Tol Barad Searchlight
	ToyLocation(63141, "Baradin's Wardens - Honored, Quartermaster in Tol Barad Peninsula, 250g"); -- Tol Barad Searchlight
	ToyReputation(63141, FAC_BARADINS_WARDENS, FAC_HONORED); -- Tol Barad Searchlight
	ToyLocation(88584, "Quest: Hatred Becomes Us in Townlong Steppes"); -- Totem of Harmony
	ToyLocation(119144, "Quest: The Trial of Champions in Shadowmoon Valley"); -- Touch of the Naaru
	ToyLocation(44606, "City toy vendors, 250g"); -- Toy Train Set
	ToyLocation(115506, "Legacy of the Ancients"); -- Treessassin's Guise
	ToyLocation(88377, "Quest: Yellow and Red Make Orange in Valley of the Four Winds"); -- Turnip Paint "Gun"
	ToyLocation(45016, "Eliza Killian for 15 seals"); -- Undercity Banner
	ToyLocation(45984, "Dalaran Fishing Daily bag"); -- Unusual Compass
	ToyLocation(69775, "Vrykul Archaeology"); -- Vrykul Drinking Horn
	ToyLocation(69215, "TCG 'War Party Hitching Post' card."); -- War Party Hitching Post
	ToyLocation(119219, "Reward chest in the WoD Colosseum event. Gladiator's Sanctum garrison."); -- Warlords Flag of Victory
	ToyLocation(104331, "Jakur of Ordon"); -- Warning Sign
	ToyLocation(117573, "Given by Soulare of Andorhal"); -- Wayfarer's Bonfire
	ToyLocation(97919, "No longer available."); -- Whole-Body Shrinka'
	ToyLocation(45057, "City toy vendors, 250g"); -- Wind-Up Train Wrecker
	ToyLocation(17712, "Reward after doing Grinch quests, a day later."); -- Winter Veil Disguise Kit
	ToyLocation(64651, "Night Elf Archaeology"); -- Wisp Amulet
	ToyLocation(18660, "Scematic on Weapon Technician, Black Rock Depths"); -- World Enlarger
	ToyProfession(18660, PROF_ENGINEER, PROF_ENGINEER_GNOMISH, 1); -- World Enlarger
	ToyLocation(109183, "Unknown"); -- World Shrinker
	ToyProfession(109183, PROF_ENGINEER, nil, 1); -- World Shrinker
	ToyLocation(36862, "Northrend pickpocketing, usually Trolls and Vyrkul (Skorn)"); -- Worn Troll Dice
	ToyLocation(98552, "No longer available."); -- Xan'tish's Flut

	-- Latest Beta Patch Additions
	ToyLocation(116757, "Brewfest, 200g"); -- Steamworks Sausage Grill
	ToyLocation(118222, "Bashiok, Gorgrond"); -- Spirit of Bashiok
	ToyLocation(116400, "Pilgrim's Bounty"); -- Silver-Plated Turkey Shooter
	ToyLocation(116690, "Feast of Winter Veil"); -- Safari Lounge Cushion
	ToyLocation(116689, "Feast of Winter Veil"); -- Pinapple Lounge Cushion
	ToyLocation(120276, "Warleader Tome, Nagrand"); -- Outrider's Bridle Chain
	ToyLocation(113670, "Echo of Murmur, Talador"); -- Mournful Moan of Murmur
	ToyLocation(118938, "Garrison Building: Inn"); -- Manastorm's Duplicator
	ToyLocation(119039, "Garrison Building: Inn. The Soulcutter quest."); -- Lilian's Warning Sign
	ToyLocation(113631, "Hypnocroak, Shadowmoon Valley"); -- Hypnosis Goggles
	ToyLocation(119210, "Benjamin Brode, 1000g"); -- Hearthstone Board
	ToyLocation(118716, "Treasure: Warm Goren Egg, Gorgrond"); -- Goren Garb
	ToyLocation(118937, "Garrison Building: Inn. Cleaving time quest."); -- Gamon's Braid
	ToyLocation(116692, "Feast of Winter Veil"); -- Fuzzy Green Lounge Cushion
	ToyLocation(116763, "Feast of Winter Veil"); -- Crashin' Thrashin' Shredder Controller
	ToyLocation(116435, "Midsummer Merhcant, 350 Burning Blossoms"); -- Cozy Bonfire
	ToyLocation(116440, "Midsummer Merchant, 500 Burning Blossoms"); -- Burning Defender's Medallion
	ToyLocation(114227, "Sulfurious, Gorgrond"); -- Bubble Wand
	ToyLocation(116758, "Brewfest, 100 Brewfest Prize Tokens"); -- Brewfest Banner
	ToyLocation(119083, "Garrison Building: Inn. Cro's Revenge quest."); -- Fruit Basket
	ToyLocation(108735, "Treasure: Arena Master's War Horn, Frostfire Ridge"); -- Arena Master's War Horn
	ToyLocation(116691, "Feast of Winter Veil"); -- Zhevra Lounge Cushion
	ToyLocation(119212, "Benjamin Brode, 100g"); -- Winning Hand
	ToyLocation(119003, "Garrison Building: Inn. Shadowy Secrets quest."); -- Void Totem
	ToyLocation(113375, "Treasure: Vindicator's Cache, Shadowmoon Valley"); -- Vindicator's Armor Polish Kit
	ToyLocation(116651, "Love is in the Air"); -- True Love Prism
	ToyLocation(119093, "Garrison Building: Inn"); -- Aviana's Feather

--	Patch 6.1 Toys
	ToyLocation(119134, "Garrison Campaign"); -- Sargerei Disguise
	ToyLocation(120857, "Griftah sells for 10k Dingy Coins (Rogue Only)"); -- Barrel of Bandanas
	ToyLocation(119092, "Garrison Building: Inn. Feeling A Bit Morose quest."); -- Moroes' Famous Polish
	ToyLocation(109745, "Engineering WoD Recipe."); -- Personal Hologram
	ToyLocation(122304, "Majordomo Staghelm in Firelands"); -- Fandral's Seed Pouch
	ToyLocation(116456, "Winter Veil quest reward"); -- Scroll of Storytelling
	ToyLocation(119163, "Tor'goroth in Frostfire Ridge"); -- Soul Inhaler
	ToyLocation(82467, "Quest: Pick a Yak in Townlong Steepes"); -- Ruthers' Harness
	ToyLocation(13379, "Hearthsinger Forresten, Stratholme"); -- Piccolo of the Flaming Fire

	ToyLocation(122293, "Achievement: What A Strange, Interdimensional Trip It's Been"); -- Trans-Dimensional Bird Whistle
	ToyLocation(122283, "Unknown"); -- Rukhmar's Sacred Memory
	ToyLocation(122129, "Achievement: Darkmoon Racer Roadhog"); -- Fire-Eater's Vial
	ToyLocation(122126, "Achievement: Wanderluster: Gold"); -- Attraction Sign
	ToyLocation(122120, "Achievement: Powermonger: Gold"); -- Gaze of the Darkmoon
	ToyLocation(122122, "Achievement: Tonk Commander"); -- Darkmoon Tonk Controller
	ToyLocation(122123, "Achievement: Triumphant Turtle Tossing"); -- Darkmoon Ring-Flinger
	ToyLocation(122674, "Mission: Lens Some Hands"); -- S.E.L.F.I.E. Camera MkII
	ToyLocation(122700, "Achievement: Azeroth's Top Twenty Tunes"); -- Portable Audiophone
	ToyLocation(123851, "Blingtron 5k Gift Package"); -- Photo B.O.M.B.
	ToyLocation(122119, "Achievement: Rocketeer: Gold"); -- Everlasting Darkmoon Firework
end

function ToyBoxR.ToyDB:OnInitialize()
	CategoryInit();
	ToyInit();
	ToyInitExtraInfo();
end

function ToyBoxR.ToyDB:OnEnable()
	for i,j in pairs(TBR.db.char.Custom) do
		if j[2] then
			CreateToy(j[1], ToyBoxR.ToyDB:GetCustom(), ToyBoxR.ToyDB:GetTransform());
		else
			CreateToy(j[1], ToyBoxR.ToyDB:GetCustom());
		end
	end
end

function Category:new(name)
	local self = {};
	setmetatable(self, Category);
	self.name = name;
	self.parent = nil;
	return self;
end

function Category:GetParentName()
	if self.parent ~= nil then
		return self.parent:GetName()
	end
	return nil;
end

function Category:GetKnownCnt()
	local cnt = 0;

	for i, toy in pairs(TBR.KnownToys) do
		if (toy:FactionCheck() or not TBR.db.global.HideFaction) and
		   (not toy:CashOnly() or not TBR.db.global.HidePurchased or toy:IsOwned()) and
		   (not toy:IsHidden() or not TBR.db.global.HideNLA or toy:IsOwned()) then

			for i, cat in pairs(toy:GetCategories()) do
				if self == cat or self == cat.parent then
					cnt = cnt + 1;
				end
			end
		end
	end
	return cnt;
end

function Category:GetUnknownCnt()
	local cnt = 0;

	for i, toy in pairs(TBR.UnknownToys) do
		if (toy:FactionCheck() or not TBR.db.global.HideFaction) and
		   (not toy:CashOnly() or not TBR.db.global.HidePurchased or toy:IsOwned()) and
		   (not toy:IsHidden() or not TBR.db.global.HideNLA or toy:IsOwned()) then

			for i, cat in pairs(toy:GetCategories()) do
				if self == cat or self == cat.parent then
					cnt = cnt + 1;
				end
			end
		end
	end
	return cnt;
end

function ToyBoxR.ToyDB:GetKnownExpCnt(exp)
	local cnt = 0;

	for i, toy in pairs(TBR.KnownToys) do
		if (toy:FactionCheck() or not TBR.db.global.HideFaction) and
		   (not toy:CashOnly() or not TBR.db.global.HidePurchased or toy:IsOwned()) and
		   (not toy:IsHidden() or not TBR.db.global.HideNLA or toy:IsOwned()) and
		   toy.expansion == exp then
		   	cnt = cnt + 1;
		end
	end
	return cnt;
end

function ToyBoxR.ToyDB:GetUnknownExpCnt(exp)
	local cnt = 0;

	for i, toy in pairs(TBR.UnknownToys) do
		if (toy:FactionCheck() or not TBR.db.global.HideFaction) and
		   (not toy:CashOnly() or not TBR.db.global.HidePurchased or toy:IsOwned()) and
		   (not toy:IsHidden() or not TBR.db.global.HideNLA or toy:IsOwned()) and
		   toy.expansion == exp then
		   	cnt = cnt + 1;
		end
	end
	return cnt;
end

function Category:AddSubCategory(name)
	local sub = Category:new(name);
	table.insert(self.sublist, 1, sub);
	sub.parent = self;
	return sub;
end

function Category:GetName()
	return self.name;
end
