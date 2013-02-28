# All credit for all intelligent happenings in here goes to https://github.com/pthrasher/twittergeo
class window.Map
  constructor: (selector) ->
    @po = org.polymaps
    @map = @po.map().container(d3.select(selector).append("svg:svg").node()).zoom(3).center({lat:27.57,lon:8}).add(@po.interact())

    @map.add(@po.image().url(@po.url("http://{S}tile.cloudmade.com/c79457282b3a4bcc9c9259ae1766eacd/999/256/{Z}/{X}/{Y}.png").hosts(["a.", "b.", "c.", ""])))

    @map.add(@po.compass().pan("none"))
    @layer = d3.select("#map svg").insert("svg:g").attr('class','points')

  draw: (lat, lng, duration, startFillColor, endFillColor, startStroke, endStroke, startRadius, endRadius, startColor, endColor) ->
    p = @map.locationPoint({lat: lat, lon: lng})
    [x, y] = [p.x, p.y]
    @layer.append("svg:circle")
      .attr("cx", x)
      .attr("cy", y)
      .attr("r", startRadius)
      .attr("class",'')
      .style("fill", startFillColor)
      .style("stroke", startColor)
      .style("stroke-opacity", startStroke.opacity)
      .style("stroke-width", startStroke.width)
      .transition()
      .duration(duration)
      .ease(Math.sqrt)
      .attr("r", endRadius)
      .style("fill", endFillColor)
      .style("stroke", endColor)
      .style("stroke-opacity", endStroke.opacity)
      .style("stroke-width", endStroke.width)
      .remove()
