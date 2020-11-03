function register_handler()
	script.on_nth_tick(300, process_inv)
end

function process_inv()
	for i, player in pairs(game.players) do
		local trash_inv = player.get_inventory(defines.inventory.character_trash)

		if not trash_inv.is_empty() then
			local player_inv = player.get_main_inventory()

			for item, wanted_number in pairs(get_wanted_items(player, player_inv)) do
				local to_transfer = math.min(wanted_number, trash_inv.get_item_count(item))
				while to_transfer > 0 do
					local trash_stack = trash_inv.find_item_stack(item)
					if not trash_stack then
						break
					end

					local original_count = nil

					if to_transfer < trash_stack.count then
						-- hacky way of getting the game to insert partial stacks
						-- while still preserving health, etc
						original_count = trash_stack.count
						trash_stack.count = to_transfer
					end

					local inserted = insert_to_cursor_and_inv(player, player_inv, trash_stack)

					if original_count then
						trash_stack.count = original_count
					end

					if inserted == 0 then
						break
					end

					if inserted == trash_stack.count then
						trash_stack.clear()
					else
						trash_stack.count = trash_stack.count - inserted
					end
					to_transfer = to_transfer - inserted
				end
			end
			player_inv.sort_and_merge()
		end
	end
end

function insert_to_cursor_and_inv(player, player_inv, item_stack)
	-- transfer stack first, then rebalance cursor
	local stack_count = item_stack.count

	if player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.transfer_stack(item_stack) then
		return stack_count
	end

	local inserted_to_cursor = stack_count - item_stack.count

	return inserted_to_cursor + player_inv.insert(item_stack)
end

function get_wanted_items(player, player_inv)
	local wanted = {}
	for item, number_requested in pairs(player.auto_trash_filters) do
		local amount_unfilfilled = number_requested - player_inv.get_item_count(item)

		if amount_unfilfilled > 0 then
			wanted[item] = amount_unfilfilled
		end
	end

	if player.cursor_stack and player.cursor_stack.valid_for_read then
		if wanted[player.cursor_stack.name] then

			wanted[player.cursor_stack.name] = wanted[player.cursor_stack.name] - player.cursor_stack.count

			if wanted[player.cursor_stack.name] == 0 then
				wanted[player.cursor_stack.name] = nil
			end
		end
	end

	-- game.print(serpent.dump(wanted))

	return wanted
end

register_handler()
