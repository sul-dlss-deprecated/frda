$(document).ready(function(){

  $('.scrollspy-content').scrollspy({offset: 30});

  $('.overview .nav-pills a:first').tab('show');

	// elements defined with these classes can be hidden by default and then show when the page loads
	//  useful when you have non javascript friendly DOM elements you need to hide for no JS browsers so you can include a <noscript> tag with
	//   non JS versions
  showOnLoad();
  
  toggleSearchOptions();

});

function showImageViewer(imageURL,target) {
	// create a new ZPR instance
	var z = new zpr(target, {
	'imageStacksURL': imageURL,
	'width': 2700,
	'height': 4200
	});
}

function showMessage(message,style) {
	$('.flash_messages').html('<div class="' + style + '">' + message + '<a class="close" data-dismiss="' + style + '" href="#">×</a></div>')
}

function clearMessages() {
	$('.flash_messages').html('')	
}

function showOnLoad() {
	$(".showOnLoad").show();
	$('.showOnLoad').removeClass('hidden');	
}

// Toggle the searchOptions section of the search form.
function toggleSearchOptions(){
	var options_link = $("[data-collapse-search='true']")
	if(options_link.length > 0) {
	  options_link.show();
	  var search_options = $(options_link.attr("data-collapse-element"));
	  search_options.hide();
		options_link.click(function(){
			search_options.slideToggle();
			return false;
		});
		$("input[type='text'], input[type='checkbox']", $("#collapseSearch")).each(function(){
			if($(this).attr("type") == "checkbox" && $(this).is(":checked")){
				search_options.show();
				return false;
			}else if($(this).attr("type") == "text" && $(this).attr("value") != ""){
				search_options.show();
				return false;
			}
		});	
	}
}