$('div.highlight').each(function () {
  var elem = $(this);
  var link = $('<a href="#">↩</a>')
  link.click(function() {
    elem.toggle()
    return false
  })
  
  elem.prev('ul').find('li:last-child').append(' ').append(link)
}).hide();
