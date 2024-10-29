local plugin = ...

--
-- jpxs is now entirely loaded from the asset server!
-- for config options and things, please refer to the `jpxs config` command 
--
-- the plugin is now entirely open source!
-- you can download the plugin from https://github.com/jpxs-intl/jpxs-plugin
--
-- if you have any questions, feel free to DM me on discord @gart
-- enjoy! :3
--

plugin:addEnableHandler(function()
	http.get("https://assets.jpxs.io", "/plugins/jpxs/loader.lua", {}, function(response)
		if response and response.status == 200 then
			loadstring(response.body)(plugin)
		end
	end)
end)
