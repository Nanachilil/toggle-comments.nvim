local M = {}

-- 默认注释符号配置（包含符号和正则表达式）
local default_symbols = {
	c = {
		symbol = "// ",
		pattern = "^%s*// ", -- ^ 一行的开头，%s* 任意个空字符串
	},
	cpp = {
		symbol = "// ",
		pattern = "^%s*// ",
	},
	lua = {
		symbol = "-- ",
		pattern = "^%s*-- ",
	},
	python = {
		symbol = "# ",
		pattern = "^%s*# ",
	},
}

-- Normal 模式注释切换函数
local function toggle_normal_comment(symbol, pattern)
	local row = vim.api.nvim_win_get_cursor(0)[1] -- 这个函数返回[row, col]，并且row是从1开始的
	local lines = vim.api.nvim_buf_get_lines(0, row - 1, row, false)
	if #lines == 0 then
		return
	end

	-- 切换当前行注释状态
	if lines[1]:match(pattern) then
		lines[1] = lines[1]:gsub(pattern, "", 1)
	else
		lines[1] = symbol .. lines[1]
	end

	vim.api.nvim_buf_set_lines(0, row - 1, row, false, lines)
end

-- Visual 模式注释切换函数
local function toggle_visual_comment(symbol, pattern)
	-- 阶段 1：锁定选区信息 -------------------------------------------------
	local orig_visualmode = vim.fn.visualmode()
	local orig_start = vim.api.nvim_buf_get_mark(0, "<")
	local orig_end = vim.api.nvim_buf_get_mark(0, ">")

	-- 阶段 2：原子化获取选区范围 --------------------------------------------
	vim.cmd([[noautocmd keepjumps normal! "vy]]) -- 静默抓取选区内容到寄存器v
	local selected_text = vim.fn.getreg("v")
	local start_line = vim.fn.line("'[") -- 精准起始行
	local end_line = vim.fn.line("']") -- 精准结束行

	-- 阶段 3：无痕操作缓冲区 ----------------------------------------------
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

	-- 智能注释检测算法
	local has_comment = false
	for i, line in ipairs(lines) do
		if line:match(pattern) then
			has_comment = true
			break
		end
	end

	-- 批量化修改
	for i, line in ipairs(lines) do
		if has_comment then
			lines[i] = line:gsub(pattern, "", 1)
		else
			lines[i] = symbol .. line
		end
	end

	vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, lines)

	-- 阶段 4：完美还原现场 ------------------------------------------------
	vim.fn.setreg("v", selected_text) -- 恢复原始选区内容
	vim.api.nvim_buf_set_mark(0, "<", orig_start[1], orig_start[2], {})
	vim.api.nvim_buf_set_mark(0, ">", orig_end[1], orig_end[2], {})
	vim.cmd("normal! gv") -- 重新激活原始选区
end

-- 启动函数
function M.setup(user_config)
	-- 合并用户配置
	local config = vim.tbl_deep_extend("force", default_symbols, user_config and user_config.symbols or {})

	-- 为每个文件类型设置自动命令
	for ft, ft_config in pairs(config) do
		vim.api.nvim_create_autocmd("FileType", {
			pattern = ft,
			callback = function(args)
				local bufnr = args.buf
				local symbol = ft_config.symbol
				local pattern = ft_config.pattern

				-- Normal 模式映射
				vim.keymap.set("n", "<C-_>", function()
					toggle_normal_comment(symbol, pattern)
				end, { buffer = bufnr, desc = "Toggle line comment" })

				-- Visual 模式映射
				vim.keymap.set("x", "<C-_>", function()
					toggle_visual_comment(symbol, pattern)
				end, { buffer = bufnr, desc = "Toggle block comment" })
			end,
		})
	end
end

return M
