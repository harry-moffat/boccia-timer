
// Global

var beep = new Audio('1minute.wav');
var alarm = new Audio('timeup.wav');
//beep.play();
//alarm.play();



// Red

var redcountdownTimer, redcountdownCurrent = 36000;
$(document).ready(function() {
	redcountdownTimer = $.timer(function() {
		var min = parseInt(redcountdownCurrent/6000);
		var sec = parseInt(redcountdownCurrent/100)-(min*60);
		var output = "00"; if(min > 0) {output = pad(min,2);}
		$('.redcountdowntime').html(output+":"+pad(sec,2));
		if(redcountdownCurrent == 0) {
			redcountdownTimer.stop();
			alarm.play();				
			alert('RED time has elapsed.');
			redcountdownReset();
		} else {
			redcountdownCurrent-=7;
			if(redcountdownCurrent < 0) {redcountdownCurrent=0;}
			if(min == 1 && sec == 0) {beep.play();}
	                if(min == 0 && sec == 30) {beep.play();}
		}
	}, 70, true);
	$('#gametime').bind('keyup', function(e) {if(e.keyCode == 13) {redcountdownReset();}});
});
function redcountdownReset() {
	var newCount = $('input[name=startTime]').val()*6000;
	if(newCount > 0) {redcountdownCurrent = newCount;bluecountdownCurrent = newCount;}
	redcountdownTimer.stop().once();
}



// Blue

var bluecountdownTimer, bluecountdownCurrent = 36000;
$(document).ready(function() {
	bluecountdownTimer = $.timer(function() {
		var min = parseInt(bluecountdownCurrent/6000);
		var sec = parseInt(bluecountdownCurrent/100)-(min*60);
		var output = "00"; if(min > 0) {output = pad(min,2);}
		$('.bluecountdowntime').html(output+":"+pad(sec,2));
		if(bluecountdownCurrent == 0) {
			bluecountdownTimer.stop();
			alarm.play();				
			alert('BLUE time has elapsed.');
			bluecountdownReset();
		} else {
			bluecountdownCurrent-=7;
			if(bluecountdownCurrent < 0) {bluecountdownCurrent=0;}
			if(min == 1 && sec == 0) {beep.play();}
	                if(min == 0 && sec == 30) {beep.play();}
			
		}
	}, 70, true);
	$('#gametime').bind('keyup', function(e) {if(e.keyCode == 13) {bluecountdownReset();}});
});
function bluecountdownReset() {
	var newCount = $('input[name=startTime]').val()*6000;
	if(newCount > 0) {redcountdownCurrent = newCount;bluecountdownCurrent = newCount;}
	bluecountdownTimer.stop().once();
}





// Padding function
function pad(number, length) {
	var str = '' + number;
	while (str.length < length) {str = '0' + str;}
	return str;
}
