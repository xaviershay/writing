$(function() {
  $('div.highlight').each(function () {
    var elem = $(this)
    var link = $('<a href="#">↩</a>')
    link.click(function() {
      elem.toggle()
      return false
    })

    elem.prev('ul').find('li:last-child').append(' ').append(link)
  }).hide();

  var canonical = $('#canonical-link').attr('href')

  $('h2').each(function() {
    var id        = $(this).text().toLowerCase().replace(' ', '-')
    var link      = canonical + '#' + id
    var permalink = $('<a class="permalink"></a>')
                      .attr('href', link)
                      .text($(this).text())

    $(this).html(permalink)
    $(this).attr("id", id)
  })

  var selected = $(location.hash)[0]

  if (selected)
    selected.scrollIntoView()
})
