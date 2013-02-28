class ActivitySource
  constructor: ->
    @callbacks = []

  register: (cb) =>
    @callbacks.push(cb)

  fire: (args...) =>
    cb(args...) for cb in @callbacks

class SocketIOSource extends ActivitySource
  constructor: ->
    super()
    socket = io.connect()
    socket.on 'activity', @fire

class FakeSource extends ActivitySource
  constructor: ->
    super()
    setInterval @fireFake, 1500

  fireFake: =>
    fakeLearning =
      object:
        title: 'A title'
        id: 150
        type: 'Learning'
      user_data: [1, 2, 3, 4, 5]
    fakeBoard =
      object:
        title: 'Another title'
        id: 200
        type: 'Board'
      user_data: [6, 7, 8, 9, 10]
    fakeBoard2 =
      object:
        title: 'The cause and effect of long titles in visualizations: a study'
        id: 300
        type: 'Board'
      user_data: [6, 7, 8, 9, 10]
    items = [fakeLearning, fakeBoard, fakeBoard2]
    item = items[Math.floor(Math.random() * items.length)]
    @fire item

class ActivityList
  constructor: (@selector, @visualization) ->
    @data = []

  add: (item) =>
    @data.push(item)
    @data.shift() if @data.length >= 500
    @update()

  update: (item) =>
    vis = @visualization
    items = d3.select(@selector).select('.items').selectAll('.item')
      .data @data, (d) ->
        if d.__key
          d.__key
        else
          d.__key = String(Math.random())
      .text (d) ->
        d.object.title
      .on('click', vis.firePings)
    items.enter()
      .insert('p', ':first-child')
      .on('click', vis.firePings)
      .attr('class', 'item')
      .style('opacity', '0')
      .text (d) ->
        d.object.title
      .transition()
      .duration(500)
      .style('opacity', '1')
    items.exit().remove()

class Visualization
  constructor: ->
    @map = new Map('#map')
    @activityList = new ActivityList('#list', this)
    @source = if window.io then new SocketIOSource() else new FakeSource()
    @source.register @onData

    @colors = [
      d3.rgb(150, 0, 0),
      d3.rgb(150, 150, 0)
    ]

  onData: (data) =>
    colors = ['green', 'red', 'yellow', 'cyan']
    color = colors[Math.floor(Math.random() * colors.length)]
    data.__color = color
    @activityList.add data
    @firePings(data)

  firePings: (data) =>
    for coord in data.coordinates
      @ping(coord.lat, coord.lng, data.__color)

  ping: (lat, lng, color) =>
    zoom = @map.map.zoom()
    endRadius = zoom * 5
    @map.draw(lat, lng, 2000, 'none', 'none', {width: zoom, opacity: 1}, {width: 1, opacity: 0}, 0, endRadius, color, color)

jQuery ->
  window.viz = new Visualization
