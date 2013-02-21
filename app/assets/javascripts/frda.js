$(document).ready(function(){

  $('.scrollspy-content').scrollspy({offset: 30});

  $('.overview .nav-pills a:first').tab('show');

	// elements defined with these classes can be hidden by default and then show when the page loads
	//  useful when you have non javascript friendly DOM elements you need to hide for no JS browsers so you can include a <noscript> tag with
	//   non JS versions
  showOnLoad();

});

function getImageDimensions(imageURL) {
	$.getJSON(imageURL + '.json',function(data) {window.alert('got here');})
}

function showImageViewer(imageURL,target) {
	// create a new ZPR instance
	var z = new zpr(target, {
	'imageStacksURL': imageURL,
	'width': 2677,
	'height': 4126
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
