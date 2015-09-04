local gpu = require("component").gpu
local unicode = require("unicode")
local syntax = {}

----------------------------------------------------------------------------------------------------------------

--Стандартные цветовые схемы
local colorSchemes = {
	["midnight"] = {
		["recommendedBackground"] = 0x262626,
		["text"] = 0xffffff,
		["strings"] = 0xff2024,
		["loops"] = 0xffff98,
		["comments"] = 0xa2ffb7,
		["boolean"] = 0xffcc66,
		["logic"] = 0xffcc66,
		["numbers"] = 0x24c0ff,
		["functions"] = 0xffcc66,
		["compares"] = 0xffff98,
	},
}

--Текущая цветовая схема
local currentColorScheme = {}
--Шаблоны поиска
local patterns
--Размер массива шаблонов поиска
local sPatterns

----------------------------------------------------------------------------------------------------------------

--Пересчитать цвета шаблонов
--Приоритет поиска шаблонов снижается сверху вниз
local function definePatterns()
	patterns = {
		--Комментарии
		{ ["pattern"] = "%-%-.*", ["color"] = currentColorScheme.comments, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		
		--Строки
		{ ["pattern"] = "\".-[^\"\"]\"", ["color"] = currentColorScheme.strings, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		
		--Циклы, условия, объявления
		{ ["pattern"] = "while ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "do$", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "do ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "end$", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "end ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "for ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "repeat ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "if ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "then", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "until ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "return", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "local ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "function ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "else$", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "else ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "elseif ", ["color"] = currentColorScheme.loops, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },

		--Состояния переменной
		{ ["pattern"] = "true", ["color"] = currentColorScheme.boolean, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "false", ["color"] = currentColorScheme.boolean, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "nil", ["color"] = currentColorScheme.boolean, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
				
		--Функции
		{ ["pattern"] = "%s([%a%d%_%-%.])*%(", ["color"] = currentColorScheme.functions, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		
		--And, or, not, break
		{ ["pattern"] = "and ", ["color"] = currentColorScheme.logic, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "or ", ["color"] = currentColorScheme.logic, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "not ", ["color"] = currentColorScheme.logic, ["cutFromLeft"] = 0, ["cutFromRight"] = 1 },
		{ ["pattern"] = "break", ["color"] = currentColorScheme.logic, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },

		--Числа
		{ ["pattern"] = "%s(0x)(%w*)", ["color"] = currentColorScheme.numbers, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "(%s)([%d%.]*)", ["color"] = currentColorScheme.numbers, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		
		--Сравнения и мат. операции
		{ ["pattern"] = "<=", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = ">=", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "<", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = ">", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "==", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "~=", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "=", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "%+", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "%-", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "%*", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "%/", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "%.%.", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "%#", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
		{ ["pattern"] = "#^", ["color"] = currentColorScheme.compares, ["cutFromLeft"] = 0, ["cutFromRight"] = 0 },
	}

	--Ну, и размер массива шаблонов тоже
	sPatterns = #patterns
end

--Проанализировать строку и создать на ее основе цветовую карту
function syntax.highlight(text)
	--Массив символов и их цветов
	local massiv = {}
	--Длина текста
	local sText = unicode.len(text)

	--Базовый цвет текста
	local currentColor = currentColorScheme.text


	--Откуда будем искать совпадения шаблонов
	local searchFrom = 1
	--Переменная успешного поиска
	local sucessfullyFound = false
	--Перебираем всю строку посимвольно и присваиваем каждому символу свой цвет
	local symbol = 1
	while symbol <= sText do
		--Обнуляем успех поиска, ибо хуй знает, найдет ли оно что-то
		sucessfullyFound = false
		
		--Перебираем все шаблоны
		for i = 1, sPatterns do
			--Ищем совпадения
			local starting, ending = string.find(text, patterns[i].pattern, searchFrom)
			--Если старт совпадения совпадает с номером символа, то
			if starting and starting == symbol then
				--Ставим цвет для текущего и последующих символов
				currentColor = patterns[i].color
				--Указываем всем символам, соответствующим шаблону, их цвет
				for j = (starting + patterns[i].cutFromLeft), (ending - patterns[i].cutFromRight) do
					massiv[j] = { ["symbol"] = unicode.sub(text, j, j), ["color"] = currentColor }
				end
				--Указываем новую позицию поиска
				searchFrom = ending + 1 - patterns[i].cutFromRight
				--И новую позицию символа
				symbol = searchFrom
				--Ставим true, ибо паттерн был найден
				sucessfullyFound = true
				--Разрываем цикл, ибо нехуй больше искать
				break
			end

			--Обнуляем переменные, ибо я так люблю
			starting, ending = nil, nil
		end

		--Если ни хера не нашло, то
		if not sucessfullyFound then
			--Ставим обычный цвет текста
			currentColor = currentColorScheme.text
			--Загоняем обычный символ
			massiv[symbol] = { ["symbol"] = unicode.sub(text, symbol, symbol), ["color"] = currentColor }
			--Го некст
			symbol = symbol + 1
		end
	end

	--И тут тоже
	sText, currentColor, searchFrom = nil, nil, nil

	--Возвращаем полученный массив
	return massiv
end

--Объявить новую цветовую схему
function syntax.setColorScheme(colorScheme)
	--Выбранная цветовая схема
	currentColorScheme = colorScheme
	--Пересчитываем шаблоны
	definePatterns()
end

--Нарисовать созданный массив по указанным координатам и обрезать строку до указанной длины.
function syntax.highlightAndDraw(x, y, limit, text)
	--Чутка левее делаем координату, т.к. цикл начинается с 1
	x = x - 1
	--Получаем подсвеченный массив
	local massiv = syntax.highlight(text)
	--Задаем стартовый цвет
	local currentColor = currentColorScheme.text
	gpu.setForeground(currentColor)
	--Перебираем все элементы полученного массива
	for symbol = 1, limit do
		--Если такой символ в массиве вообще существует, то
		if massiv[symbol] then
			--Легкая оптимизация. Меняет цвет текста только в случае несоответствия текущего цвета и цвета из массива
			if currentColor ~= massiv[symbol].color then currentColor = massiv[symbol].color; gpu.setForeground(massiv[symbol].color) end
			--Рисуем символ на экране
			gpu.set(x + symbol, y, massiv[symbol].symbol)
		--А если не существует, то разорвать цикл и закончить рисование строки
		else
			break
		end	
	end
end

--Открыть файл для чтения и отобразить первые строки из него, чтобы чекнуть, как работает подсветка
function syntax.highlightFileForDebug(pathToFile, colorSchemeName)
	--Устанавливаем цветовую схему
	syntax.setColorScheme(colorSchemes[colorSchemeName] or colorSchemes.midnight)
	--Очищаем экран рекомендуемым цветом
	ecs.prepareToExit(currentColorScheme.recommendedBackground, currentColorScheme.text)
	--Получаем размер экрана
	local xSize, ySize = gpu.getResolution()
	--Открываем файлик
	local file = io.open(pathToFile, "r")
	--Счетчик строк
	local lineCounter = 1
	--Читаем строки
	for line in file:lines() do
		--Подсвечиваем строку и рисуем
		syntax.highlightAndDraw(2, lineCounter, xSize - 2, line)
		--Счетчик в плюс
		lineCounter = lineCounter + 1
		--Разрываем цикл, если кол-во строк превысило высоту экрана
		if lineCounter > ySize then break end 
	end
	--Закрываем файл
	file:close()
end

----------------------------------------------------------------------------------------------------------------

--Стартовое объявление цветовой схемы при загрузке библиотеки
syntax.setColorScheme(colorSchemes.midnight)

--syntax.highlightFileForDebug("highlightText", midnight)

return syntax



