$(document).ready(function() {
	$('.header .menu .sel').hide();
});
function menuSel(top) {
	$('.header .menu .sel').show().stop(true, false).animate({'top':top}, 300);
}