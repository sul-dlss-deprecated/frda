require 'spec_helper'

describe("Home Page",:type=>:request,:integration=>true) do
  
    it "should render the home page with some text" do
        visit root_path
        page.should have_content("The online Bassi-Veratti Collection is a multi-year collaboration of the Stanford University Libraries, the Biblioteca Comunale dell'Archiginnasio, Bologna, Italy, and the Istituto per i Beni Artistici, Culturali e Naturali della Regione Emilia-Romagna, to produce a digital version of the archive of the influential woman scientist, Laura Bassi.")
    end
  
end