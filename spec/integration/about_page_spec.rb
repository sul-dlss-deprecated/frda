require 'spec_helper'

describe("About Pages",:type=>:request,:integration=>true) do

  before(:each) do
    @curator_title=I18n.t("frda.curator_heading")
    @project_team_title=I18n.t("frda.project_team_stanford_heading")
    @acknowledgements_title=I18n.t("frda.acknowledgements_heading")
    @terms_of_use_title=I18n.t("frda.use_and_reproduction_heading")
    @contact=I18n.t("frda.nav.contact")
  end

  it "should show the about project page for various URLs" do
    visit '/about'
    page.should have_content(@curator_title)
    visit '/about/project'
    page.should have_content(@curator_title)
    visit '/about/bogusness'
    page.should have_content(@curator_title)
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

  it "should show a contact section" do
    visit '/about'
    page.should have_content(@contact)
    page.should have_content("Curator, French and Italian Collections")
  end

  it "should show the terms of use section" do
    visit '/about#use_and_reproduction'
    page.should have_content(@terms_of_use_title)
    page.should have_content("This image(s) is a digital reproduction of works from the collections of the")
  end

  it "should show the acknowledgements section" do
    visit '/about#acknowledgements'
    page.should have_content(@acknowledgements_title)
  end

  it "should show the stanford project team section" do
    visit '/about#project_team_stanford'
    page.should have_content(@project_team_title)
  end

end
