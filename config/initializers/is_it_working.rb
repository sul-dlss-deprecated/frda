Rails.configuration.middleware.use(IsItWorking::Handler) do |h|

  h.check :version do |status|
    status.ok(IO.read(Rails.root.join('VERSION')).strip)
  end

  h.check :revision do |status|
    status.ok(IO.read(Rails.root.join('REVISION')).strip)
  end

  # Check the ActiveRecord database connection without spawning a new thread
  h.check :active_record, :async => false

  h.check :seed_data do |status|
    if PoliticalPeriod.count == 10 && CategoryEn.count == 343 && CategoryFr.count == 340 && CollectionHighlight.count == 3 && CollectionHighlightItem.count == 11
      status.ok('data present')
    else
      fail 'seed data missing'
    end
  end

  # Check the home page
  h.check :url, :get => "https://frda.stanford.edu"

  # Check the images en page
  h.check :url, :get => "https://frda.stanford.edu/en/images"

  # Check the ap home page
  h.check :url, :get => "https://frda.stanford.edu/en/ap"

  h.check :search_result do |status|
    url="https://frda.stanford.edu/en/catalog?f%5Bspeaker_ssim%5D%5B%5D=Camus&result_view=default"
    response = Faraday.get(url)
    fail 'has a bad response' unless response.success?
    if response.body.include?("<b>1</b> - <b>10</b> of <b>32</b> volumes")
      status.ok('has correct number results')
    else
      status.ok('is missing results')
    end
  end

  h.check :english_language_view_of_image_details_page_qs394nw0749 do |status|
    url="https://frda.stanford.edu/en/catalog/qs394nw0749"
    response = Faraday.get(url)
    fail 'has a bad response' unless response.success?
    if response.body.include?("<h3>S. Iacobus. Mai : [dessin]</h3>") && response.body.include?("Cite this item")
      status.ok('has correct title and english navigational element')
    else
      status.ok('is missing the correct title and english navigational element')
    end
  end

  h.check :french_language_view_of_image_details_page_qs394nw0749 do |status|
    url="https://frda.stanford.edu/fr/catalog/qs394nw0749"
    response = Faraday.get(url)
    fail 'has a bad response' unless response.success?
    if response.body.include?("<h3>S. Iacobus. Mai : [dessin]</h3>") && response.body.include?("Citer")
      status.ok('has correct title and french navigational element')
    else
      status.ok('is missing the correct title or french navigational element')
    end
  end

  h.check :ap_details_page_fz023dp4399_00_0005 do |status|
    url="https://frda.stanford.edu/en/catalog/fz023dp4399_00_0005"
    response = Faraday.get(url)
    fail 'has a bad response' unless response.success?
    response_body=response.body.force_encoding('UTF-8').scrub
    if response_body.include?("Tome 2 : 1789 – États généraux. Cahiers des sénéchaussées et baillages [Angoumois - Clermont-Ferrand]") && response_body.include?('page 1')
      status.ok('has correct title and page number')
    else
      status.ok('is missing the correct title and page number')
    end
  end

end
