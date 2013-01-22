$(document).ready(function(){
	if($("[data-collapse='true']").length > 0) {
		$("ul", $("[data-collapse='true']")).each(function(){
			var toggle_text = $(this).children("li[data-behavior='toggle-handler']");
			toggle_text.each(function(){
				var icon = $(this).children("i");
				icon.toggle();
			  var nested_list = $(this).next("li");	
  			nested_list.hide();
				$("a, i", $(this)).click(function(){
					icon.toggleClass("icon-minus-sign");
					nested_list.slideToggle();
					// Refresh the scrollspy since we've changed the DOM
					$('.scrollspy-content').scrollspy("refresh");
				});
			});
		});
		// Refresh the scrollspy since we've changed the DOM
		$('.scrollspy-content').scrollspy("refresh");
	}
	
	// When we have an anchor on the inventory page on page load
  if($(".blacklight-inventory").length > 0 && window.location.hash != '') {
	  var focus = $("[data-reference-id='" + window.location.hash +"']");
	  // Show the next list item and all its hidden list item parents
	  focus.next("li").show();
	  focus.children("i").toggleClass("icon-minus-sign");
	  focus.parents("li:hidden").each(function(){
		  $(this).show();
  		$(this).prev("li").children("i").toggleClass("icon-minus-sign");
	  });
	  // Scroll to the item that we're trying to focus on.
		$(window).scrollTop(focus.offset().top);
		// Refresh the scrollspy since we've changed the DOM
		$('.scrollspy-content').scrollspy("refresh");
  }
});