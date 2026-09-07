# frozen_string_literal: true

RSpec.describe CastleDevise::Helpers::CastleHelper, type: :helper do
  describe "#castle_javascript_tag" do
    before do
      CastleDevise.configuration.publishable_key = "pk_test"
    end

    after do
      CastleDevise.configuration.publishable_key = "pk_spec"
    end

    it "loads castle.umd.js from /vendor/castle-js" do
      html = helper.castle_javascript_tag

      expect(html).to include("/vendor/castle-js/castle.umd.js")
      expect(html).to include("window.module")
      expect(html).to include("window.Castle")
      expect(html).to include("@castleio/castle-js")
      expect(html).to include(".configure")
      expect(html).to include("pk_test")
      expect(html).to include("castleDeviseOnFormSubmit")
      expect(html).not_to include("cdn.castle.io")
      expect(html).not_to include("castle.browser.js")
    end

    it "loads a custom UMD src when given" do
      html = helper.castle_javascript_tag(src: "/assets/castle.umd.js")

      expect(html).to include("/assets/castle.umd.js")
      expect(html).not_to include("/vendor/castle-js/castle.umd.js")
      expect(html).to include("window.module")
      expect(html).not_to include("cdn.castle.io")
    end

    it "skips the script tag when src is nil" do
      html = helper.castle_javascript_tag(src: nil)

      expect(html).to include(".configure")
      expect(html).to include("pk_test")
      expect(html).not_to include("castle.umd.js")
      expect(html).not_to include("cdn.castle.io")
    end
  end

  describe "#castle_on_form_submit" do
    it "delegates to the shared submit helper" do
      expect(helper.castle_on_form_submit).to eq("castleDeviseOnFormSubmit(event)")
    end
  end
end
