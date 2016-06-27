# encoding: utf-8

Frda::Application.routes.draw do

  scope "(:locale)", :locale => /en|fr/ do

    Blacklight.add_routes(self)

    get '/', :to => "catalog#index", :as=> 'root'
    get 'login',   :to => 'catalog#index', :as => 'new_user_session'
    get 'logout',  :to => 'catalog#index', :as => 'destroy_user_session'
    get 'account', :to => 'catalog#index', :as => 'edit_user_registration'

    get 'search', :to=> 'catalog#index', :as=>'search'

    get 'version', :to=>'about#show', :defaults => {:id=>'version'}, :as => 'version'

    get 'collections', :to => 'catalog#index', :as => 'collection_highlights'

    match 'show_page', :to=>'catalog#show_page', :as =>'show_page', :via => [:get,:post]
    get 'speaker_suggest', :to=>'catalog#speaker_suggest', :as => 'speaker_suggest'

    get 'catalog/:id/mods', :to => "catalog#mods", :as => "mods_view"

    get 'ap', :to => 'catalog#index', :as =>'ap_collection', :defaults=>{:f=>{:collection_ssi=>[Frda::Application.config.ap_id]}}
    get 'images', :to => 'catalog#index', :as =>'images_collection', :defaults=>{:f=>{:collection_ssi=>[Frda::Application.config.images_id]}}

    # Handles all About pages.
    get 'about', :to => 'about#show', :as => 'about_project', :defaults => {:id=>'project'} # no page specified, go to project page
    match 'contact', :to=> 'about#contact', :as=>'contact_us', :via => [:get,:post]
    match 'about/contact', :to=> 'about#contact', :via => [:get,:post] # specific contact us about page
    get 'about/:id', :to => 'about#show' # catch anything else and direct to show page with ID parameter of partial to show


    # helper routes to we can have a friendly URL for items and collections
    get 'item/:id', :to=> 'catalog#show', :as =>'item'
    get 'collection/:id', :to=> 'catalog#show', :as =>'collection'

    get 'accept_terms', :to=> 'application#accept_terms', :as=> 'accept_terms', :via=>:post

    # The priority is based upon order of creation:
    # first created -> highest priority.

    # Sample of regular route:
    #   match 'products/:id' => 'catalog#view'
    # Keep in mind you can assign values other than :controller and :action

    # Sample of named route:
    #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
    # This route can be invoked with purchase_url(:id => product.id)

    # Sample resource route (maps HTTP verbs to controller actions automatically):
    #   resources :products

    # Sample resource route with options:
    #   resources :products do
    #     member do
    #       get 'short'
    #       post 'toggle'
    #     end
    #
    #     collection do
    #       get 'sold'
    #     end
    #   end

    # Sample resource route with sub-resources:
    #   resources :products do
    #     resources :comments, :sales
    #     resource :seller
    #   end

    # Sample resource route with more complex sub-resources
    #   resources :products do
    #     resources :comments
    #     resources :sales do
    #       get 'recent', :on => :collection
    #     end
    #   end

    # Sample resource route within a namespace:
    #   namespace :admin do
    #     # Directs /admin/products/* to Admin::ProductsController
    #     # (app/controllers/admin/products_controller.rb)
    #     resources :products
    #   end

    # You can have the root of your site routed with "root"
    # just remember to delete public/index.html.
    # root :to => 'welcome#index'

    # See how all your routes lay out with "rake routes"

    # This is a legacy wild controller route that's not recommended for RESTful applications.
    # Note: This route will make all actions in every controller accessible via GET requests.
    # match ':controller(/:action(/:id))(.:format)'
  end

end
