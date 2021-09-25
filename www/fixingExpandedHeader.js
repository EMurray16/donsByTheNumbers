$(document).ready(function() {
  var myInterval = setInterval(function() {
    // clear interval after the table's DOM is available
    if ($('thead').length) {
      clearInterval(myInterval);
    }

    // setting css
    $('thead tr th').css('position', 'sticky').css('background', 'white');

    var height = 0;

    for (var i = 0, length = $('thead tr').length; i < length; i++) {
      var header = $('thead tr:nth-child(' + i + ')');
      height += header.length ? header.height() : 0;
      $('thead tr:nth-child(' + (i + 1) + ') th').css('top', height);
    }

  }, 500);
});