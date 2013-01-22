require 'spec_helper'

describe("About Pages",:type=>:request,:integration=>true) do
  
  before(:each) do
    @about_page_title=I18n.t("frda.about.project_title")
    @project_team_title=I18n.t("frda.about.stanford_team_title")
    @acknowledgements_title=I18n.t("frda.about.acknowledgements_title")
    @contact_us_title=I18n.t("frda.about.contact_title")
    @terms_of_use_title=I18n.t("frda.about.terms_of_use_title")
  end
  
  it "should show the about project page for various URLs" do
    visit '/about'
    page.should have_content(@about_page_title)
    visit '/about/project'
    page.should have_content(@about_page_title)    
    visit '/about/bogusness'
    page.should have_content(@about_page_title)    
  end

  it "should show the contact us page" do
    visit '/about/contact'
    page.should have_content(@contact_us_title)
    fill_in 'name', :with=>'Spongebob Squarepants'
    click_button 'Send'
    find('div.alert').should have_content(I18n.t("frda.about.contact_error"))
    fill_in 'message', :with=>'I live in a pineapple under the sea.'
    FrdaMailer.stub_chain(:contact_message,:deliver).and_return('a mailer')
    FrdaMailer.should_receive(:contact_message)
    click_button 'Send'
    find('div.alert').should have_content(I18n.t("frda.about.contact_message_sent"))
  end

  it "should show the terms of use page" do
    visit '/about/terms_of_use'
    page.should have_content(@terms_of_use_title)
  end

  it "should show the acknowledgements page" do
    visit '/about/acknowledgements'
    page.should have_content(@acknowledgements_title)
  end

  it "should show the project team page" do
    visit '/about/stanford_team'
    page.should have_content(@project_team_title)
  end
    
end
