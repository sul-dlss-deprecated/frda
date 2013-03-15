$(document).ready(function(){
	$("div[data-lazy-load]").each(function(){
		load_image_if_visible($(this));
	});
});
$(window).scroll(function(){
	$("div[data-lazy-load]").each(function(){
		load_image_if_visible($(this));
	});
});
function load_image_if_visible(image) {
	if(element_is_visible(image)) {
		var image_html = "<img src='" + image.attr('data-src') + "' alt='" + image.attr('data-alt') + "' title='" + image.attr('data-title') + "' border='0' />";
		image.parent().html(image_html);
	}
}

function element_is_visible(elem) {
    var top = $(window).scrollTop();
    var bottom = top + $(window).height();

    var elem_top = $(elem).offset().top;
    var elem_bottom = elem_top + $(elem).height();

    return ((elem_bottom <= bottom) && (elem_top >= top));
}