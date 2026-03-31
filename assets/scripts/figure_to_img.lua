-- Pandoc processes paragraphs whose content is a single image as a figure.
-- This script ensures the output is a plain image, not a figure.

if PANDOC_VERSION and PANDOC_VERSION.must_be_at_least then
  PANDOC_VERSION:must_be_at_least("2.11")
else
  error("pandoc version >=2.11 is required")
end

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
