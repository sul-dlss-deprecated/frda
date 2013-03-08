$(document).ready(function(){

  $('.scrollspy-content').scrollspy({offset: 30});

  $('.overview .nav-pills a:first').tab('show');

	// elements defined with these classes can be hidden by default and then show when the page loads
	//  useful when you have non javascript friendly DOM elements you need to hide for no JS browsers so you can include a <noscript> tag with
	//   non JS versions
  showOnLoad();
  
	changeFormFocus();

  toggleSearchOptions();

  handleSearchFormSubmit();

  searchOptionsDatePicker();
	searchOptionsToggles();
	
	setupSpeakerAutoComplete();

});

function setupSpeakerAutoComplete() {
	 $( "#by-speaker" ).autocomplete({
	source: "/speaker_suggest.json",
	minLength: 3	});	
}
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
	$('.showOnLoad').removeClass('hidden');	
	$('.showOnLoad').show();
}

function changeFormFocus(){
	if($("[data-post-check-focus]").length > 0) {
	  $("[data-post-check-focus]").each(function(){
		  $(this).change(function(){
			  if($(this).is(":checked")){
				  $($(this).attr("data-post-check-focus")).click();
  				$($(this).attr("data-post-check-focus")).focus();
			  }
		  });
		});	
	}
}

// Allow form to be submitted with enter/return key.
function handleSearchFormSubmit(){
	$("form.search_form").bind("keypress", function(e){
		if(e.keyCode === 13){
			$(this).submit();
		}
	});
	$("[data-hide-submit='true']").each(function(){
		$(this).toggleClass("hide");
	});
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

// enable/disable certain advanced search options that are incompatible with each other
function searchOptionsToggles(){
	$('#prox').click(function(){ 
		if ($('#prox').attr('checked'))
			{ // proximity search checked, uncheck "in speeches" fields and clear values
				$('#speeches').attr('checked',false);	
				$('#by-speaker').attr('value','');	
			}
	}
 )

	$('#speeches').click(function(){ 
		if ($('#speeches').attr('checked'))
			{ // in speeches by field checked, uncheck "separated by" fields
				$('#prox').attr('checked',false);	
			}
	}
 )

	$('#by-speaker').click(function(){ 
		$('#speeches').attr('checked',true);
		$('#prox').attr('checked',false);	
	}
 )
}

function searchOptionsDatePicker(){
	if($("[data-date-picker='true']").length > 0) {
		$("[data-date-picker='true']").each(function(){
			$(this).datepicker({
				format: "yyyy-mm-dd"
			});
			$(this).click(function(){
				if($(this).attr("value") == "") {
					$(this).attr("value", $(this).attr("placeholder"));
					$(this).datepicker("update");
				}
			});
			$(this).bind('blur', function(){
				if($(this).attr("value") == $(this).attr("placeholder")) {
					$(this).attr("value", "");
				}
			});
		});
	}
}