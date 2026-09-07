# frozen_string_literal: true

RSpec.describe CastleDevise::Helpers::CastleHelper, type: :helper do
  describe "#castle_javascript_tag" do
    before do
      CastleDevise.configuration.publishable_key = "pk_test"
    end

    after do
      CastleDevise.configuration.publishable_key = "pk_spec"
    end

    it "loads castle-js UMD from /vendor/castle-js and configures it with pk" do
      html = helper.castle_javascript_tag

      expect(html).to include("/vendor/castle-js/castle.umd.js")
      expect(html).to include("window.module")
      expect(html).to include("window.Castle")
      expect(html).to include("@castleio/castle-js")
      expect(html).to include(".configure")
      expect(html).to include("pk")
      expect(html).to include("pk_test")
      expect(html).to include("castleDeviseOnFormSubmit")
      expect(html).not_to include("castle.browser.js")
      expect(html).not_to include("cdn.castle.io")
    end

    it "omits the script tag when the SDK is already bundled" do
      html = helper.castle_javascript_tag(bundled: true)

      expect(html).not_to include("/vendor/castle-js/castle.umd.js")
      expect(html).to include("castleDeviseOnFormSubmit")
    end
  end

  describe "#castle_on_form_submit" do
    it "delegates to the shared submit helper" do
      expect(helper.castle_on_form_submit).to eq("castleDeviseOnFormSubmit(event)")
    end
  end
end
