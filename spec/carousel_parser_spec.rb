require "json"
require_relative "../lib/carousel_parser"

FIXTURES = File.expand_path("../files", __dir__)

RSpec.describe CarouselParser do
  describe "Van Gogh paintings (primary fixture)" do
    let(:html)     { File.read("#{FIXTURES}/van-gogh-paintings.html") }
    let(:expected) { JSON.parse(File.read("#{FIXTURES}/expected-array.json"))["artworks"] }
    let(:results)  { described_class.new(html).parse }

    it "extracts the correct number of artworks" do
      expect(results.length).to eq(expected.length)
    end

    it "matches names in order" do
      expect(results.map { |r| r["name"] }).to eq(expected.map { |e| e["name"] })
    end

    it "matches extensions (years) in order" do
      expect(results.map { |r| r["extensions"] }).to eq(expected.map { |e| e["extensions"] })
    end

    it "matches links in order" do
      expect(results.map { |r| r["link"] }).to eq(expected.map { |e| e["link"] })
    end

    it "matches images in order" do
      expect(results.map { |r| r["image"] }).to eq(expected.map { |e| e["image"] })
    end

    it "produces an exact match against the full expected array" do
      expect(results).to eq(expected)
    end
  end

  describe "item structure" do
    let(:html)    { File.read("#{FIXTURES}/van-gogh-paintings.html") }
    let(:results) { described_class.new(html).parse }

    it "every item has a name string" do
      results.each { |r| expect(r["name"]).to be_a(String) }
    end

    it "every item has a link starting with https://www.google.com" do
      results.each { |r| expect(r["link"]).to start_with("https://www.google.com") }
    end

    it "extensions, when present, contain a four-digit year string" do
      results.each do |r|
        next unless r["extensions"]

        expect(r["extensions"]).to be_an(Array)
        r["extensions"].each { |ext| expect(ext).to match(/\A\d{4}\z/) }
      end
    end

    it "images, when present, are data URIs or URLs" do
      results.each do |r|
        next unless r["image"]

        expect(r["image"]).to match(/\Adata:image\/|https:\/\//)
      end
    end
  end
end
