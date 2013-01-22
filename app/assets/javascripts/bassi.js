$(document).ready(function(){

	// Carousel on show page	
	$("#image_carousel").carousel({
		interval: false
	})
	$("#image_carousel").bind('slid', function(){
	  var carousel = $(this);
	  var index = $('.active', carousel).index('#' + carousel.attr("id") + ' .item');
	  $("#iterator", carousel).text(parseInt(index) + 1);
	});
	
	// load any images on the content inventory page
	itemImages=$('.item-image-link');
	for (var i = 0 ; i < itemImages.length; i++) {
		itemImages[i].innerHTML='<a href="' + itemImages[i].attributes['data-image-link'].value + '"><img alt=\'' + itemImages[i].attributes['data-image-title'].value + '\' title=\'' +  itemImages[i].attributes['data-image-title'].value + '\' src="' + itemImages[i].attributes['data-image-url'].value + '"></a>'
	}
	
	// Modal behavior for collection member show page.
	$("[data-modal-selector]").on('click', function(){
		$($(this).attr("data-modal-selector")).modal('show');
	  return false;
	});

  $('.scrollspy-content').scrollspy({offset: 30});

  $('.overview .nav-pills a:first').tab('show');

});
