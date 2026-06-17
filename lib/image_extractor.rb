require "nokolexbor"

# Resolves carousel thumbnail images from two sources present in the static HTML:
#   1. Inline <script> blocks that call _setImagesSrc(ii, s) — used for the
#      initially-visible items. Parses id → base64 data URI mappings once on init.
#   2. data-src attributes on <img> tags — used for lazy-loaded items.
class ImageExtractor
  def initialize(doc)
    @id_map = build_id_map(doc)
  end

  def for_img(img_node)
    id = img_node["id"]
    return @id_map[id] if id && @id_map.key?(id)

    img_node["data-src"]
  end

  private

  def build_id_map(doc)
    map = {}
    doc.css("script").each do |script|
      src = script.text
      next unless src.include?("_setImagesSrc") && src.include?("data:image")

      image_uri = extract_image_uri(src)
      ids       = extract_ids(src)

      next unless image_uri && ids.any?

      ids.each { |id| map[id] = image_uri }
    end
    map
  end

  def extract_image_uri(src)
    match = src.match(/(?:var|let|const)\s+s\s*=\s*'(data:image[^']*)'/)
    return nil unless match

    unescape_js(match[1])
  end

  def extract_ids(src)
    match = src.match(/(?:var|let|const)\s+ii\s*=\s*\[([^\]]+)\]/)
    return [] unless match

    match[1].scan(/'([^']+)'/).flatten
  end

  # Google encodes some base64 padding chars as \x3d (=) and slashes as \/
  def unescape_js(str)
    str.gsub(/\\x([0-9a-fA-F]{2})/) { $1.to_i(16).chr }.gsub('\/', "/")
  end
end
