startNewTracker = (link) ->
  $(link).addClass('js-skip-dialog').first().click()

timeTrackerAjax = (args) ->
  $.ajax
    url: args.url
    type: args.type || 'post'
    data: $.extend {_method: args.method}, args.data or {}
    success: args.success
    error: ({responseJSON}) ->
      hourglass.Utils.showErrorMessage responseJSON.message

stopDialogApplyHandler = (link) ->
  $stopDialog = $(@)
  $activityField = $stopDialog.find('[name*=activity_id]')
  return unless hourglass.FormValidator.isFieldValid $activityField
  $stopDialog.dialog 'close'
  timeTrackerAjax
    url: $(link).attr('href')
    type: 'delete'
    data:
      time_tracker:
        activity_id: $activityField.val()
    success: -> location.reload()

startDialogApplyHandler = (link) ->
  $startDialog = $(@)
  switch $startDialog.find('input[type=radio]:checked').val()
    when 'log'
      $activityField = $startDialog.find('[name*=activity_id]')
      if $activityField.length
        return unless hourglass.FormValidator.isFieldValid $activityField
        $startDialog.dialog 'close'
        timeTrackerAjax
          url: hourglassRoutes.start_hourglass_time_trackers()
          method: 'post'
          data:
            $.extend Object.fromEntries(new URLSearchParams($(link).data('params'))),
              id: 'current'
              current_action: 'stop'
              current_update:
                activity_id: $activityField.val()
          success: -> location.reload()
      else
        $startDialog.dialog 'close'
        timeTrackerAjax
          url: hourglassRoutes.start_hourglass_time_trackers()
          method: 'post'
          data:
            $.extend Object.fromEntries(new URLSearchParams($(link).data('params'))),
              id: 'current'
              current_action: 'stop'
          success: -> location.reload()
    when 'discard'
      $startDialog.dialog 'close'
      timeTrackerAjax
        url: hourglassRoutes.start_hourglass_time_trackers()
        method: 'post'
        data:
          $.extend Object.fromEntries(new URLSearchParams($(link).data('params'))),
            id: 'current'
            current_action: 'destroy'
        success: -> location.reload()
    when 'takeover'
      $startDialog.dialog 'close'
      timeTrackerAjax
        url: hourglassRoutes.hourglass_time_tracker 'current'
        type: 'put'
        data: Object.fromEntries(new URLSearchParams($(link).data('params')))
        success: ->
          location.reload()

showStartDialog = (e) ->
  return true if $(@).hasClass('js-skip-dialog')
  $startDialog = $('.js-start-dialog')
  if $startDialog.length is 0
    $startDialogContent = $('.js-start-dialog-content')
    if $startDialogContent.length isnt 0
      e.preventDefault()
      e.stopPropagation()
      hourglass.Utils.showDialog $startDialogContent.data('content'), [
        {
          text: $startDialogContent.data('button-ok-text')
          click: -> startDialogApplyHandler.call(@, e.target)
        }
        {
          text: $startDialogContent.data('button-cancel-text')
          click: -> $(@).dialog 'close'
        }
      ]
  else
    e.preventDefault()
    e.stopPropagation()
    $startDialog.dialog 'open'

showStopDialog = (e) ->
  return true if $(@).hasClass('js-skip-dialog')
  $stopDialog = $('.js-stop-dialog')
  if $stopDialog.length is 0
    $stopDialogContent = $('.js-stop-dialog-content')
    if $stopDialogContent.length isnt 0
      e.preventDefault()
      e.stopPropagation()
      hourglass.Utils.showDialog $stopDialogContent.data('content'), [
        {
          text: $stopDialogContent.data('button-ok-text')
          click: -> stopDialogApplyHandler.call(@, e.target)
        }
        {
          text: $stopDialogContent.data('button-cancel-text')
          click: -> $(@).dialog 'close'
        }
      ]
      $stopDialogContent.on 'change', '[name*=activity_id]', ->
        hourglass.FormValidator.validateField $(@)
  else
    e.preventDefault()
    e.stopPropagation()
    $stopDialog.dialog 'open'

window.oldToggleOperator = window.toggleOperator
window.toggleOperator = (field) ->
  operator = $("#operators_" + field.replace('.', '_')).val()
  return enableValues(field, []) if operator is 'q' or operator is 'lq'
  window.oldToggleOperator field

$ ->
  $('#content > .contextual >:nth-child(2)').after $('.js-issue-action').removeClass('hidden')

  $('.hourglass-quick').replaceWith $('.js-account-menu-link').removeClass('hidden')

  $('#content, #top-menu')
    .on 'click', '.js-start-tracker', showStartDialog
    .on 'click', '.js-stop-tracker', showStopDialog

  $contextMenuTarget = null
  $(document).on 'contextmenu', '.hourglass-list', (e) ->
    $contextMenuTarget = $(@)

  $.ajaxPrefilter (options) ->
    return unless options.url.endsWith 'hourglass/ui/context_menu'
    options.data = $.param list_type: $contextMenuTarget.data('list-type')
    $contextMenuTarget.find('.context-menu-selection').each ->
      options.data += "&ids[]=#{@id}"

