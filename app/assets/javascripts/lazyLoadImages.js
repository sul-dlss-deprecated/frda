/*
 * jQuery Lazy Load Images plugin.
 *
 * https://github.com/jkeck/lazyLoadImages
 *
 * VERSION 0.0.1
 *
**/
(function( $ ){
	$.fn.lazyLoadImages = function() {
		var $this = this;
		loadImages($this);
		$(window).bind("scroll", function(){
			loadImages($this);
		});
		function loadImages(el){
			el.each(function(){
				if(element_is_visible($(this))) {
					var image_html = "<img src='" + $(this).attr('data-src') + "' alt='" + $(this).attr('data-alt') + "' title='" + $(this).attr('data-title') + "' border='0' />";
					$(this).parent().html(image_html);
				}
			});
		}
		function element_is_visible(elem) {
		    var top = $(window).scrollTop();
		    var bottom = top + $(window).height();

		    var elem_top = $(elem).offset().top;
		    var elem_bottom = elem_top + $(elem).height();

		    return ((elem_bottom <= bottom) && (elem_top >= top));
		}
	};
})( jQuery );