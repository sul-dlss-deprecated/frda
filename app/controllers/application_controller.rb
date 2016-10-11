class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.

  protect_from_forgery

  rescue_from Exception, :with=>:exception_on_website
  layout "frda"

  helper_method :show_terms_dialog?, :on_home_page, :on_collection_highlights_page,
                :on_collections_pages, :on_about_pages, :on_show_page,
                :on_ap_page, :on_ap_landing_page,
                :on_images_page, :on_images_landing_page,
                :on_search_page, :request_path

  before_filter :set_locale

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options(options={})
    logger.debug "default_url_options is passed options: #{options.inspect}\n"
    { :locale => I18n.locale }
  end

  def seen_terms_dialog?
    cookies[:seen_terms] || false
  end

  def show_terms_dialog?
    %w{staging}.include?(Rails.env) && !seen_terms_dialog?   # we are using the terms dialog to show a warning to users who are viewing the site on staging
  end

  def accept_terms
    cookies[:seen_terms] = { :value => true, :expires => 1.day.from_now } # they've seen it now!
    if params[:return_to].blank?
      render :nothing=>true
    else
      redirect_to params[:return_to]
    end
  end

  def request_path
    Rails.application.routes.recognize_path(request.path)
  end

  def on_home_page
    request_path[:controller] == 'catalog' && request_path[:action] == 'index' && params[:f].blank? && params[:q].blank? && params[:"date-start"].blank? && params[:"date-end"].blank? && !on_collection_highlights_page
  end

  def on_collections_pages
    request_path[:controller] == 'catalog' && !on_home_page && !on_collection_highlights_page
  end

  def on_collection_highlights_page
    request_path[:controller] == 'catalog' && request_path[:action] == 'index' && %w{/collections /en/collections /fr/collections}.include?(request.path)
  end

  def on_images_page
    (@document && @document.images_item?) || (on_search_page && params[:f] && params[:f]['collection_ssi']==[Frda::Application.config.images_id])
  end

  def on_images_landing_page
    request_path[:controller] == 'catalog' && request_path[:action] == 'index' && %w{/en/images /fr/images}.include?(request.path) && !params[:q]
  end

  def on_ap_page
    (@document && @document.ap_item?) || (on_search_page && params[:f] && params[:f]['collection_ssi']==[Frda::Application.config.ap_id])
  end

  def on_ap_landing_page
    request_path[:controller] == 'catalog' && request_path[:action] == 'index' && %w{/en/ap /fr/ap}.include?(request.path) && !params[:q]
  end

  def on_show_page
    request_path[:controller] == 'catalog' && request_path[:action] == 'show'
  end

  def on_search_page
    request_path[:controller] == 'catalog' && request_path[:action] == 'index' && !on_home_page && !on_ap_landing_page
  end

  def on_about_pages
    request_path[:controller] == 'about'
  end

  def exception_on_website(exception)
    @exception=exception
    Honeybadger.notify(exception)

    if Frda::Application.config.exception_error_page
        logger.error(@exception.message)
        logger.error(@exception.backtrace.join("\n"))
        render "500", :status => 500
      else
        raise(@exception)
     end
  end

end
