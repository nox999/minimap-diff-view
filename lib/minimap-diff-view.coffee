{CompositeDisposable} = require 'event-kit'

module.exports =
  active: false
  markerLayers: null
  bindingsById: {}
  subscriptionsById: {}
  subscriptions: {}

  isActive: -> @active

  activate: (state) ->
    @subscriptions = new CompositeDisposable

  consumeDiffView: (diffViewService) ->
    @waitForDiff(diffViewService)

  consumeMinimapServiceV1: (@minimap) ->
    @minimap.registerPlugin 'diff-view', this

  deactivate: ->
    @minimap.unregisterPlugin 'diff-view'
    @minimap = null

  waitForDiff: (diffViewService)->
    diffViewService.getMarkerLayers().then (@markerLayers) =>
      for i of @bindingsById
        @bindingsById[i].handleMarkerLayers(@markerLayers)
      @markerLayers.editor1.lineMarkerLayer.onDidDestroy () =>
        @markerLayers = null
        @waitForDiff(diffViewService)

  activatePlugin: ->
    return if @active

    @active = true

    @subscriptions.add @minimap.observeMinimaps (minimap) =>
      MinimapDiffViewBinding = require './minimap-diff-view-binding'

      binding = new MinimapDiffViewBinding(minimap)
      @bindingsById[minimap.id] = binding

      binding.handleMarkerLayers(@markerLayers)

      @subscriptionsById[minimap.id] = minimap.onDidDestroy =>
        @subscriptionsById[minimap.id]?.dispose()
        @bindingsById[minimap.id]?.destroy()

        delete @bindingsById[minimap.id]
        delete @subscriptionsById[minimap.id]

  deactivatePlugin: ->
    return unless @active

    @active = false
    for i of @bindingsById
      @bindingsById[i].destroy()
    @subscriptions.dispose()
