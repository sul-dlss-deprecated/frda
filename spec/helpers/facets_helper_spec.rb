require "spec_helper"

describe FacetsHelper do
  describe "Blacklight overrides" do
    describe "should_render_facet?" do
      before do
        @config = Blacklight::Configuration.new do |config|
          config.add_facet_field 'basic_field'
          config.add_facet_field 'no_show', :show => false
          config.add_facet_field 'helper_show', :show => :my_custom_check
          config.add_facet_field 'helper_with_an_arg_show', :show => :my_custom_check_with_an_arg
          config.add_facet_field 'lambda_show', :show => lambda { |context, config, field| true }
          config.add_facet_field 'lambda_no_show', :show => lambda { |context, config, field| false }
        end

        allow(helper).to receive_messages(:blacklight_config => @config)
      end

      it "should remove all the appropriate facet field names and replace them with the field including the locale" do
        allow(helper).to receive_messages(on_home_page: false)
        allow(helper).to receive_message_chain([:blacklight_config, :facet_fields]).and_return("en_periods_ssim" => double(show: true), "fr_periods_ssim" => double(show: true))

        expect(helper.should_render_facet?(double(name: "fr_periods_ssim", items: [1,2,3]))).to be_falsey
        expect(helper.should_render_facet?(double(name: "en_periods_ssim", items: [1,2,3]))).to be_truthy

      end
    end
  end
end
