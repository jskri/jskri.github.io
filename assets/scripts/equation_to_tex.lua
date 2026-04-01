-- Format equations.
--
-- Input example:
--
-- ```equation
-- create : State × E × Subset(E × E) → State
-- create(state, entity, relations) =
--   state ∪ { (entity, id, entity) }
--         ∪ { (entity, predicate, object) ∈ E × E × E | (predicate, object) ∈ relations }
-- ```
--
-- Output example:
-- 
-- \begin{equation*}\begin{aligned}
-- &create : State × E × Subset(E × E) → State\\
-- &create(state,~ entity,~ relations) =\\
-- &  state ∪ \{ (entity,~ id,~ entity) \}\\
-- &        ∪ \{ (entity,~ predicate,~ object) ∈ E × E × E ~|~ (predicate,~ object) ∈ relations \}
-- \end{aligned}\end{equation*}

if PANDOC_VERSION and PANDOC_VERSION.must_be_at_least then
  PANDOC_VERSION:must_be_at_least("2.11")
else
  error("pandoc version >=2.11 is required")
end

local function format_inline_math(s)
  s, _ = string.gsub(s, ",", [[,~]])
  s, _ = string.gsub(s, "bank account ", [[bank~account~]])
  s, _ = string.gsub(s, "{", [[\{]])
  s, _ = string.gsub(s, "}", [[\}]])
  s, _ = string.gsub(s, "|", [[~|~]])
  s, _ = string.gsub(s, "_%)", [[\_)]])
  s, _ = string.gsub(s, "_,", [[\_,]])
  s, _ = string.gsub(s, "%-%-(.*)", [[~~—\text{%1}]])
  s, _ = string.gsub(s, [[(CREATE[^{]+){([^}]*)}]], [[\texttt{%1{%2}}]])
  s, _ = string.gsub(s, [[(ALTER[^{]+){([^}]*)}]], [[\texttt{%1{%2}}]])
  s, _ = string.gsub(s, [[DELETE [a-zA-Z0-9]+]], [[\texttt{%0}]])
  s, _ = string.gsub(s, [[WATCH path,]], [[\texttt{WATCH path},]])
  s, _ = string.gsub(s, [[WATCH path \{([^}]+)}]], [[\texttt{WATCH path \{%1}}]])
  s, _ = string.gsub(s, [[READ[^,]+]], [[\texttt{%0}]])
  s, _ = string.gsub(s, "where", [[\text{where}]])
  s, _ = string.gsub(s, "m%(key1,", [[m(\texttt{key1},]])
  s, _ = string.gsub(s, "m%(value1,", [[m(\texttt{value1},]])
  s, _ = string.gsub(s, "m%(path,~ state%)", [[m(\texttt{path},~ state)]])
  s, _ = string.gsub(s, "local%(path,~ n'%+k,~ H%)", [[local(\texttt{path},~ n'+k,~ H)]])
  s, _ = string.gsub(s, "k ≥ n ∧ m%(path,~ H%(k%).state%)", [[k ≥ \texttt{n} ∧ m(\texttt{path}, H(k).state)]])
  s, _ = string.gsub(s, "k ≥ n' ∧ m%(path,~ H%(k%).state%)", [[k ≥ n' ∧ m(\texttt{path}, H(k).state)]])
  s, _ = string.gsub(s, "= watch%(path,~ n,~ m", [[= watch(\texttt{path},~\texttt{n},~\texttt{m}]])
  s, _ = string.gsub(s, "= watch%(path,~ min%(index%(t0%)%),~ max%(index%(t1%)%)", [[= watch(\texttt{path},~ min(index(\texttt{t0})),~ min(index(\texttt{t1}))]])
  s, _ = string.gsub(s, "now ∈ Timestamp", [[\texttt{now} ∈ Timestamp]])
  s, _ = string.gsub(s, "ₙ₊₁", [[_{n+1}]])
  s, _ = string.gsub(s, "₀", [[_{0}]])
  s, _ = string.gsub(s, "₁", [[_{1}]])
  s, _ = string.gsub(s, "₂", [[_{2}]])
  s, _ = string.gsub(s, "₃", [[_{3}]])
  s, _ = string.gsub(s, "₄", [[_{4}]])
  s, _ = string.gsub(s, "ₙ", [[_{n}]])
  return s
end

local function format_display_math(s)
  local res = ""
  local n = 0
  local first = true
  for line in string.gmatch(s, "([^\n]*)") do
    n = string.find(line, "%S")
    if n == nil then
      n = 1
    end
    line = "&" .. string.rep([[\quad ]], math.floor(n / 2)) .. string.sub(line, n)
    line = format_inline_math(line)
    if not first then
      res = res .. [[\\]] .. "\n"
    end
    res = res .. line
    first = false
  end
  res = [[\begin{equation*}\begin{aligned}]] .. "\n" .. res .. "\n" .. [[\end{aligned}\end{equation*}]]
  return res
end

local function process_code_block(block)
  local kind = block.classes[1]
  local res = ""
  if kind == "equation" then
    res = format_display_math(block.text)
  else
    return block
  end
  return pandoc.RawBlock("tex", res)
end

function process_math(el)
  if el.mathtype == "InlineMath" then
    res = format_inline_math(el.text)
    return pandoc.Math(el.mathtype, res)
  else
    return el
  end
end

function process_para(el)
  if #el.content == 1 and el.content[1].t == "Math" and el.content[1].mathtype == "DisplayMath" then
    local math = el.content[1]
    res = format_display_math(math.text)
    return pandoc.RawBlock("tex", res)
  end
end

return {{CodeBlock = process_code_block,
         Math = process_math,
         Para = process_para}}
