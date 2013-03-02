$(document).ready(function(){

  $('.scrollspy-content').scrollspy({offset: 30});

  $('.overview .nav-pills a:first').tab('show');

	// elements defined with these classes can be hidden by default and then show when the page loads
	//  useful when you have non javascript friendly DOM elements you need to hide for no JS browsers so you can include a <noscript> tag with
	//   non JS versions
  showOnLoad();
  
  toggleSearchOptions()
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
// I think we'll need to eventually re-write the whole thing
// to not use the Bootstrap version, but this will do for now.
function toggleSearchOptions(){
	$("input[type='text'], input[type='checkbox']", $("#collapseSearch")).each(function(){
		if($(this).attr("type") == "checkbox" && $(this).is(":checked")){
			$("#collapseSearch").height("auto");
			return false;
		}else if($(this).attr("type") == "text" && $(this).attr("value") != ""){
			$("#collapseSearch").height("auto");
			return false;
		}
	});
}