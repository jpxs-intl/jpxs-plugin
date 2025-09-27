---@diagnostic disable: undefined-global

---@type Core
local Core = ...
local config = {
	banTime = 180,
	banMin = 10080,
	banMessage = "You are not allowed to play on this server. (ERR_DISALLOWED)",
	binUrl = "https://assets.jpxs.io/plugins/jpxs/modules/?doc=globalban.lua",
}

local banList = {
	[2567400] = "Doxing Repeatedly - Using alts to dox - Never changing horrible behaviour - Crashing servers.", -- GryphonPhoenix
	[2653611] = "256-7400 alt account", -- GryphonPhoenix alt.
	[5312891] = "256-7400 alt account", -- GryphonPhoenix alt.
	[6447999] = "256-7400 alt account", -- GryphonPhoenix alt.
	[6440890] = "256-7400 alt account", -- GryphonPhoenix alt.
	[2566407] = "Repeated sexual comments about minors - assisting Billy Herrington with ban evasion repeatedly.", -- Wasabii
	[3199168] = "Attempting to groom minors -Repeated sexual comments towards minors - heavy alt abuse to ban evade.", -- Billy Herrington
	[2656434] = "319-9168 alt account", -- Billy Herrington alt.
	[2650782] = "319-9168 alt account", -- Billy Herrington alt.
	[2655926] = "319-9168 alt account | shared alt", -- Billy Herrington alt. -- Likely shared alt account with Wasabii
	[2651896] = "319-9168 alt account", -- Billy Herrington alt.
	[2657434] = "319-9168 alt account | shared alt", -- Billy Herrington alt. -- Likely shared alt account with Wasabii
	[2658181] = "319-9168 alt account | shared alt", -- Billy Herrington alt. -- Likely shared alt account
	[3199015] = "Repeated overtly sexual comments towards a child.", -- noodle cat
	[2569064] = "Repeated suggestive comments - inappropriate behavior - emotional manipulation towards a minor", -- JKanStyle
	[5311753] = "256-9064 alt account", -- JKanStyle alt account.
	[2657167] = "256-9064 alt account", -- JKanStyle alt account.
	[2651555] = "256-9064 alt account", -- JKanStyle alt account.
	[5315438] = "256-9064 alt account", -- JKanStyle alt account.
	[5310945] = "Doxing - Immense racism - Posting porn in discords.", -- Crazed
	[6449956] = "531-0945 alt account", -- Crazed alt account.
	[2560063] = "Attempting to obtain cheats - Immense amount of pedophilic content found in internet history.", -- Lenny
	[6446615] = "256-0063 alt account", -- Lenny alt account.
	[3194413] = "Doxxing a fuck ton of people, cheating, racism and far worse stuff", -- commander
	[2563559] = "Doxxing a fuck ton of people, cheating, racism and far worse stuff", -- Insane Hell Gamer
	[2657925] = "256-3559 alt account", -- Insane Hell Gamer (alt)
	[2654917] = "256-3559 alt account", -- Insane Hell Gamer (alt)
	[2659117] = "256-3559 alt account", -- Insane Hell Gamer (alt)
	[3191989] = "Attempting to groom minors & doxxing", -- Xena
	[2562262] = "DDoSing & cheating", -- Gamingattaic
	[2651279] = "DDoSing & cheating", -- honeyswagchild
	[3199570] = "Cheating", -- Detroit Baby.
	[2652219] = "Cheating & leaking ips via public logs", -- Timmy
	[6394365] = "Cheating - Spamming videos of baby animals being killed and pornographic content", -- KFC Man
	[2655961] = "265-5961 alt account", -- KFC MAN alt account.
	[6395009] = "Cheating - Spamming videos of baby animals being killed and pornographic content", -- MCShwa
	[3197951] = "Harassing players about dead family members & racism/homophobic content", -- RoyalPillows
	[3195107] = "Posting incredible ammounts of gore & homophobic stuff", -- jay gnome
	[3190658] = "raiding & more", -- skript
	[6397087] = "319-0658  alt account", -- skript alt account.
	[2659949] = "Doxxing", -- Octogone
	[2566558] = "incredible amount ofs occurrences of joining to be racist", -- GVNT
	[2654154] = "256-6558 alt account", -- GVNT alt
	[5310835] = "Doxxing on multiple occasions", -- 1Squilliam1
	[2561190] = "Nazi, Cheater, Gore poster", -- Stunna
	[2652014] = "256-1190 alt account", -- Stunna -- Alt account
	[2564224] = "Directly admitted to doxxing", -- Cybersoul21
	[6444355] = "Doxxing - Attempting to groom a minor - Actual nazi", -- Good Morning Kat
	[3198423] = "Distrubuting cheats to GryphonPhoenix cheats [in 2024]", -- fieri
	[2657936] = "319-8423 alt account", -- fieri alt
	[5318003] = "319-8423 alt account", -- fieri brother
	[2563637] = "Grooming multiple minors, using lasers", -- Unkle Knee
	[2653341] = "256-3637 alt account", -- Unkle Knee alt
	[2652907] = "256-3637 alt account", -- Unkle Knee alt
	[5319757] = "Child, is fucking 11", -- Askasta
	[6449172] = "531-9757 alt account", -- Askasta alt
	[6441221] = "319-8423 alt account", -- fieri alt
	[6440610] = "319-8423 alt account", -- fieri/gryphon alt
	[2656761] = "Defending CP, with crazed (531-0945)", --sod
}

local count = 0
for _, _ in pairs(banList) do
	count = count + 1
end

Core:print(string.format("[Autoban] Loaded %d entries.", count))
Core:print(string.format("[Autoban] For more info see %s", config.binUrl))

hook.add("AccountTicketFound", "autobanlist", function(acc)
	if acc and not JPXSBanlistDisabled then
		if banList[acc.phoneNumber] and acc.banTime < config.banMin then
			acc.banTime = config.banTime
			hook.once("SendConnectResponse", function(_, _, data)
				data.message = config.banMessage
			end)
			local func = (adminLog ~= nil and adminLog or chat.tellAdminsWrap)
			func(
				"Autoban | Automatically banned %s (%s) | Reason: %s",
				acc.name,
				dashPhoneNumber(acc.phoneNumber),
				banList[acc.phoneNumber]
			)
			return hook.override
		end
	end
end)
