myFeatherBox = undefined
tagOptions = []
update_original_var = undefined

addTagToSong = (el) ->
  #Allow passing in either a jQuery object or selector
  tagElement = $(el.target)
  tagAddCRUDButton = $("#songtagger")
  oldOffset = tagElement.offset()
  tagElement.insertBefore tagAddCRUDButton
  newOffset = tagElement.offset()
  temp = tagElement.clone().appendTo('body')
  temp.css
    'position': 'absolute'
    'left': oldOffset.left
    'top': oldOffset.top
    'z-index': 1000
  tagElement.hide()
  temp.animate {
    'top': newOffset.top
    'left': newOffset.left
  }, 'slow', ->
    tagElement.show
    tagElement.removeAttr "style"
    temp.remove()
    if tagAddCRUDButton.tooltipster('content').find(".song_tag").length > 0
      tagAddCRUDButton.tooltipster 'content', tagAddCRUDButton.tooltipster('content')
    else
      tagAddCRUDButton.tooltipster 'hide'
    $.ajax
      type: 'POST'
      url: '/song_tags/'
      data: {"tag_id": tagElement.data("tag-id"),"song_id": $(".song_tags").data("song-id")},
      dataType: 'JSON'

removeTagFromSong = (el) ->
  tagElement = $(el.target)
  tagAddCRUDButton = $("#songtagger")
  console.log tagElement
  tagElement.removeAttr "style"
  temp = tagElement.clone().insertAfter tagElement
  tagElement.appendTo(tagAddCRUDButton.tooltipster('content')).removeAttr "style"
  temp.css("max-height", temp.height()).animate {'opacity':0,'width':0}, ->
    tagAddCRUDButton.tooltipster 'content', tagAddCRUDButton.tooltipster('content')
    $(this).remove()
    $.ajax
      type: 'DELETE'
      url: '/song_tags/-1'
      data: {"tag_id": tagElement.data("tag-id"),"song_id": $(".song_tags").data("song-id")},
      dataType: 'JSON'

ceAfterUpdate = (el) ->
  $(el).closest('table').removeClass 'table-hover'
  trueColor = $(el).css 'backgroundColor'
  $(el).closest('table').addClass 'table-hover'
  $(el).animate { backgroundColor: '#cce2ff' },
    duration: 100
    complete: ->
      # reset
      $(el).delay(10).animate { backgroundColor: trueColor },
        duration: 900
        complete: ->
          $(el).removeAttr "style"
      return
  return

ceDoUpdate = ->
  if update_original_var == $(this).html()
    return
  dataToSend =
    key: $(this).attr('name')
    value: $(this).text().trim()
  toupdate = this
  $.ajax
    type: 'PUT'
    url: '/' + $('table.masteredit').attr('id') + '/' + $(this).parent('tr').attr('id')
    data: dataToSend
    dataType: 'JSON'
    success: (data) ->
      if data.result
        ceAfterUpdate $(toupdate)
        $(toupdate).siblings('td').each ->
          if $(this).text() != ""+data.object[$(this).attr('name')] and !!$(this).text() and !!data.object[$(this).attr('name')] and typeof data.object[$(this).attr('name')] != 'undefined'
            $(this).text data.object[$(this).attr('name')]
            ceAfterUpdate $(this)
          return
      else
        $(toupdate).text update_original_var
        console.log 'You should check rails logs because something went wrong with that update'
        trueColor = $(toupdate).css('backgroundColor')
        $(toupdate).animate { backgroundColor: '#ffe2cc' },
          duration: 100
          complete: ->
            # reset
            $(toupdate).delay(10).animate { backgroundColor: trueColor }, duration: 900
            return
      return
  return

ceBeforeUpdate = ->
  update_original_var = $(this).html()
  return

cePaste = (el) ->
  that = this
  setTimeout (->
    $(that).html $(that).text()
    return
  ), 0
  return

optChange = ->
  dataToSend =
    key: "new_role"
    value: $(this).data("user-role")
  doUpdateUser $(this).parents('tr').data('user-id'), dataToSend


chkChange = (event) ->
  dataToSend =
    key: "enabled"
    value: event.type == "ifChecked" ? true : false
  doUpdateUser $(this).parents('tr').data('user-id'), dataToSend

doUpdateUser = (user_id, dataToSend) ->
  $.ajax
    type: 'PUT'
    url: '/users/' + user_id
    data: dataToSend
    dataType: 'JSON'
    success: (response) ->
      if !response.success
        alert "Oh dear, I hoped never to see this message but something has gone wrong with saving user data"

songAnchorClicked = ->
  doSongAnchorClicked $(this).attr('id')

tagitSongAnchorClicked = (id) ->
  doSongAnchorClicked id

doSongAnchorClicked = (song_id) ->
  jqxhr = $.post('/songs/data/' + song_id).done((data) ->
    mc = $('<canvas height=250>')
    ctx = mc.get(0).getContext('2d')
    myLightboxChart = new Chart(ctx).Doughnut data.leader_usage_data#, {
    #   tooltipEvents: [],
    #   tooltipTemplate: "<%if (label){%><%=label%>: <%}%><%= value %>",
    #   onAnimationComplete: ->
    #     this.showTooltip this.segments, true
    # }
    # This stuff ^^ allows persistent tooltips but they overlap so we need some solution to that first
    moc = $('<canvas height=80>')
    ctx2 = moc.get(0).getContext('2d')

    if data.song_frequency_data.datasets.length > 1
      console.error "only handling one dataset when there are " + data.song_frequency_data.datasets.length
      console.console.log "(must fix highestValue)"
    highestValue = Math.max.apply(null, data.song_frequency_data.datasets[0].data)

    myOtherLightboxChart = new Chart(ctx2).Bar(data.song_frequency_data, {
      "showTooltips": false,
      scaleOverride: true,
      scaleSteps: highestValue,
      scaleStepWidth: 1,
      scaleStartValue: 0
    })
    tabledata = ''
    tooltip_content = ''
    for key of data.tag_data.tags
      if data.tag_data.tags[key].value
        tabledata += '<span data-tag-id=\'' + data.tag_data.tags[key].id + '\' class=\'song_tag\'>' +
          data.tag_data.tags[key].name + '</span>'
      else
        tooltip_content += '<span data-tag-id=\'' + data.tag_data.tags[key].id + '\' class=\'song_tag\'>' +
          data.tag_data.tags[key].name + '</span>'
    tabledata = '<tr><td class=\'tdkey\'>Tags</td><td class=\'tddata song_tags\' data-song-id="' + song_id + '">' + tabledata + (if data.tag_data.can_tag then '<a id=\'songtagger\' class=\'glyphicon glyphicon-plus-sign crud_button\'></a>' else "") + '</td></tr>'

    for key of data.song_details
      tabledata += '<tr><td class=\'tdkey\'>' + key + '</td><td class=\'tddata\'>' + data.song_details[key] + '</td></tr>' if data.song_details.hasOwnProperty key

    $.featherlight $('<div><div class=\'breakdown_header\'>' + data.song_name + ' (' + data.tally + ')</div>' + '<div id=\'feathersac\' style=\'text-align:center; margin: 10px\'></div><div id=\'feathersac2\' style=\'text-align:center; margin: 10px\'></div>' + '<div><table class=\'table table-condensed table-striped\'>' + tabledata + '</table></div><div>')
    $("#feathersac").html $(mc)
    $("#feathersac2").html $(moc)
    if data.tag_data.can_tag
      $("#songtagger").tooltipster {
        content: $("<div class='tipster'>" + tooltip_content + "</div>"),
        interactive: true,
        theme: 'tooltipster-light'
      }

  ).fail ->
    console.log 'doSongAnchorClicked Error'
    console.dir this

leaderAnchorClicked = ->
  jqxhr = $.post('/leaders/data/' + $(this).attr("id")).done((data) ->
    arrlabel = []
    arrdata1 = []
    for d of data.chart_data
      if data.chart_data.hasOwnProperty d
        arrlabel.push d
        arrdata1.push data.chart_data[d]
    completedata =
      'labels': arrlabel
      'datasets': [ {
        fillColor: 'rgba(151,187,205,0.5)'
        strokeColor: 'rgba(151,187,205,0.8)'
        highlightFill: 'rgba(151,187,205,0.75)'
        highlightStroke: 'rgba(151,187,205,1)'
        data: arrdata1
      } ]
    mc = $('<canvas width=600 height=300>')
    ctx = mc.get(0).getContext('2d')
    myLightboxChart = new Chart(ctx).Bar(completedata)

    $.featherlight.close()
    $.featherlight $('<div><div class=\'breakdown_header\'>' + data.leader_name + '</div><div id=\'feather\'></div><div id=\'featherlut\'>' + data.usage_table + '</div>')
    $('#feather').html $(mc)

  ).fail ->
    console.log 'leaderAnchorClicked Error'
    console.dir this

songUsageAnchorClicked = (response) ->
  $.featherlight '<div class=\'breakdown_header\'>Usage Summary</div><div id=\'feather\'>' + response.responseText + '</div>'

handleAjaxBusy = (event) ->
  if $(event.target).is("form")
    #form is being submitted make things look pretty in the mean time
    $(".ajaxbusy").show()
  return


handleAjaxComplete = (event, xhr) ->
  if $(event.target).hasClass "crud_create"
    #creation button hit
    $.featherlight xhr.responseText, afterOpen: ->
      $('form#frm_create').validate()
      $('form#frm_create input[type!=hidden]').first().focus()
      $('form#frm_create .ccli_populate').click ccli_loader

  else if $(event.target).hasClass "crud_delete"
    #destroy button hit
    if xhr.responseJSON.success && xhr.responseJSON.what == "destroyed"
      switch xhr.responseJSON.whatDestroyed
        when 'aka'
          $('tr#' + xhr.responseJSON.aka_id).fadeOut 'slow', ->
            $(this).remove()
        when 'user'
          $('tr[data-user-id=' + xhr.responseJSON.user_id + ']').fadeOut 'slow', ->
            $(this).remove()

    else
      alert xhr.responseJSON.message

  else if $(event.target).hasClass "songUsageAnchor"
    songUsageAnchorClicked response

  else if $(event.target).is("form")
    #form submission
    if xhr.responseJSON.success && xhr.responseJSON.what == "created"
      switch xhr.responseJSON.whatCreated
        when 'service'
          $('#songList').tagit "removeAll"
          $('.insertionForm').after xhr.responseJSON.htmlOutput
        when 'leader'
          $('#service_leader_id').append xhr.responseJSON.htmlOutput
        when 'service_type'
          $('#service_service_type_id').append xhr.responseJSON.htmlOutput
        when 'song'
          $('#songList').tagit 'createTag', xhr.responseJSON.tag.id, xhr.responseJSON.tag.label
        when 'aka'
          new_aka_song_id = xhr.responseJSON.song_id
          $.ajax
            'url': '/akas/' + xhr.responseJSON.aka_id
            'success': (newAkaTemplate) ->
              $(newAkaTemplate).insertAfter $('td[data-song-id=' + new_aka_song_id + ']').last().parent('tr')
    $.featherlight.close()
    $(".ajaxbusy").hide()
  return

handlePageLoad = ->
  elem = document.createElement('input')
  elem.setAttribute 'type', 'date'
  if elem.type == 'text'
    $('#service_date').datepicker dateFormat: 'yy-mm-dd'
  $('#songList').tagit
    tagSource: (search, showChoices) ->
      $.ajax
        url: '/songs/list'
        type: 'POST'
        data: search
        success: (choices) ->
          tagOptions = choices
          showChoices choices
          return
        error: (e) ->
          console.log 'tagSource Error'
          console.log e
          return
      return
    allowSpaces: true
    allowNewTags: false
    onlyAvailableTags: true
    removeConfirmation: true
    onTagClicked: (evt, ui) ->
      tagitSongAnchorClicked ui.tagLabel
      return
    showAutocompleteOnFocus: false
    beforeTagAdded: (event, ui) ->
      $.isNumeric ui.tag[0].children[2].defaultValue
    fieldName: 'service[songs][]'

  $("input[type=radio], input[type=checkbox]").iCheck {
    checkboxClass: 'icheckbox_flat-green',
    radioClass: 'iradio_square-blue',
    increaseArea: '20%'
  }
  $("<div>").addClass("ajaxbusy").css("display", "none").appendTo("body").append $("<div>").addClass("glyphicon glyphicon-refresh glyphicon-spin")
  $.featherlight.defaults.root = $(".featherlight-holder")


  # $('usertable input').on('ifChecked', function(event){
  #     alert('xx');
  # });

$(document)
  # Various Anchors
  .on('click', 'a.songAnchor', songAnchorClicked)
  .on('click', 'a.leaderAnchor', leaderAnchorClicked)
  .on('click', '.tipster .song_tag', addTagToSong)
  .on('click', '.song_tags .song_tag', removeTagFromSong)
  .on('ifChecked', '.usertable input[type=radio]', optChange)
  .on('ifChecked ifUnchecked', '.usertable input[type=checkbox]', chkChange)
  # .on('click', '.song_tag_filter .song_tag', filterBySongTag)

  # TD Elements
  .on('focus', 'td[contenteditable=true]', ceBeforeUpdate)
  .on('blur', 'td[contenteditable=true]', ceDoUpdate)
  .on('paste', 'td[contenteditable=true]', cePaste)

  # Ajax and Turbolinks
  .on('ajax:complete', handleAjaxComplete)
  .on('ajax:send', handleAjaxBusy)
  .on('ready page:load', handlePageLoad)

Turbolinks.enableProgressBar()
