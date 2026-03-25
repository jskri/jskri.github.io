function process_figure(el)
  local plain = el.content[1]
  if not plain or plain.t ~= "Plain" then
    return nil
  end

  local img = plain.content[1]
  if not img or img.t ~= "Image" then
    return nil
  end

  return pandoc.Plain({ img })
end

return {{Figure = process_figure}}
