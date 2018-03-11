local ToyBoxR = LibStub("AceAddon-3.0"):GetAddon("ToyBoxR");

ToyBoxR.LDB = ToyBoxR:NewModule("LDB");

local ToyTimer = LibStub("AceTimer-3.0");

local ldb = LibStub:GetLibrary("LibDataBroker-1.1");
local LibQTip = LibStub("LibQTip-1.0");
local LibIcon = LibStub("LibDBIcon-1.0");
local appName = ...
local TBR = ToyBoxR.TBR;

local TBRicon = "Interface\\Icons\\INV_Misc_Toy_10"

TBR.IconFormat = "|T%s:20:20|t"
TBR.TimerIsScheduled = false;

TBR.VIEW_ALL = 1;
TBR.VIEW_TRANSFORM = 2;
TBR.VIEW_OTHER = 3;
local ViewMsgs = { "All", "Transform", "Non Transform" };

TBR.ShownToys = {};

BINDING_HEADER_ToyBoxR = "ToyBoxR";
_G[ "BINDING_NAME_CLICK ToyBoxRBtn:LeftButton" ] = "Use Random Toy"
_G[ "BINDING_NAME_CLICK ToyBoxRTrans:LeftButton" ] = "Use Random Transformation"

function ToyBoxR.LDB:OnInitialize()
	TBR.broker = ldb:NewDataObject("ToyBoxR", {
		type = "data source",
		icon = TBRicon,
		label = "ToyBoxR",
		text = "ToyBoxR",
		OnEnter = function(self, button) ToyBoxR.LDB:OnEnter(self, button) end,
	});

	LibIcon:Register(appName, TBR.broker, TBR.db.global.minimap);
end

function ToyBoxR.LDB:ChangeIcon(val)
	if val then
		LibIcon:Show(appName)
	else
		LibIcon:Hide(appName)
	end
end


local TBR_Button;
function SecureTooltipEnter(self, toy)
	TBR_Button = self;
	if InCombatLockdown() then return end
	
	ToyBoxRMenu:SetScript("OnEnter", function(self)
		if TBR_Button then TBR_Button:GetScript("OnEnter")(self); end
	end);
	ToyBoxRMenu:SetScript("OnLeave", function(self)
		if TBR_Button then TBR_Button:GetScript("OnLeave")(self); end
		ToyBoxRMenu:Hide();
	end)	
	self:SetScript("OnHide", function()
		ToyBoxRMenu:Hide();
	end)
	ToyBoxRMenu:SetScript('PreClick', function (_, btn) 
		if toy == nil then
			ToyBoxR.LDB:MenuViewSwap()
		else
			ToyBoxR.LDB:SecurePreClick(btn, ToyBoxRMenu, toy)
		end
	end);
	ToyBoxRMenu:SetScript('PostClick', function (_, btn) 
		ToyBoxR.LDB:SecurePostClick(ToyBoxRMenu)
	end)
	ToyBoxRMenu:SetFrameStrata(self:GetFrameStrata())
	ToyBoxRMenu:SetFrameLevel(self:GetFrameLevel()+1)
	ToyBoxRMenu:SetAllPoints(self)
	ToyBoxRMenu:Show()
end

function TBR_CooldownTime(toy)
	local startTime, duration, enable = GetItemCooldown(toy:GetID());
	if enable == 1 and duration > 0 then
		local cooldown = duration - (GetTime() - startTime);
		if cooldown >= 60 then
			cooldown = math.floor(cooldown / 60);
			if cooldown >= 60 then
				cooldown = math.floor(cooldown / 60);
				cooldown = cooldown.."h";
			else
				cooldown = cooldown.."m";
			end
		elseif cooldown > 0 and cooldown < 60 then
			cooldown = math.floor(cooldown).."s";
		end
		return "|cffffff00"..cooldown.."|r";
	end
	return nil
end

local function SortToys(a, b)
	local toyA = ToyBoxR.ToyDB:GetToy(a);
	local toyB = ToyBoxR.ToyDB:GetToy(b);

	if toyA:GetName() < toyB:GetName() then
		return 1;
	else
		return nil;
	end
end

function ToyBoxR.LDB:UpdateShownToys(viewtype, offcooldown)
	TBR.ShownToys = {};
	
	for i, j in pairs(TBR.db.char.ToyBoxRList) do
		local toy = ToyBoxR.ToyDB:GetToy(i);
		local cat, catlist;
		local filter_check = false;

		if toy == nil then 
			filter_check = false;
		elseif viewtype == TBR.VIEW_ALL then
			filter_check = true;
		elseif viewtype == TBR.VIEW_TRANSFORM then
			catlist = toy:GetCategories();
			for _,cat in pairs(catlist) do
				if cat == TBR.TRANSFORM_MOVE or cat == TBR.TRANSFORM_MOUNT then
					filter_check = true;
				end
			end
		else
			filter_check = true;
			catlist = toy:GetCategories();
			for _,cat in pairs(catlist) do
				if cat == TBR.TRANSFORM_MOVE or cat == TBR.TRANSFORM_MOUNT then
					filter_check = false;
				end
			end
		end

		if toy ~= nil then
			if toy:GetName() == nil then 
				filter_check = false;
			end
			if not toy:FactionCheck() then
				filter_check = false;
			end
			if not toy:CanUse() then
				filter_check = false;
			end
		end
		if filter_check == true then
			if offcooldown == true then
				local startTime, duration, enable = GetItemCooldown(i);
				if enable ~= 1 or duration == 0 then
					table.insert(TBR.ShownToys, i);
				end
			else
				table.insert(TBR.ShownToys, i);
			end
		end
	end
	table.sort(TBR.ShownToys, SortToys);

end

function ToyBoxR.LDB:SecurePreClick(btn, secure, toy, view)
	if btn == "RightButton" then
		ToyBoxR:UIOpen();
		return;
	end

	if toy == nil then
		if view == nil then view = TBR.db.global.BrokerView end
		ToyBoxR.LDB:UpdateShownToys(view, true);
		if #TBR.ShownToys == 0 then
			ToyBoxR:Print("No toys on list are off cooldown.");
			return;
		end
		local rnd = fastrandom(#TBR.ShownToys);
		toy = ToyBoxR.ToyDB:GetToy(TBR.ShownToys[rnd]);
	end

	local cooldown = TBR_CooldownTime(toy);
	if cooldown ~= nil then
		ToyBoxR:Print(toy:GetName(), "is on cooldown for", cooldown..".");
		return;
	end

	ToyBoxR:Print("Using", toy:GetName());
	local found = false;


	if toy:IsCustom() then
		for x = 0,4 do
			for y = 1, GetContainerNumSlots(x) do
				local id = GetContainerItemID(x,y);
				if id == toy:GetID() then
					found = true;
				end
			end
		end
		if found == false then
			ToyBoxR:Print(toy:GetName(), "is not found in your current inventory.");
			return;
		end
	end
	secure:SetAttribute("type", "item");
	secure:SetAttribute("item", toy:GetName());
--	secure:SetAttribute("item", "item:"..toy:GetID());
	if TBR.TimerIsScheduled == false then
		ToyTimer:ScheduleTimer("CheckCooldown", .5);
		TBR.TimerIsScheduled = true;
	end
end

function ToyBoxR.LDB:SecurePostClick(secure)
	secure:SetAttribute("type", nil);
	secure:SetAttribute("item", nil);
end

function ToyBoxR.LDB:OnEnable()
	CreateFrame("Button", "ToyBoxRBtn", UIParent, "SecureActionButtonTemplate");
	ToyBoxRBtn:SetScript('PreClick', function (_, btn) 
		ToyBoxR.LDB:SecurePreClick(btn, ToyBoxRBtn, nil, nil);
	end);
	ToyBoxRBtn:SetScript('PostClick', function (_, btn) 
		ToyBoxR.LDB:SecurePostClick(ToyBoxRBtn);
	end);
	ToyBoxRBtn:SetScript("OnEnter", function(self) 
		ToyBoxR.LDB:OnEnterSecure(self, button);
	end);
	ToyBoxRBtn:SetScript("OnLeave", function(self)
		if TBR.chocolate and TBR.chocolate.autohide then
			TBR.chocolate:HideAll();
		end
	end);
	ToyBoxRBtn:RegisterForClicks('AnyUp');
	ToyBoxRBtn:Hide();

	CreateFrame("Button", "ToyBoxRTrans", UIParent, "SecureActionButtonTemplate");
	ToyBoxRTrans:SetScript('PreClick', function (_, btn) 
		ToyBoxR.LDB:SecurePreClick(btn, ToyBoxRTrans, nil, TBR.VIEW_TRANSFORM);
	end);
	ToyBoxRTrans:SetScript('PostClick', function (_, btn) 
		ToyBoxR.LDB:SecurePostClick(ToyBoxRTrans);
	end);
	ToyBoxRTrans:SetScript("OnEnter", function(self) 
		ToyBoxR.LDB:OnEnterSecure(self, button);
	end);
	ToyBoxRTrans:RegisterForClicks('AnyUp');
	ToyBoxRTrans:Hide();

	CreateFrame("Button", "ToyBoxRMenu", UIParent, "SecureActionButtonTemplate") 
	ToyBoxRMenu:RegisterForClicks('LeftButtonUp');
	ToyBoxRMenu:Hide()
end 

function TBR.OpenConfig()
	ToyBoxR:UIOpen();
end

function ToyBoxR.LDB:MenuViewSwap(self)
	if TBR.db.global.BrokerView == TBR.VIEW_ALL then
		TBR.db.global.BrokerView = TBR.VIEW_TRANSFORM;
	elseif TBR.db.global.BrokerView == TBR.VIEW_TRANSFORM then
		TBR.db.global.BrokerView = TBR.VIEW_OTHER;
	else
		TBR.db.global.BrokerView = TBR.VIEW_ALL;
	end
	local msg = "View: "..ViewMsgs[TBR.db.global.BrokerView].." (Click to Change)";
	local tooltip = LibQTip:Acquire("ToyBoxRTooltip", 1, "LEFT", "LEFT");
	if tooltip:IsShown() then
		tooltip:Clear();
		ToyBoxR.LDB:Tooltip_Generate(tooltip);
	end
end

local function Tooltip_AddRows(tooltip)
	local format = "%s";
	local empty = true;
	format = "|cffffc1c1"..format.."|r";

	if TBR.db.global.BrokerView == nil then
		TBR.db.global.BrokerView = TBR.VIEW_ALL;
	end

	ToyBoxR.LDB:UpdateShownToys(TBR.db.global.BrokerView, false);

	for i, j in pairs(TBR.ShownToys) do
		local toy = ToyBoxR.ToyDB:GetToy(j);
		local name = toy:GetName();
		local icon = toy:GetIcon();
		local line;
		
		local cooldown = TBR_CooldownTime(toy);
		if cooldown ~= nil then
			name = name.." "..cooldown;

			if TBR.TimerIsScheduled == false then
				ToyTimer:ScheduleTimer("CheckCooldown", 1);
				TBR.TimerIsScheduled = true;
			end
		end
		
		if empty == true then
			line = tooltip:AddLine();
			local msg = "Viewing: "..ViewMsgs[TBR.db.global.BrokerView].." (Click to Change)";
			tooltip:SetCell(line, 1, msg, nil, "CENTER", 1);
			tooltip:SetCellScript(line, 1, "OnEnter", SecureTooltipEnter, nil);
			tooltip:AddSeparator();
		end
		empty = false;
		line = tooltip:AddLine();
		tooltip:SetCell(line, 1, string.format(TBR.IconFormat, icon).." "..name, nil, "LEFT", 1);
		tooltip:SetCellScript(line, 1, "OnEnter", SecureTooltipEnter, toy);
	end
	
	if empty == true then
		line = tooltip:AddLine();
		local msg = "Viewing: "..ViewMsgs[TBR.db.global.BrokerView].." (Click to Change)";
		tooltip:SetCell(line, 1, msg, nil, "CENTER", 1);
		tooltip:SetCellScript(line, 1, "OnEnter", SecureTooltipEnter, nil);
		tooltip:AddSeparator();
		local line = tooltip:AddLine();
		tooltip:SetCell(line, 1, "Right Click to add toys to this menu.");
		line = tooltip:AddLine();
		tooltip:SetCell(line, 1, "Left Click to pick a random transformation.");
		line = tooltip:AddLine();
		tooltip:SetCell(line, 1, "Click pet in menu to use a specific toy.");
		tooltip:SetColumnScript(1, "OnMouseDown", TBR.OpenConfig);
	end

end

function ToyBoxR.LDB:Tooltip_Generate_Category(tooltip)
	tooltip:SetScale(TBR.db.profile.Scale);
	local line = tooltip:AddLine()

	tooltip:SetCell(line, 1, "|cff00E5EECategory|r", nil, "CENTER", 1);
	tooltip:AddSeparator();
end

function ToyBoxR.LDB:Tooltip_Generate(tooltip)
	tooltip:SetScale(TBR.db.profile.Scale);
	local line = tooltip:AddLine()

	tooltip:SetCell(line, 1, "|cff00E5EEToyBoxR|r", nil, "CENTER", 1);
	tooltip:AddSeparator();

	if TBR.db.global.mod == 1 or
	   (TBR.db.global.mod == 2 and IsControlKeyDown()) or
	   (TBR.db.global.mod == 3 and IsShiftKeyDown()) or
	   (TBR.db.global.mod == 4 and IsAltKeyDown()) then
		Tooltip_AddRows(tooltip);
	end
end

function ToyTimer:CheckCooldown()
	TBR.TimerIsScheduled = false;
	local tooltip = LibQTip:Acquire("ToyBoxRTooltip", 1, "LEFT", "LEFT");
	if tooltip:IsShown() then
		tooltip:Clear();
		ToyBoxR.LDB:Tooltip_Generate(tooltip);
	end
end

function ToyBoxR.LDB:OnEnter(brokerframe, button)
	if GameTooltip ~= nil then GameTooltip:Hide(); end
	if InCombatLockdown() then return end;
	if brokerframe.bar ~= nil and brokerframe.bar.chocolist ~= nil then
		TBR.chocolate = brokerframe.bar;
	end

	ToyBoxRBtn:RegisterForDrag("LeftButton")
	ToyBoxRBtn:SetMovable(true)
	ToyBoxRBtn:SetScript("OnDragStart", function(self)
		if InCombatLockdown() then return end
		if GameTooltip ~= nil then GameTooltip:Hide() end
		brokerframe:GetScript("OnDragStart")(brokerframe)
		self:SetScript("OnUpdate", function(self)
			self:SetAllPoints(brokerframe)
			if not IsMouseButtonDown("LeftButton") then
				brokerframe:GetScript("OnDragStop")(brokerframe)
				self:SetScript("OnUpdate",nil)
			end
		end)
		self:Show()
	end)

	brokerframe:SetScript("OnHide", function()
		if not InCombatLockdown() then ToyBoxRBtn:Hide(); end
	end)

	ToyBoxRBtn:SetFrameStrata(brokerframe:GetFrameStrata())
	ToyBoxRBtn:SetFrameLevel(brokerframe:GetFrameLevel()+1)
	ToyBoxRBtn:SetAllPoints(brokerframe)
	ToyBoxRBtn:Show()
end

function ToyBoxR.LDB:OnEnterSecure(self, button)
	if TBR.chocolate and TBR.chocolate.autohide then
		TBR.chocolate:ShowAll();
	end
	local tooltip = LibQTip:Acquire("ToyBoxRTooltip", 1, "LEFT", "LEFT");
	if tooltip:IsShown() then
		return;
	end

	tooltip:SmartAnchorTo(self);

	tooltip:Clear();

	ToyBoxR.LDB:Tooltip_Generate(tooltip);

	tooltip:EnableMouse();
	tooltip:SmartAnchorTo(self);
	tooltip:SetAutoHideDelay(0.25, self);
	tooltip:UpdateScrolling();
	tooltip:Show();
end

function ToyBoxR.LDB:LibIconToggle(val)
	if val then
		LibIcon:Show(appName);
	else
		LibIcon:Hide(appName);
	end
end
