require "nokolexbor"
require_relative "image_extractor"

# Parses a Google Search HTML page and extracts carousel items as an array of
# { name:, extensions:, link:, image: } hashes.
#
# Detection is structure-based rather than CSS-class-based: a carousel item is
# any <a> whose href contains both "/search?" and "&stick=". This signal is
# part of Google's search URL semantics and is stable across class-name rotations
# and different carousel layouts (paintings, movies, albums, etc.).
class CarouselParser
  GOOGLE_BASE = "https://www.google.com"
  YEAR_PATTERN = /\A\d{4}\z/

  def initialize(html)
    @doc       = Nokolexbor::HTML(html)
    @extractor = ImageExtractor.new(@doc)
  end

  def parse
    carousel_anchors.map { |anchor| extract_item(anchor) }
  end

  private

  def carousel_anchors
    @doc.css("a").select do |a|
      href = a["href"].to_s
      href.include?("/search?") && href.include?("stick=") && a.css("img").any?
    end
  end

  def extract_item(anchor)
    labels = leaf_texts(anchor)
    img    = anchor.css("img").first

    {
      "name"       => labels[0],
      "extensions" => year_extensions(labels[1]),
      "link"       => normalize_link(anchor["href"]),
      "image"      => img ? @extractor.for_img(img) : nil
    }.tap { |h| h.delete("extensions") if h["extensions"].nil? }
     .tap { |h| h.delete("image")      if h["image"].nil? }
  end

  # Collects text from leaf nodes (nodes with no element children) under the
  # anchor. This avoids duplicating text that appears in nested containers and
  # reliably separates name from extension without relying on class names.
  def leaf_texts(node)
    texts = []
    node.traverse do |child|
      next unless child.text?
      next if child.parent.element_children.any?

      text = child.text.strip
      texts << text unless text.empty?
    end
    texts
  end

  def year_extensions(text)
    return nil unless text && text.match?(YEAR_PATTERN)

    [text]
  end

  def normalize_link(href)
    decoded = href.gsub("&amp;", "&")
    decoded.start_with?("/") ? "#{GOOGLE_BASE}#{decoded}" : decoded
  end
end
